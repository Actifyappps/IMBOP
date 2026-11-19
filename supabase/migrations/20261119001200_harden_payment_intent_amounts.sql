-- Harden customer payment intents: bind the amount to the selected invoice balance before any provider prompt.
create or replace function public.create_my_billing_payment_intent(
  p_institution_id uuid,
  p_amount_kes numeric,
  p_payment_method text,
  p_invoice_id uuid default null,
  p_provider text default null,
  p_expires_at timestamptz default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security invoker
set search_path to ''
as $function$
declare
  v_id uuid;
  v_user uuid := auth.uid();
  v_method text := upper(p_payment_method);
  v_outstanding numeric(14,2);
begin
  if not private.has_institution_permission(p_institution_id,'institution_admin') then
    raise exception 'INSTITUTION_PERMISSION_REQUIRED';
  end if;
  if p_amount_kes <= 0 then raise exception 'INVALID_PAYMENT_AMOUNT'; end if;
  if v_method not in ('MPESA','AIRTEL_MONEY','BANK_TRANSFER','CARD','OTHER') then
    raise exception 'INVALID_PAYMENT_METHOD';
  end if;
  if p_invoice_id is null then
    raise exception 'INVOICE_REQUIRED';
  end if;

  select greatest(0,i.total_kes-coalesce((
    select sum(a.amount_kes)
      from public.billing_payment_allocations a
      join public.billing_payments p on p.id=a.payment_id
     where a.invoice_id=i.id and p.status='CONFIRMED'
  ),0))
    into v_outstanding
    from public.billing_invoices i
   where i.id=p_invoice_id
     and i.institution_id=p_institution_id
     and i.status in ('ISSUED','PARTIALLY_PAID','OVERDUE');

  if v_outstanding is null then
    raise exception 'INVOICE_NOT_PAYABLE';
  end if;
  if p_amount_kes > v_outstanding then
    raise exception 'PAYMENT_EXCEEDS_OUTSTANDING_BALANCE';
  end if;

  insert into public.billing_payment_intents(
    institution_id,invoice_id,payment_method,provider,amount_kes,status,
    requested_by_user_id,expires_at,metadata
  ) values (
    p_institution_id,p_invoice_id,v_method,p_provider,p_amount_kes,'CREATED',
    v_user,coalesce(p_expires_at,now()+interval '30 minutes'),
    coalesce(p_metadata,'{}'::jsonb)||jsonb_build_object('outstanding_at_creation_kes',v_outstanding)
  )
  returning id into v_id;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,actor_user_id,metadata
  ) values (
    p_institution_id,p_invoice_id,'PAYMENT_INTENT_CREATED',v_user,
    jsonb_build_object(
      'payment_intent_id',v_id,
      'amount_kes',p_amount_kes,
      'payment_method',v_method,
      'provider',p_provider,
      'outstanding_at_creation_kes',v_outstanding
    )
  );

  return v_id;
end;
$function$;

revoke execute on function public.create_my_billing_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) from public,anon;
grant execute on function public.create_my_billing_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) to authenticated;
