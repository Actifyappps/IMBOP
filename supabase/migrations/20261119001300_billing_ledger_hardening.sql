-- IMBOP Billing & Payments hardening
-- Purpose: close concurrency, reconciliation and ledger-integrity gaps found during review.

-- A provider transaction reference must never create two confirmed payments.
create unique index if not exists billing_payments_provider_reference_unique_idx
  on public.billing_payments(provider, provider_reference)
  where provider is not null and provider_reference is not null;

-- Payment allocations must never exceed the invoice total, even under concurrent provider callbacks.
create or replace function private.guard_billing_payment_allocation()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_payment_institution uuid;
  v_payment_status text;
  v_invoice_institution uuid;
  v_invoice_total numeric(14,2);
  v_allocated numeric(14,2);
begin
  select p.institution_id,p.status
    into v_payment_institution,v_payment_status
    from public.billing_payments p
   where p.id=new.payment_id
   for update;

  if not found then raise exception 'PAYMENT_NOT_FOUND'; end if;
  if v_payment_status <> 'CONFIRMED' then raise exception 'PAYMENT_NOT_CONFIRMED'; end if;

  select i.institution_id,i.total_kes
    into v_invoice_institution,v_invoice_total
    from public.billing_invoices i
   where i.id=new.invoice_id
   for update;

  if not found then raise exception 'INVOICE_NOT_FOUND'; end if;
  if v_payment_institution <> v_invoice_institution then
    raise exception 'PAYMENT_INVOICE_INSTITUTION_MISMATCH';
  end if;

  select coalesce(sum(a.amount_kes),0)
    into v_allocated
    from public.billing_payment_allocations a
   where a.invoice_id=new.invoice_id
     and (tg_op <> 'UPDATE' or a.id <> new.id);

  if v_allocated + new.amount_kes > v_invoice_total then
    raise exception 'PAYMENT_ALLOCATION_EXCEEDS_INVOICE';
  end if;

  if new.amount_kes <= 0 then raise exception 'INVALID_ALLOCATION_AMOUNT'; end if;
  return new;
end;
$function$;

revoke execute on function private.guard_billing_payment_allocation() from public,anon,authenticated;

drop trigger if exists billing_payment_allocation_guard on public.billing_payment_allocations;
create trigger billing_payment_allocation_guard
before insert or update of amount_kes,payment_id,invoice_id
on public.billing_payment_allocations
for each row execute function private.guard_billing_payment_allocation();

-- Outstanding calculations must count only confirmed money.
create or replace function public.get_my_billing_dashboard(p_institution_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path to ''
as $function$
declare
  v jsonb;
begin
  if not private.has_institution_permission(p_institution_id,'institution_admin') then
    raise exception 'INSTITUTION_PERMISSION_REQUIRED';
  end if;

  select jsonb_build_object(
    'institution_id',b.institution_id,
    'institution_name',inst.name,
    'plan_code',b.plan_code,
    'member_limit',b.member_limit,
    'monthly_fee_kes',b.monthly_fee_kes,
    'billing_status',b.billing_status,
    'compliance_status',b.compliance_status,
    'pilot_end_date',b.pilot_end_date,
    'next_due_date',b.next_due_date,
    'imbop_onboards',(select count(*) from public.memberships m where m.institution_id=b.institution_id and m.status='active'),
    'outstanding_kes',coalesce((
      select sum(i.total_kes - coalesce((
        select sum(a.amount_kes)
          from public.billing_payment_allocations a
          join public.billing_payments p on p.id=a.payment_id
         where a.invoice_id=i.id and p.status='CONFIRMED'
      ),0))
        from public.billing_invoices i
       where i.institution_id=b.institution_id
         and i.status in ('ISSUED','PARTIALLY_PAID','OVERDUE')
    ),0),
    'latest_invoice',(
      select jsonb_build_object(
        'id',i.id,
        'invoice_number',i.invoice_number,
        'plan_code',i.plan_code,
        'period_start',i.period_start,
        'period_end',i.period_end,
        'due_date',i.due_date,
        'total_kes',i.total_kes,
        'status',i.status,
        'outstanding_kes',i.total_kes-coalesce((
          select sum(a.amount_kes)
            from public.billing_payment_allocations a
            join public.billing_payments p on p.id=a.payment_id
           where a.invoice_id=i.id and p.status='CONFIRMED'
        ),0)
      )
      from public.billing_invoices i
      where i.institution_id=b.institution_id
      order by i.issued_at desc,i.created_at desc
      limit 1
    )
  ) into v
  from public.institution_billing_accounts b
  join public.institutions inst on inst.id=b.institution_id
  where b.institution_id=p_institution_id;

  return coalesce(v,'{}'::jsonb);
end;
$function$;

revoke execute on function public.get_my_billing_dashboard(uuid) from anon;
grant execute on function public.get_my_billing_dashboard(uuid) to authenticated;

-- Controlled service operation for expiring stale payment intents.
create or replace function public.platform_expire_stale_payment_intents(p_as_of timestamptz default now())
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_count integer;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  update public.billing_payment_intents
     set status='EXPIRED',updated_at=now()
   where status in ('CREATED','PENDING')
     and expires_at is not null
     and expires_at <= p_as_of;

  get diagnostics v_count = row_count;
  return v_count;
end;
$function$;

revoke execute on function public.platform_expire_stale_payment_intents(timestamptz) from public,anon,authenticated;
grant execute on function public.platform_expire_stale_payment_intents(timestamptz) to service_role;
