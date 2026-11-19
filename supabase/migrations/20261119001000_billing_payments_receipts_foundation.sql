-- IMBOP Billing & Payments — receipts and payment-intent foundation
-- Branch: feature/billing-system
-- Purpose: extend the internal billing ledger so a confirmed payment can produce an auditable receipt
-- and a future provider checkout can be initiated without coupling IMBOP to one payment provider.

create sequence if not exists public.imbop_receipt_number_seq;

create table if not exists public.billing_payment_intents (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  invoice_id uuid references public.billing_invoices(id) on delete restrict,
  payment_method text not null,
  provider text,
  amount_kes numeric(14,2) not null,
  currency text not null default 'KES',
  status text not null default 'CREATED',
  external_reference text,
  checkout_reference text,
  requested_by_user_id uuid references auth.users(id),
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint billing_payment_intents_method_check check (payment_method in ('MPESA','AIRTEL_MONEY','BANK_TRANSFER','CARD','OTHER')),
  constraint billing_payment_intents_status_check check (status in ('CREATED','PENDING','SUCCEEDED','FAILED','CANCELLED','EXPIRED')),
  constraint billing_payment_intents_amount_check check (amount_kes > 0),
  constraint billing_payment_intents_currency_check check (currency = 'KES')
);

create table if not exists public.billing_receipts (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  payment_id uuid not null references public.billing_payments(id) on delete restrict,
  receipt_number text not null unique,
  amount_kes numeric(14,2) not null,
  currency text not null default 'KES',
  issued_at timestamptz not null default now(),
  issued_to_name text,
  issued_to_email text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint billing_receipts_amount_check check (amount_kes > 0),
  constraint billing_receipts_currency_check check (currency = 'KES'),
  constraint billing_receipts_payment_unique unique (payment_id)
);

create index if not exists billing_payment_intents_institution_status_idx
  on public.billing_payment_intents(institution_id,status,created_at desc);
create index if not exists billing_payment_intents_invoice_idx
  on public.billing_payment_intents(invoice_id,created_at desc);
create index if not exists billing_receipts_institution_time_idx
  on public.billing_receipts(institution_id,issued_at desc);

alter table public.billing_payment_intents enable row level security;
alter table public.billing_receipts enable row level security;

drop policy if exists billing_payment_intents_institution_select on public.billing_payment_intents;
create policy billing_payment_intents_institution_select
on public.billing_payment_intents for select
to authenticated
using (private.has_institution_permission(institution_id,'institution_admin'));

drop policy if exists billing_receipts_institution_select on public.billing_receipts;
create policy billing_receipts_institution_select
on public.billing_receipts for select
to authenticated
using (private.has_institution_permission(institution_id,'institution_admin'));

revoke all on table public.billing_payment_intents from anon, authenticated;
revoke all on table public.billing_receipts from anon, authenticated;
grant select on table public.billing_payment_intents to authenticated;
grant select on table public.billing_receipts to authenticated;

create or replace function public.platform_create_payment_intent(
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
security definer
set search_path to ''
as $function$
declare
  v_id uuid;
  v_user uuid := auth.uid();
begin
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;
  if p_amount_kes <= 0 then raise exception 'INVALID_PAYMENT_AMOUNT'; end if;
  if p_invoice_id is not null and not exists (
    select 1 from public.billing_invoices
    where id=p_invoice_id and institution_id=p_institution_id
  ) then
    raise exception 'INVOICE_NOT_FOUND';
  end if;

  insert into public.billing_payment_intents(
    institution_id,invoice_id,payment_method,provider,amount_kes,status,
    requested_by_user_id,expires_at,metadata
  ) values (
    p_institution_id,p_invoice_id,upper(p_payment_method),p_provider,p_amount_kes,'CREATED',
    v_user,coalesce(p_expires_at,now()+interval '30 minutes'),coalesce(p_metadata,'{}'::jsonb)
  )
  returning id into v_id;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,actor_user_id,metadata
  ) values (
    p_institution_id,p_invoice_id,'PAYMENT_INTENT_CREATED',v_user,
    jsonb_build_object('payment_intent_id',v_id,'amount_kes',p_amount_kes,'payment_method',upper(p_payment_method),'provider',p_provider)
  );

  return v_id;
end;
$function$;

revoke execute on function public.platform_create_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) from public,anon,authenticated;
grant execute on function public.platform_create_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) to authenticated;

create or replace function public.platform_issue_payment_receipt(
  p_payment_id uuid,
  p_issued_to_name text default null,
  p_issued_to_email text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_payment public.billing_payments%rowtype;
  v_receipt_id uuid;
  v_receipt_number text;
  v_user uuid := auth.uid();
begin
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  select * into v_payment
    from public.billing_payments
   where id=p_payment_id
     and status='CONFIRMED';

  if not found then raise exception 'CONFIRMED_PAYMENT_NOT_FOUND'; end if;

  select id into v_receipt_id
    from public.billing_receipts
   where payment_id=p_payment_id;

  if v_receipt_id is not null then
    return v_receipt_id;
  end if;

  v_receipt_number := 'IMBOP-RCP-' || to_char(current_date,'YYYY') || '-' ||
    lpad(nextval('public.imbop_receipt_number_seq')::text,6,'0');

  insert into public.billing_receipts(
    institution_id,payment_id,receipt_number,amount_kes,
    issued_to_name,issued_to_email,notes
  ) values (
    v_payment.institution_id,p_payment_id,v_receipt_number,v_payment.amount_kes,
    p_issued_to_name,p_issued_to_email,p_notes
  ) returning id into v_receipt_id;

  insert into public.billing_events(
    institution_id,payment_id,event_type,actor_user_id,metadata,idempotency_key
  ) values (
    v_payment.institution_id,p_payment_id,'PAYMENT_RECEIPT_ISSUED',v_user,
    jsonb_build_object('receipt_id',v_receipt_id,'receipt_number',v_receipt_number),
    'receipt:'||p_payment_id::text
  ) on conflict (idempotency_key) do nothing;

  return v_receipt_id;
end;
$function$;

revoke execute on function public.platform_issue_payment_receipt(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.platform_issue_payment_receipt(uuid,text,text,text) to authenticated;

create or replace function public.get_my_billing_receipts(p_institution_id uuid)
returns table(
  receipt_id uuid,
  receipt_number text,
  payment_id uuid,
  amount_kes numeric,
  payment_method text,
  provider text,
  provider_reference text,
  issued_at timestamptz
)
language sql
security invoker
set search_path to 'public'
as $$
  select r.id,r.receipt_number,r.payment_id,r.amount_kes,
         p.payment_method,p.provider,p.provider_reference,r.issued_at
    from public.billing_receipts r
    join public.billing_payments p on p.id=r.payment_id
   where r.institution_id=p_institution_id
     and private.has_institution_permission(p_institution_id,'institution_admin')
   order by r.issued_at desc;
$$;

revoke execute on function public.get_my_billing_receipts(uuid) from anon;
grant execute on function public.get_my_billing_receipts(uuid) to authenticated;

-- Payment channels supported by the product-facing payment flow.
alter table public.billing_payments
  drop constraint if exists billing_payments_method_check;

alter table public.billing_payments
  add constraint billing_payments_method_check
  check (payment_method in ('MANUAL','BANK_TRANSFER','MPESA','AIRTEL_MONEY','CARD','OTHER'));

create or replace function private.issue_billing_receipt_for_payment()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_receipt_id uuid;
  v_receipt_number text;
begin
  if new.status <> 'CONFIRMED' then
    return new;
  end if;

  if exists (select 1 from public.billing_receipts where payment_id=new.id) then
    return new;
  end if;

  v_receipt_number := 'IMBOP-RCP-' || to_char(current_date,'YYYY') || '-' ||
    lpad(nextval('public.imbop_receipt_number_seq')::text,6,'0');

  insert into public.billing_receipts(
    institution_id,payment_id,receipt_number,amount_kes,notes
  ) values (
    new.institution_id,new.id,v_receipt_number,new.amount_kes,'System-issued receipt for confirmed payment'
  )
  returning id into v_receipt_id;

  insert into public.billing_events(
    institution_id,payment_id,event_type,metadata,idempotency_key
  ) values (
    new.institution_id,new.id,'PAYMENT_RECEIPT_ISSUED',
    jsonb_build_object('receipt_id',v_receipt_id,'receipt_number',v_receipt_number),
    'receipt:'||new.id::text
  ) on conflict (idempotency_key) do nothing;

  return new;
end;
$function$;

drop trigger if exists billing_payment_receipt_after_confirm on public.billing_payments;
create trigger billing_payment_receipt_after_confirm
after insert or update of status on public.billing_payments
for each row
execute function private.issue_billing_receipt_for_payment();

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
begin
  if not private.has_institution_permission(p_institution_id,'institution_admin') then
    raise exception 'INSTITUTION_PERMISSION_REQUIRED';
  end if;
  if p_amount_kes <= 0 then raise exception 'INVALID_PAYMENT_AMOUNT'; end if;
  if v_method not in ('MPESA','AIRTEL_MONEY','BANK_TRANSFER','CARD','OTHER') then
    raise exception 'INVALID_PAYMENT_METHOD';
  end if;
  if p_invoice_id is not null and not exists (
    select 1 from public.billing_invoices
    where id=p_invoice_id and institution_id=p_institution_id
      and status in ('ISSUED','PARTIALLY_PAID','OVERDUE')
  ) then
    raise exception 'INVOICE_NOT_PAYABLE';
  end if;

  insert into public.billing_payment_intents(
    institution_id,invoice_id,payment_method,provider,amount_kes,status,
    requested_by_user_id,expires_at,metadata
  ) values (
    p_institution_id,p_invoice_id,v_method,p_provider,p_amount_kes,'CREATED',
    v_user,coalesce(p_expires_at,now()+interval '30 minutes'),coalesce(p_metadata,'{}'::jsonb)
  )
  returning id into v_id;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,actor_user_id,metadata
  ) values (
    p_institution_id,p_invoice_id,'PAYMENT_INTENT_CREATED',v_user,
    jsonb_build_object('payment_intent_id',v_id,'amount_kes',p_amount_kes,'payment_method',v_method,'provider',p_provider)
  );

  return v_id;
end;
$function$;

revoke execute on function public.create_my_billing_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) from public,anon;
grant execute on function public.create_my_billing_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) to authenticated;

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
      select sum(i.total_kes - coalesce((select sum(a.amount_kes) from public.billing_payment_allocations a where a.invoice_id=i.id),0))
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
        'outstanding_kes',i.total_kes-coalesce((select sum(a.amount_kes) from public.billing_payment_allocations a where a.invoice_id=i.id),0)
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
