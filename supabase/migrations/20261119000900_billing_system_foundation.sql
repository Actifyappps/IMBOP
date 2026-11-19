-- IMBOP Billing System Foundation
-- Branch: feature/billing-system
-- Purpose: establish auditable institutional billing, invoicing and payment-record infrastructure.
-- Payment processing/provider integration is intentionally NOT included in this migration.

create sequence if not exists public.imbop_invoice_number_seq;

create table if not exists public.billing_invoices (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  invoice_number text not null unique,
  plan_code text not null,
  period_start date not null,
  period_end date not null,
  issued_at timestamptz not null default now(),
  due_date date not null,
  currency text not null default 'KES',
  onboards_snapshot integer not null default 0,
  subtotal_kes numeric(14,2) not null default 0,
  adjustments_kes numeric(14,2) not null default 0,
  total_kes numeric(14,2) not null default 0,
  status text not null default 'DRAFT',
  notes text,
  created_by_user_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint billing_invoices_period_check check (period_end >= period_start),
  constraint billing_invoices_due_check check (due_date >= period_start),
  constraint billing_invoices_money_check check (subtotal_kes >= 0 and total_kes >= 0),
  constraint billing_invoices_onboards_check check (onboards_snapshot >= 0),
  constraint billing_invoices_status_check check (status in ('DRAFT','ISSUED','PARTIALLY_PAID','PAID','OVERDUE','VOID','WAIVED')),
  constraint billing_invoices_currency_check check (currency = 'KES')
);

create table if not exists public.billing_invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.billing_invoices(id) on delete cascade,
  line_type text not null,
  description text not null,
  quantity numeric(14,2) not null default 1,
  unit_amount_kes numeric(14,2) not null default 0,
  line_amount_kes numeric(14,2) not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint billing_invoice_lines_type_check check (line_type in ('PLAN','TRANSITION','ADJUSTMENT','CREDIT','OTHER')),
  constraint billing_invoice_lines_quantity_check check (quantity >= 0),
  constraint billing_invoice_lines_amount_check check (unit_amount_kes >= 0 and line_amount_kes >= 0)
);

create table if not exists public.billing_payments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  provider text,
  provider_reference text,
  payment_method text not null default 'MANUAL',
  amount_kes numeric(14,2) not null,
  currency text not null default 'KES',
  status text not null default 'PENDING',
  received_at timestamptz,
  recorded_by_user_id uuid references auth.users(id),
  idempotency_key text unique,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint billing_payments_amount_check check (amount_kes > 0),
  constraint billing_payments_currency_check check (currency = 'KES'),
  constraint billing_payments_status_check check (status in ('PENDING','CONFIRMED','FAILED','REFUNDED')),
  constraint billing_payments_method_check check (payment_method in ('MANUAL','BANK_TRANSFER','MPESA','CARD','OTHER'))
);

create table if not exists public.billing_payment_allocations (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.billing_payments(id) on delete cascade,
  invoice_id uuid not null references public.billing_invoices(id) on delete restrict,
  amount_kes numeric(14,2) not null,
  created_at timestamptz not null default now(),
  constraint billing_payment_allocations_amount_check check (amount_kes > 0),
  constraint billing_payment_allocations_unique unique (payment_id, invoice_id)
);

create table if not exists public.billing_events (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  invoice_id uuid references public.billing_invoices(id) on delete set null,
  payment_id uuid references public.billing_payments(id) on delete set null,
  event_type text not null,
  actor_user_id uuid references auth.users(id),
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  idempotency_key text unique
);

create index if not exists billing_invoices_institution_status_idx
  on public.billing_invoices(institution_id,status,due_date desc);
create index if not exists billing_invoices_period_idx
  on public.billing_invoices(institution_id,period_start,period_end);
create index if not exists billing_invoice_lines_invoice_idx
  on public.billing_invoice_lines(invoice_id);
create index if not exists billing_payments_institution_status_idx
  on public.billing_payments(institution_id,status,received_at desc);
create index if not exists billing_payment_allocations_invoice_idx
  on public.billing_payment_allocations(invoice_id);
create index if not exists billing_events_institution_time_idx
  on public.billing_events(institution_id,occurred_at desc);
create index if not exists billing_events_invoice_idx
  on public.billing_events(invoice_id,occurred_at desc);

alter table public.billing_invoices enable row level security;
alter table public.billing_invoice_lines enable row level security;
alter table public.billing_payments enable row level security;
alter table public.billing_payment_allocations enable row level security;
alter table public.billing_events enable row level security;

drop policy if exists billing_invoices_institution_select on public.billing_invoices;
create policy billing_invoices_institution_select
on public.billing_invoices for select
to authenticated
using (private.has_institution_permission(institution_id,'institution_admin'));

drop policy if exists billing_invoice_lines_institution_select on public.billing_invoice_lines;
create policy billing_invoice_lines_institution_select
on public.billing_invoice_lines for select
to authenticated
using (exists (
  select 1 from public.billing_invoices i
  where i.id=billing_invoice_lines.invoice_id
    and private.has_institution_permission(i.institution_id,'institution_admin')
));

drop policy if exists billing_payments_institution_select on public.billing_payments;
create policy billing_payments_institution_select
on public.billing_payments for select
to authenticated
using (private.has_institution_permission(institution_id,'institution_admin'));

drop policy if exists billing_payment_allocations_institution_select on public.billing_payment_allocations;
create policy billing_payment_allocations_institution_select
on public.billing_payment_allocations for select
to authenticated
using (exists (
  select 1
  from public.billing_invoices i
  where i.id=billing_payment_allocations.invoice_id
    and private.has_institution_permission(i.institution_id,'institution_admin')
));

drop policy if exists billing_events_institution_select on public.billing_events;
create policy billing_events_institution_select
on public.billing_events for select
to authenticated
using (private.has_institution_permission(institution_id,'institution_admin'));

-- Platform administration is performed through tightly scoped RPCs rather than direct table writes.
revoke all on table public.billing_invoices from anon, authenticated;
revoke all on table public.billing_invoice_lines from anon, authenticated;
revoke all on table public.billing_payments from anon, authenticated;
revoke all on table public.billing_payment_allocations from anon, authenticated;
revoke all on table public.billing_events from anon, authenticated;
grant select on table public.billing_invoices to authenticated;
grant select on table public.billing_invoice_lines to authenticated;
grant select on table public.billing_payments to authenticated;
grant select on table public.billing_payment_allocations to authenticated;
grant select on table public.billing_events to authenticated;

create or replace function public.get_my_institution_billing_summary(p_institution_id uuid)
returns table(
  institution_id uuid,
  plan_code text,
  member_limit integer,
  monthly_fee_kes numeric,
  billing_status text,
  compliance_status text,
  pilot_end_date date,
  next_due_date date,
  current_onboards bigint,
  latest_invoice_id uuid,
  latest_invoice_number text,
  latest_invoice_status text,
  latest_invoice_total_kes numeric,
  latest_invoice_due_date date
)
language sql
security invoker
set search_path to 'public'
as $$
  with account as (
    select b.institution_id,b.plan_code,b.member_limit,b.monthly_fee_kes,b.billing_status,
           b.compliance_status,b.pilot_end_date,b.next_due_date
      from public.institution_billing_accounts b
     where b.institution_id=p_institution_id
       and private.has_institution_permission(p_institution_id,'institution_admin')
  ),
  onboard as (
    select count(*)::bigint current_onboards
      from public.memberships m
     where m.institution_id=p_institution_id
       and m.status='active'
  ),
  latest as (
    select i.id,i.invoice_number,i.status,i.total_kes,i.due_date
      from public.billing_invoices i
     where i.institution_id=p_institution_id
     order by i.issued_at desc,i.created_at desc
     limit 1
  )
  select a.institution_id,a.plan_code,a.member_limit,a.monthly_fee_kes,a.billing_status,
         a.compliance_status,a.pilot_end_date,a.next_due_date,o.current_onboards,
         l.id,l.invoice_number,l.status,l.total_kes,l.due_date
    from account a cross join onboard o left join latest l on true;
$$;

revoke execute on function public.get_my_institution_billing_summary(uuid) from anon;
grant execute on function public.get_my_institution_billing_summary(uuid) to authenticated;

create or replace function public.platform_create_invoice(
  p_institution_id uuid,
  p_period_start date,
  p_period_end date,
  p_due_date date,
  p_plan_code text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_invoice_id uuid;
  v_invoice_number text;
  v_plan_code text;
  v_onboards integer;
  v_fee numeric(14,2);
  v_transition numeric(14,2);
  v_total numeric(14,2);
  v_user uuid := auth.uid();
  v_status text;
begin
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  select count(*)::integer into v_onboards
    from public.memberships m
   where m.institution_id=p_institution_id
     and m.status='active';

  select coalesce(nullif(trim(p_plan_code),''),b.plan_code),
         b.monthly_fee_kes
    into v_plan_code,v_fee
    from public.institution_billing_accounts b
   where b.institution_id=p_institution_id;

  if v_plan_code is null then
    raise exception 'BILLING_ACCOUNT_NOT_FOUND';
  end if;

  select coalesce(p.transition_minimum_kes,0)
    into v_transition
    from public.imbop_pricing_plans p
   where p.plan_code=v_plan_code;

  if v_fee is null then
    select coalesce(p.monthly_fee_kes,0) into v_fee
      from public.imbop_pricing_plans p
     where p.plan_code=v_plan_code;
  end if;

  v_fee := coalesce(v_fee,0);
  v_transition := case
    when v_onboards > 50 and v_onboards <= 100 then coalesce(v_transition,5000)
    else 0
  end;
  v_total := greatest(0,v_fee + v_transition);

  v_status := case
    when v_total=0 then 'WAIVED'
    else 'ISSUED'
  end;

  v_invoice_number := 'IMBOP-' || to_char(p_period_start,'YYYY') || '-' ||
    lpad(nextval('public.imbop_invoice_number_seq')::text,6,'0');

  insert into public.billing_invoices(
    institution_id,invoice_number,plan_code,period_start,period_end,due_date,
    onboards_snapshot,subtotal_kes,adjustments_kes,total_kes,status,notes,created_by_user_id
  ) values (
    p_institution_id,v_invoice_number,v_plan_code,p_period_start,p_period_end,p_due_date,
    v_onboards,v_total,0,v_total,v_status,p_notes,v_user
  ) returning id into v_invoice_id;

  insert into public.billing_invoice_lines(
    invoice_id,line_type,description,quantity,unit_amount_kes,line_amount_kes,metadata
  ) values (
    v_invoice_id,'PLAN','IMBOP ' || v_plan_code || ' monthly plan',1,v_fee,v_fee,
    jsonb_build_object('onboards_snapshot',v_onboards,'plan_code',v_plan_code)
  );

  if v_transition > 0 then
    insert into public.billing_invoice_lines(
      invoice_id,line_type,description,quantity,unit_amount_kes,line_amount_kes,metadata
    ) values (
      v_invoice_id,'TRANSITION','Discounted first transition month minimum',1,v_transition,v_transition,
      jsonb_build_object('onboards_snapshot',v_onboards,'transition_minimum_kes',v_transition)
    );
  end if;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,actor_user_id,metadata,idempotency_key
  ) values (
    p_institution_id,v_invoice_id,
    case when v_status='WAIVED' then 'INVOICE_WAIVED' else 'INVOICE_ISSUED' end,
    v_user,
    jsonb_build_object('invoice_number',v_invoice_number,'total_kes',v_total,'onboards',v_onboards),
    'invoice:'||v_invoice_id::text
  ) on conflict (idempotency_key) do nothing;

  return v_invoice_id;
end;
$function$;

revoke execute on function public.platform_create_invoice(uuid,date,date,date,text,text) from public, anon, authenticated;
grant execute on function public.platform_create_invoice(uuid,date,date,date,text,text) to authenticated;

create or replace function public.platform_record_billing_payment(
  p_institution_id uuid,
  p_amount_kes numeric,
  p_payment_method text default 'MANUAL',
  p_provider text default null,
  p_provider_reference text default null,
  p_invoice_id uuid default null,
  p_received_at timestamptz default now(),
  p_idempotency_key text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_payment_id uuid;
  v_user uuid := auth.uid();
  v_remaining numeric(14,2) := p_amount_kes;
  r record;
  v_alloc numeric(14,2);
begin
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;
  if p_amount_kes <= 0 then raise exception 'INVALID_PAYMENT_AMOUNT'; end if;
  if p_invoice_id is not null and not exists(
    select 1 from public.billing_invoices
     where id=p_invoice_id and institution_id=p_institution_id
  ) then
    raise exception 'INVOICE_NOT_FOUND';
  end if;

  insert into public.billing_payments(
    institution_id,provider,provider_reference,payment_method,amount_kes,
    status,received_at,recorded_by_user_id,idempotency_key,notes
  ) values(
    p_institution_id,p_provider,p_provider_reference,upper(p_payment_method),p_amount_kes,
    'CONFIRMED',p_received_at,v_user,p_idempotency_key,p_notes
  )
  on conflict (idempotency_key) do update set updated_at=now()
  returning id into v_payment_id;

  if v_payment_id is null then
    select id into v_payment_id from public.billing_payments where idempotency_key=p_idempotency_key;
  end if;

  for r in
    select i.id,
           greatest(0,i.total_kes-coalesce((
             select sum(a.amount_kes)
               from public.billing_payment_allocations a
               join public.billing_payments p on p.id=a.payment_id
              where a.invoice_id=i.id and p.status='CONFIRMED'
           ),0)) outstanding
      from public.billing_invoices i
     where i.institution_id=p_institution_id
       and i.status in ('ISSUED','OVERDUE','PARTIALLY_PAID')
       and (p_invoice_id is null or i.id=p_invoice_id)
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

  insert into public.billing_events(
    institution_id,payment_id,event_type,actor_user_id,metadata,idempotency_key
  ) values(
    p_institution_id,v_payment_id,'PAYMENT_CONFIRMED',v_user,
    jsonb_build_object('amount_kes',p_amount_kes,'method',upper(p_payment_method),'provider_reference',p_provider_reference),
    case when p_idempotency_key is null then 'payment:'||v_payment_id::text else 'payment-event:'||p_idempotency_key end
  ) on conflict (idempotency_key) do nothing;

  update public.billing_invoices i
     set status=case
       when greatest(0,i.total_kes-coalesce((
         select sum(a.amount_kes) from public.billing_payment_allocations a
         join public.billing_payments p on p.id=a.payment_id
         where a.invoice_id=i.id and p.status='CONFIRMED'
       ),0)) <= 0 then 'PAID'
       when coalesce((
         select sum(a.amount_kes) from public.billing_payment_allocations a
         join public.billing_payments p on p.id=a.payment_id
         where a.invoice_id=i.id and p.status='CONFIRMED'
       ),0) > 0 then 'PARTIALLY_PAID'
       else i.status
     end,
     updated_at=now()
   where i.institution_id=p_institution_id
     and (p_invoice_id is null or i.id=p_invoice_id);

  return v_payment_id;
end;
$function$;

revoke execute on function public.platform_record_billing_payment(uuid,numeric,text,text,text,uuid,timestamptz,text,text) from public, anon, authenticated;
grant execute on function public.platform_record_billing_payment(uuid,numeric,text,text,text,uuid,timestamptz,text,text) to authenticated;

create or replace function public.platform_mark_overdue_invoices(p_as_of date default current_date)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_count integer;
begin
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  update public.billing_invoices i
     set status='OVERDUE',updated_at=now()
   where i.status in ('ISSUED','PARTIALLY_PAID')
     and i.due_date < p_as_of
     and greatest(0,i.total_kes-coalesce((
       select sum(a.amount_kes)
         from public.billing_payment_allocations a
         join public.billing_payments p on p.id=a.payment_id
        where a.invoice_id=i.id and p.status='CONFIRMED'
     ),0)) > 0;

  get diagnostics v_count=row_count;
  return v_count;
end;
$function$;

revoke execute on function public.platform_mark_overdue_invoices(date) from public, anon, authenticated;
grant execute on function public.platform_mark_overdue_invoices(date) to authenticated;

create or replace function public.platform_get_billing_accounts(
  p_status text default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table(
  institution_id uuid,
  institution_name text,
  plan_code text,
  member_limit integer,
  monthly_fee_kes numeric,
  billing_status text,
  compliance_status text,
  next_due_date date,
  current_onboards bigint,
  outstanding_kes numeric,
  latest_invoice_status text
)
language sql
security invoker
set search_path to 'public'
as $$
  with base as (
    select b.institution_id,b.plan_code,b.member_limit,b.monthly_fee_kes,b.billing_status,
           b.compliance_status,b.next_due_date,i.name institution_name,
           (select count(*) from public.memberships m where m.institution_id=b.institution_id and m.status='active') current_onboards
      from public.institution_billing_accounts b
      join public.institutions i on i.id=b.institution_id
     where private.has_platform_permission('institution_manage')
       and (nullif(trim(p_status),'') is null or b.billing_status=upper(trim(p_status)))
  ),
  outstanding as (
    select i.institution_id,
           coalesce(sum(greatest(0,i.total_kes-coalesce((
             select sum(a.amount_kes)
               from public.billing_payment_allocations a
               join public.billing_payments p on p.id=a.payment_id
              where a.invoice_id=i.id and p.status='CONFIRMED'
           ),0))),0) outstanding_kes
      from public.billing_invoices i
     where i.status not in ('PAID','WAIVED','VOID')
     group by i.institution_id
  ),
  latest as (
    select distinct on (i.institution_id) i.institution_id,i.status
      from public.billing_invoices i
     order by i.institution_id,i.issued_at desc,i.created_at desc
  )
  select b.institution_id,b.institution_name,b.plan_code,b.member_limit,b.monthly_fee_kes,
         b.billing_status,b.compliance_status,b.next_due_date,b.current_onboards,
         coalesce(o.outstanding_kes,0),l.status
    from base b
    left join outstanding o on o.institution_id=b.institution_id
    left join latest l on l.institution_id=b.institution_id
   order by b.institution_name
   limit greatest(1,least(coalesce(p_limit,100),500))
   offset greatest(0,coalesce(p_offset,0));
$$;

revoke execute on function public.platform_get_billing_accounts(text,integer,integer) from public, anon, authenticated;
grant execute on function public.platform_get_billing_accounts(text,integer,integer) to authenticated;
