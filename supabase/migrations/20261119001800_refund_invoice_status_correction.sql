-- IMBOP Refund Ledger Correction
-- Recalculate invoice status after a confirmed refund so a refunded settlement cannot leave an invoice falsely marked PAID.

create or replace function public.platform_recalculate_invoice_status(p_invoice_id uuid)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_invoice public.billing_invoices%rowtype;
  v_paid numeric(14,2);
  v_refunded numeric(14,2);
  v_net numeric(14,2);
  v_status text;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select * into v_invoice
  from public.billing_invoices
  where id=p_invoice_id
  for update;

  if not found then raise exception 'INVOICE_NOT_FOUND'; end if;

  select coalesce(sum(a.amount_kes),0)
    into v_paid
  from public.billing_payment_allocations a
  join public.billing_payments p on p.id=a.payment_id
  where a.invoice_id=p_invoice_id
    and p.status in ('CONFIRMED','REFUNDED');

  select coalesce(sum(r.amount_kes),0)
    into v_refunded
  from public.billing_payment_refunds r
  join public.billing_payments p on p.id=r.payment_id
  where r.status='CONFIRMED'
    and p.status in ('CONFIRMED','REFUNDED')
    and exists (
      select 1 from public.billing_payment_allocations a
      where a.payment_id=p.id and a.invoice_id=p_invoice_id
    );

  v_net := greatest(0,v_paid-v_refunded);

  if v_net >= v_invoice.total_kes then
    v_status := 'PAID';
  elsif v_net > 0 then
    v_status := 'PARTIALLY_PAID';
  elsif v_invoice.due_date < current_date then
    v_status := 'OVERDUE';
  else
    v_status := 'ISSUED';
  end if;

  update public.billing_invoices
     set status=v_status,updated_at=now()
   where id=p_invoice_id;

  return v_status;
end;
$function$;

revoke execute on function public.platform_recalculate_invoice_status(uuid) from public,anon,authenticated;
grant execute on function public.platform_recalculate_invoice_status(uuid) to service_role;

create or replace function public.platform_confirm_payment_refund(
  p_refund_id uuid,
  p_provider_reference text default null,
  p_provider text default null
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_refund public.billing_payment_refunds;
  v_payment public.billing_payments;
  v_invoice_id uuid;
  v_invoice_status text;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select * into v_refund
  from public.billing_payment_refunds
  where id=p_refund_id
  for update;

  if not found then raise exception 'REFUND_NOT_FOUND'; end if;
  if v_refund.status='CONFIRMED' then
    select a.invoice_id into v_invoice_id
    from public.billing_payment_allocations a
    where a.payment_id=v_refund.payment_id
    limit 1;
    if v_invoice_id is not null then
      v_invoice_status := public.platform_recalculate_invoice_status(v_invoice_id);
    end if;
    return jsonb_build_object('ok',true,'status','CONFIRMED','invoice_status',v_invoice_status);
  end if;

  select * into v_payment
  from public.billing_payments
  where id=v_refund.payment_id;

  if not found then raise exception 'PAYMENT_NOT_FOUND'; end if;

  update public.billing_payment_refunds
     set status='CONFIRMED',
         provider_reference=coalesce(p_provider_reference,provider_reference),
         provider=coalesce(p_provider,provider),
         confirmed_at=now(),
         updated_at=now()
   where id=p_refund_id;

  select a.invoice_id into v_invoice_id
  from public.billing_payment_allocations a
  where a.payment_id=v_refund.payment_id
  order by a.invoice_id
  limit 1;

  if v_invoice_id is not null then
    v_invoice_status := public.platform_recalculate_invoice_status(v_invoice_id);
  end if;

  if (
    select coalesce(sum(amount_kes),0)
    from public.billing_payment_refunds
    where payment_id=v_refund.payment_id and status='CONFIRMED'
  ) = (
    select coalesce(sum(amount_kes),0)
    from public.billing_payment_allocations
    where payment_id=v_refund.payment_id
  ) then
    update public.billing_payments
       set status='REFUNDED',updated_at=now()
     where id=v_refund.payment_id;
  end if;

  insert into public.billing_events(
    institution_id,event_type,payment_id,metadata,idempotency_key
  ) values(
    v_refund.institution_id,'PAYMENT_REFUND_CONFIRMED',v_refund.payment_id,
    jsonb_build_object(
      'refund_id',p_refund_id,
      'amount_kes',v_refund.amount_kes,
      'provider',p_provider,
      'provider_reference',p_provider_reference,
      'invoice_id',v_invoice_id,
      'invoice_status',v_invoice_status
    ),
    'refund-confirm:'||p_refund_id::text
  ) on conflict (idempotency_key) do nothing;

  return jsonb_build_object(
    'ok',true,
    'status','CONFIRMED',
    'refund_id',p_refund_id,
    'invoice_id',v_invoice_id,
    'invoice_status',v_invoice_status
  );
end;
$function$;

revoke execute on function public.platform_confirm_payment_refund(uuid,text,text) from public,anon,authenticated;
grant execute on function public.platform_confirm_payment_refund(uuid,text,text) to service_role;
