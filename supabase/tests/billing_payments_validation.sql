-- IMBOP Billing & Payments structural verification
-- Run against an isolated Supabase database after applying billing migrations.
-- This file intentionally performs no financial writes.

do $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from pg_tables
  where schemaname='public'
    and tablename in (
      'billing_invoices','billing_invoice_lines','billing_payments',
      'billing_payment_allocations','billing_events','billing_payment_intents',
      'billing_receipts','billing_settlement_accounts',
      'billing_bank_statement_imports','billing_bank_statement_entries',
      'billing_payment_refunds'
    );
  if v_count <> 11 then
    raise exception 'BILLING_TABLES_MISSING: expected 11, found %',v_count;
  end if;
end $$;

do $$
declare v_count integer;
begin
  select count(*) into v_count
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname in (
      'create_my_billing_payment_intent',
      'platform_create_payment_intent',
      'platform_finalize_payment_intent_from_provider',
      'platform_fail_payment_intent',
      'platform_issue_payment_receipt',
      'get_my_billing_dashboard',
      'get_my_billing_payment_instructions',
      'platform_expire_stale_payment_intents',
      'platform_record_bank_statement_entry',
      'platform_request_payment_refund',
      'platform_confirm_payment_refund',
      'platform_reconcile_bank_statement_entry',
      'platform_mark_bank_statement_import_status'
    );
  if v_count < 13 then
    raise exception 'BILLING_FUNCTIONS_MISSING: expected at least 13, found %',v_count;
  end if;
end $$;

do $$
declare v_count integer;
begin
  select count(*) into v_count
  from pg_indexes
  where schemaname='public'
    and indexname in (
      'billing_payments_provider_reference_unique_idx',
      'billing_bank_statement_entry_external_ref_unique_idx',
      'billing_payment_refunds_provider_reference_unique_idx'
    );
  if v_count <> 3 then
    raise exception 'BILLING_UNIQUENESS_GUARDS_MISSING: expected 3, found %',v_count;
  end if;
end $$;

-- Bank-transfer reconciliation must have a lookup index.
do $
declare v_count integer;
begin
  select count(*) into v_count
  from pg_indexes
  where schemaname='public'
    and indexname='billing_payment_intents_bank_reference_idx';
  if v_count <> 1 then raise exception 'BANK_REFERENCE_INDEX_MISSING'; end if;
end $;

-- Payment/refund state constraints must exist.
do $$
declare v_count integer;
begin
  select count(*) into v_count
  from pg_constraint
  where conrelid='public.billing_payment_intents'::regclass
    and contype='c';
  if v_count = 0 then raise exception 'PAYMENT_INTENT_CONSTRAINTS_MISSING'; end if;
end $$;

-- No direct API role should have table-level write access to the new banking/refund tables.
do $$
declare v_bad integer;
begin
  select count(*) into v_bad
  from information_schema.role_table_grants
  where table_schema='public'
    and table_name in (
      'billing_settlement_accounts','billing_bank_statement_imports',
      'billing_bank_statement_entries','billing_payment_refunds'
    )
    and grantee in ('anon','authenticated')
    and privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE');
  if v_bad <> 0 then
    raise exception 'BILLING_API_WRITE_GRANTS_PRESENT: %',v_bad;
  end if;
end $$;

select 'BILLING STRUCTURAL TESTS PASS' as result;
