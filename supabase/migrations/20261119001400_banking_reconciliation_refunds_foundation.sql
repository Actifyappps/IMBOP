-- IMBOP Banking, Reconciliation & Refund Foundation
-- Provider-neutral foundation for bank transfer settlement, statement reconciliation and refunds.
-- No live bank API or money movement is activated by this migration.

create table if not exists public.billing_settlement_accounts (
  id uuid primary key default gen_random_uuid(),
  account_name text not null,
  bank_name text not null,
  branch_name text,
  account_number text not null,
  currency text not null default 'KES',
  swift_code text,
  paybill_number text,
  till_number text,
  reference_prefix text not null default 'IMBOP',
  active boolean not null default true,
  instructions text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.billing_bank_statement_imports (
  id uuid primary key default gen_random_uuid(),
  settlement_account_id uuid not null references public.billing_settlement_accounts(id),
  statement_period_start date,
  statement_period_end date,
  source_type text not null default 'MANUAL',
  source_reference text,
  status text not null default 'RECEIVED',
  imported_by_user_id uuid references auth.users(id),
  imported_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  constraint billing_bank_statement_import_status_chk check (status in ('RECEIVED','PROCESSING','RECONCILED','PARTIAL','FAILED'))
);

create table if not exists public.billing_bank_statement_entries (
  id uuid primary key default gen_random_uuid(),
  import_id uuid not null references public.billing_bank_statement_imports(id) on delete cascade,
  settlement_account_id uuid not null references public.billing_settlement_accounts(id),
  transaction_date timestamptz not null,
  value_date timestamptz,
  external_reference text,
  narrative text,
  amount_kes numeric(14,2) not null,
  direction text not null,
  counterparty_name text,
  counterparty_account text,
  matched_payment_intent_id uuid references public.billing_payment_intents(id),
  matched_payment_id uuid references public.billing_payments(id),
  reconciliation_status text not null default 'UNMATCHED',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint billing_bank_statement_entry_direction_chk check (direction in ('CREDIT','DEBIT')),
  constraint billing_bank_statement_entry_amount_chk check (amount_kes > 0),
  constraint billing_bank_statement_entry_recon_chk check (reconciliation_status in ('UNMATCHED','MATCHED','EXCEPTION','IGNORED'))
);

create unique index if not exists billing_bank_statement_entry_external_ref_unique_idx
  on public.billing_bank_statement_entries(settlement_account_id, external_reference)
  where external_reference is not null;

create index if not exists billing_bank_statement_entries_unmatched_idx
  on public.billing_bank_statement_entries(settlement_account_id, reconciliation_status, transaction_date);

create table if not exists public.billing_payment_refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.billing_payments(id),
  institution_id uuid not null references public.institutions(id),
  amount_kes numeric(14,2) not null,
  currency text not null default 'KES',
  status text not null default 'REQUESTED',
  provider text,
  provider_reference text,
  reason text,
  requested_by_user_id uuid references auth.users(id),
  confirmed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint billing_payment_refund_amount_chk check (amount_kes > 0),
  constraint billing_payment_refund_status_chk check (status in ('REQUESTED','CONFIRMED','FAILED','CANCELLED'))
);

create unique index if not exists billing_payment_refunds_provider_reference_unique_idx
  on public.billing_payment_refunds(provider, provider_reference)
  where provider is not null and provider_reference is not null;

create index if not exists billing_payment_refunds_payment_idx
  on public.billing_payment_refunds(payment_id, status);

alter table public.billing_settlement_accounts enable row level security;
alter table public.billing_bank_statement_imports enable row level security;
alter table public.billing_bank_statement_entries enable row level security;
alter table public.billing_payment_refunds enable row level security;

revoke all on public.billing_settlement_accounts from anon, authenticated;
revoke all on public.billing_bank_statement_imports from anon, authenticated;
revoke all on public.billing_bank_statement_entries from anon, authenticated;
revoke all on public.billing_payment_refunds from anon, authenticated;

create or replace function public.platform_record_bank_statement_entry(
  p_settlement_account_id uuid,
  p_transaction_date timestamptz,
  p_amount_kes numeric,
  p_external_reference text,
  p_narrative text default null,
  p_counterparty_name text default null,
  p_counterparty_account text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare v_id uuid;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if p_amount_kes <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  -- A statement entry must belong to a real import batch.
  insert into public.billing_bank_statement_imports(settlement_account_id,source_type,status,metadata)
  values(p_settlement_account_id,'MANUAL','PROCESSING',jsonb_build_object('auto_created',true))
  returning id into v_id;

  insert into public.billing_bank_statement_entries(
    import_id,settlement_account_id,transaction_date,external_reference,narrative,
    amount_kes,direction,counterparty_name,counterparty_account,metadata
  )
  select
    v_id,p_settlement_account_id,p_transaction_date,p_external_reference,p_narrative,
    p_amount_kes,'CREDIT',p_counterparty_name,p_counterparty_account,p_metadata
  where not exists (
    select 1 from public.billing_bank_statement_entries e
    where e.settlement_account_id=p_settlement_account_id
      and e.external_reference is not null
      and e.external_reference=p_external_reference
  )
  returning id into v_id;

  return v_id;
end;
$function$;

revoke execute on function public.platform_record_bank_statement_entry(uuid,timestamptz,numeric,text,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.platform_record_bank_statement_entry(uuid,timestamptz,numeric,text,text,text,text,jsonb) to service_role;

create or replace function public.platform_request_payment_refund(
  p_payment_id uuid,
  p_amount_kes numeric,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_payment public.billing_payments;
  v_confirmed numeric(14,2);
  v_refunded numeric(14,2);
  v_id uuid;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select * into v_payment from public.billing_payments where id=p_payment_id for update;
  if not found or v_payment.status <> 'CONFIRMED' then raise exception 'PAYMENT_NOT_REFUNDABLE'; end if;

  select coalesce(sum(amount_kes),0) into v_confirmed from public.billing_payment_allocations where payment_id=p_payment_id;
  select coalesce(sum(amount_kes),0) into v_refunded from public.billing_payment_refunds where payment_id=p_payment_id and status in ('REQUESTED','CONFIRMED');

  if (select count(distinct invoice_id) from public.billing_payment_allocations where payment_id=p_payment_id) <> 1 then
    raise exception 'REFUND_REQUIRES_SINGLE_INVOICE_PAYMENT';
  end if;

  if p_amount_kes <= 0 or p_amount_kes + v_refunded > v_confirmed then
    raise exception 'REFUND_EXCEEDS_SETTLED_PAYMENT';
  end if;

  insert into public.billing_payment_refunds(payment_id,institution_id,amount_kes,reason)
  values(p_payment_id,v_payment.institution_id,p_amount_kes,p_reason)
  returning id into v_id;

  insert into public.billing_events(institution_id,event_type,entity_type,entity_id,payload)
  values(v_payment.institution_id,'PAYMENT_REFUND_REQUESTED','PAYMENT',p_payment_id,
    jsonb_build_object('refund_id',v_id,'amount_kes',p_amount_kes,'reason',p_reason));

  return v_id;
end;
$function$;

revoke execute on function public.platform_request_payment_refund(uuid,numeric,text) from public,anon,authenticated;
grant execute on function public.platform_request_payment_refund(uuid,numeric,text) to service_role;

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
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select * into v_refund from public.billing_payment_refunds where id=p_refund_id for update;
  if not found then raise exception 'REFUND_NOT_FOUND'; end if;
  if v_refund.status='CONFIRMED' then return jsonb_build_object('ok',true,'status','CONFIRMED'); end if;

  select * into v_payment from public.billing_payments where id=v_refund.payment_id;
  if not found then raise exception 'PAYMENT_NOT_FOUND'; end if;

  update public.billing_payment_refunds
     set status='CONFIRMED',provider_reference=coalesce(p_provider_reference,provider_reference),
         provider=coalesce(p_provider,provider),confirmed_at=now(),updated_at=now()
   where id=p_refund_id;

  if v_refund.amount_kes = (
    select coalesce(sum(amount_kes),0) from public.billing_payment_refunds
    where payment_id=v_refund.payment_id and status='CONFIRMED'
  ) then
    update public.billing_payments set status='REFUNDED', updated_at=now() where id=v_refund.payment_id;
  end if;

  insert into public.billing_events(institution_id,event_type,entity_type,entity_id,payload)
  values(v_refund.institution_id,'PAYMENT_REFUND_CONFIRMED','PAYMENT',v_refund.payment_id,
    jsonb_build_object('refund_id',p_refund_id,'amount_kes',v_refund.amount_kes,
                       'provider',p_provider,'provider_reference',p_provider_reference));

  return jsonb_build_object('ok',true,'status','CONFIRMED','refund_id',p_refund_id);
end;
$function$;

revoke execute on function public.platform_confirm_payment_refund(uuid,text,text) from public,anon,authenticated;
grant execute on function public.platform_confirm_payment_refund(uuid,text,text) to service_role;

-- Rebuild the institution dashboard balance so confirmed refunds increase the amount still owed.
create or replace function public.get_my_billing_dashboard(p_institution_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path to ''
as $function$
declare v jsonb;
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
      select sum(i.total_kes
        - coalesce((select sum(a.amount_kes) from public.billing_payment_allocations a join public.billing_payments p on p.id=a.payment_id where a.invoice_id=i.id and p.status='CONFIRMED'),0)
        + coalesce((select sum(r.amount_kes) from public.billing_payment_refunds r join public.billing_payments p on p.id=r.payment_id where p.status='CONFIRMED' and r.status='CONFIRMED' and exists(select 1 from public.billing_payment_allocations a where a.payment_id=p.id and a.invoice_id=i.id)),0))
      from public.billing_invoices i
      where i.institution_id=b.institution_id and i.status in ('ISSUED','PARTIALLY_PAID','OVERDUE')
    ),0),
    'latest_invoice',(
      select jsonb_build_object(
        'id',i.id,'invoice_number',i.invoice_number,'plan_code',i.plan_code,
        'period_start',i.period_start,'period_end',i.period_end,'due_date',i.due_date,
        'total_kes',i.total_kes,'status',i.status,
        'outstanding_kes',i.total_kes
          - coalesce((select sum(a.amount_kes) from public.billing_payment_allocations a join public.billing_payments p on p.id=a.payment_id where a.invoice_id=i.id and p.status='CONFIRMED'),0)
          + coalesce((select sum(r.amount_kes) from public.billing_payment_refunds r join public.billing_payments p on p.id=r.payment_id where p.status='CONFIRMED' and r.status='CONFIRMED' and exists(select 1 from public.billing_payment_allocations a where a.payment_id=p.id and a.invoice_id=i.id)),0)
      )
      from public.billing_invoices i where i.institution_id=b.institution_id order by i.issued_at desc,i.created_at desc limit 1
    )
  ) into v
  from public.institution_billing_accounts b join public.institutions inst on inst.id=b.institution_id
  where b.institution_id=p_institution_id;
  return coalesce(v,'{}'::jsonb);
end;
$function$;

revoke execute on function public.get_my_billing_dashboard(uuid) from anon;
grant execute on function public.get_my_billing_dashboard(uuid) to authenticated;
