-- IMBOP Billing & Payments — provider rails, callbacks and reconciliation foundation
-- Branch: feature/billing-system
-- Purpose: make payment intents provider-aware without exposing provider secrets or trusting client amounts.

create index if not exists billing_payment_intents_provider_reference_idx
  on public.billing_payment_intents(provider, external_reference);

create index if not exists billing_payment_intents_checkout_reference_idx
  on public.billing_payment_intents(checkout_reference);

create or replace function public.platform_set_payment_intent_provider_state(
  p_payment_intent_id uuid,
  p_status text,
  p_external_reference text default null,
  p_checkout_reference text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_intent public.billing_payment_intents%rowtype;
  v_user uuid := auth.uid();
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select * into v_intent
    from public.billing_payment_intents
   where id=p_payment_intent_id
   for update;

  if not found then raise exception 'PAYMENT_INTENT_NOT_FOUND'; end if;

  update public.billing_payment_intents
     set status=p_status,
         external_reference=coalesce(p_external_reference,external_reference),
         checkout_reference=coalesce(p_checkout_reference,checkout_reference),
         metadata=coalesce(metadata,'{}'::jsonb) || coalesce(p_metadata,'{}'::jsonb),
         updated_at=now()
   where id=p_payment_intent_id;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,metadata,idempotency_key
  ) values(
    v_intent.institution_id,v_intent.invoice_id,'PAYMENT_INTENT_PROVIDER_STATE',
    jsonb_build_object(
      'payment_intent_id',p_payment_intent_id,
      'status',p_status,
      'external_reference',p_external_reference,
      'checkout_reference',p_checkout_reference
    ) || coalesce(p_metadata,'{}'::jsonb),
    'intent-provider-state:'||p_payment_intent_id::text||':'||p_status
  ) on conflict (idempotency_key) do nothing;

  return true;
end;
$function$;

revoke execute on function public.platform_set_payment_intent_provider_state(uuid,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.platform_set_payment_intent_provider_state(uuid,text,text,text,jsonb) to service_role;

create or replace function public.platform_finalize_payment_intent_from_provider(
  p_payment_intent_id uuid,
  p_provider text,
  p_provider_reference text,
  p_amount_kes numeric,
  p_received_at timestamptz default now(),
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_intent public.billing_payment_intents%rowtype;
  v_payment_id uuid;
  v_remaining numeric(14,2);
  r record;
  v_alloc numeric(14,2);
  v_idempotency text;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  if p_amount_kes <= 0 then raise exception 'INVALID_PAYMENT_AMOUNT'; end if;

  select * into v_intent
    from public.billing_payment_intents
   where id=p_payment_intent_id
   for update;

  if not found then raise exception 'PAYMENT_INTENT_NOT_FOUND'; end if;

  if v_intent.status='SUCCEEDED' then
    select p.id into v_payment_id
      from public.billing_payments p
     where p.idempotency_key='provider-intent:'||p_payment_intent_id::text;
    if v_payment_id is null then raise exception 'PAYMENT_FINALIZED_WITHOUT_PAYMENT'; end if;
    return v_payment_id;
  end if;

  if v_intent.status not in ('CREATED','PENDING') then
    raise exception 'PAYMENT_INTENT_NOT_FINALIZABLE';
  end if;

  if abs(p_amount_kes-v_intent.amount_kes) > 0.01 then
    raise exception 'PAYMENT_AMOUNT_MISMATCH';
  end if;

  if v_intent.expires_at is not null and v_intent.expires_at < now() then
    update public.billing_payment_intents set status='EXPIRED',updated_at=now()
     where id=v_intent.id;
    raise exception 'PAYMENT_INTENT_EXPIRED';
  end if;

  if v_intent.invoice_id is not null then
    if not exists(
      select 1 from public.billing_invoices i
       where i.id=v_intent.invoice_id
         and i.institution_id=v_intent.institution_id
         and i.status in ('ISSUED','PARTIALLY_PAID','OVERDUE')
    ) then raise exception 'INVOICE_NOT_PAYABLE'; end if;

    if p_amount_kes > (
      select greatest(0,i.total_kes-coalesce((
        select sum(a.amount_kes)
          from public.billing_payment_allocations a
          join public.billing_payments p on p.id=a.payment_id
         where a.invoice_id=i.id and p.status='CONFIRMED'
      ),0))
        from public.billing_invoices i where i.id=v_intent.invoice_id
    ) then
      raise exception 'PAYMENT_EXCEEDS_OUTSTANDING_BALANCE';
    end if;
  end if;

  v_idempotency := 'provider-intent:'||p_payment_intent_id::text;

  insert into public.billing_payments(
    institution_id,provider,provider_reference,payment_method,amount_kes,status,
    received_at,idempotency_key,notes,metadata
  ) values(
    v_intent.institution_id,p_provider,p_provider_reference,v_intent.payment_method,
    p_amount_kes,'CONFIRMED',p_received_at,v_idempotency,
    'Provider-confirmed payment for IMBOP payment intent',
    coalesce(p_metadata,'{}'::jsonb)||jsonb_build_object('payment_intent_id',p_payment_intent_id)
  )
  on conflict (idempotency_key) do update set updated_at=now()
  returning id into v_payment_id;

  if v_payment_id is null then
    select id into v_payment_id from public.billing_payments where idempotency_key=v_idempotency;
  end if;

  v_remaining := p_amount_kes;

  for r in
    select i.id,
      greatest(0,i.total_kes-coalesce((
        select sum(a.amount_kes)
          from public.billing_payment_allocations a
          join public.billing_payments p on p.id=a.payment_id
         where a.invoice_id=i.id and p.status='CONFIRMED'
      ),0)) outstanding
    from public.billing_invoices i
    where i.institution_id=v_intent.institution_id
      and i.status in ('ISSUED','OVERDUE','PARTIALLY_PAID')
      and (v_intent.invoice_id is null or i.id=v_intent.invoice_id)
    order by i.due_date,i.issued_at
  loop
    exit when v_remaining <= 0;
    v_alloc := least(v_remaining,r.outstanding);
    if v_alloc > 0 then
      insert into public.billing_payment_allocations(payment_id,invoice_id,amount_kes)
      values(v_payment_id,r.id,v_alloc)
      on conflict (payment_id,invoice_id) do update set amount_kes=excluded.amount_kes;
      v_remaining := v_remaining-v_alloc;
    end if;
  end loop;

  update public.billing_payment_intents
     set status='SUCCEEDED',
         external_reference=coalesce(p_provider_reference,external_reference),
         updated_at=now()
   where id=v_intent.id;

  insert into public.billing_events(
    institution_id,invoice_id,payment_id,event_type,metadata,idempotency_key
  ) values(
    v_intent.institution_id,v_intent.invoice_id,v_payment_id,'PAYMENT_CONFIRMED',
    jsonb_build_object(
      'payment_intent_id',p_payment_intent_id,
      'provider',p_provider,
      'provider_reference',p_provider_reference,
      'amount_kes',p_amount_kes
    )||coalesce(p_metadata,'{}'::jsonb),
    'provider-payment-confirmed:'||p_payment_intent_id::text
  ) on conflict (idempotency_key) do nothing;

  update public.billing_invoices i
     set status=case
       when greatest(0,i.total_kes-coalesce((
         select sum(a.amount_kes)
           from public.billing_payment_allocations a
           join public.billing_payments p on p.id=a.payment_id
          where a.invoice_id=i.id and p.status='CONFIRMED'
       ),0)) <= 0 then 'PAID'
       when coalesce((
         select sum(a.amount_kes)
           from public.billing_payment_allocations a
           join public.billing_payments p on p.id=a.payment_id
          where a.invoice_id=i.id and p.status='CONFIRMED'
       ),0) > 0 then 'PARTIALLY_PAID'
       else i.status
     end,
     updated_at=now()
   where i.id=v_intent.invoice_id;

  return v_payment_id;
end;
$function$;

revoke execute on function public.platform_finalize_payment_intent_from_provider(uuid,text,text,numeric,timestamptz,jsonb) from public,anon,authenticated;
grant execute on function public.platform_finalize_payment_intent_from_provider(uuid,text,text,numeric,timestamptz,jsonb) to service_role;

create or replace function public.platform_fail_payment_intent(
  p_payment_intent_id uuid,
  p_status text,
  p_metadata jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_intent public.billing_payment_intents%rowtype;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if p_status not in ('FAILED','CANCELLED','EXPIRED') then raise exception 'INVALID_INTENT_STATUS'; end if;

  select * into v_intent from public.billing_payment_intents where id=p_payment_intent_id for update;
  if not found then raise exception 'PAYMENT_INTENT_NOT_FOUND'; end if;
  if v_intent.status='SUCCEEDED' then return true; end if;

  update public.billing_payment_intents
     set status=p_status,updated_at=now(),
         metadata=coalesce(metadata,'{}'::jsonb)||coalesce(p_metadata,'{}'::jsonb)
   where id=p_payment_intent_id;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,metadata,idempotency_key
  ) values(
    v_intent.institution_id,v_intent.invoice_id,'PAYMENT_INTENT_TERMINAL',
    jsonb_build_object('payment_intent_id',p_payment_intent_id,'status',p_status)||
      coalesce(p_metadata,'{}'::jsonb),
    'intent-terminal:'||p_payment_intent_id::text||':'||p_status
  ) on conflict (idempotency_key) do nothing;

  return true;
end;
$function$;

revoke execute on function public.platform_fail_payment_intent(uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.platform_fail_payment_intent(uuid,text,jsonb) to service_role;
