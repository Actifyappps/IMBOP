-- IMBOP Banking Reconciliation Hardening
-- Adds deterministic bank-transfer references and controlled statement reconciliation.
-- Bank statements remain settlement evidence; only the service role may finalize a payment.

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
  v_reference text;
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

  if v_method = 'BANK_TRANSFER' then
    v_reference := 'IMBOP-' || upper(substr(replace(v_id::text,'-',''),1,12));
    update public.billing_payment_intents
       set checkout_reference=v_reference
     where id=v_id;
  end if;

  insert into public.billing_events(
    institution_id,invoice_id,event_type,actor_user_id,metadata
  ) values (
    p_institution_id,p_invoice_id,'PAYMENT_INTENT_CREATED',v_user,
    jsonb_build_object(
      'payment_intent_id',v_id,
      'amount_kes',p_amount_kes,
      'payment_method',v_method,
      'payment_reference',v_reference,
      'provider',p_provider
    )
  );

  return v_id;
end;
$function$;

revoke execute on function public.create_my_billing_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) from public,anon;
grant execute on function public.create_my_billing_payment_intent(uuid,numeric,text,uuid,text,timestamptz,jsonb) to authenticated;

create or replace function public.platform_reconcile_bank_statement_entry(
  p_entry_id uuid,
  p_payment_intent_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_entry public.billing_bank_statement_entries%rowtype;
  v_intent public.billing_payment_intents%rowtype;
  v_invoice public.billing_invoices%rowtype;
  v_payment_id uuid;
  v_match_reason text;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select * into v_entry
  from public.billing_bank_statement_entries
  where id=p_entry_id
  for update;

  if not found then raise exception 'STATEMENT_ENTRY_NOT_FOUND'; end if;
  if v_entry.direction <> 'CREDIT' then
    update public.billing_bank_statement_entries
       set reconciliation_status='IGNORED'
     where id=p_entry_id;
    return jsonb_build_object('ok',true,'status','IGNORED','reason','NON_CREDIT_ENTRY');
  end if;

  if v_entry.reconciliation_status='MATCHED' then
    return jsonb_build_object('ok',true,'status','MATCHED','payment_intent_id',v_entry.matched_payment_intent_id);
  end if;

  if p_payment_intent_id is not null then
    select * into v_intent
    from public.billing_payment_intents
    where id=p_payment_intent_id
      and payment_method='BANK_TRANSFER'
    for update;
    if not found then raise exception 'BANK_PAYMENT_INTENT_NOT_FOUND'; end if;

    if v_intent.amount_kes <> v_entry.amount_kes then
      update public.billing_bank_statement_entries
         set reconciliation_status='EXCEPTION',
             metadata=metadata || jsonb_build_object('exception','AMOUNT_MISMATCH','expected_kes',v_intent.amount_kes)
       where id=p_entry_id;
      return jsonb_build_object('ok',false,'status','EXCEPTION','reason','AMOUNT_MISMATCH');
    end if;

    v_match_reason := 'MANUAL_INTENT_MATCH';
  else
    select * into v_intent
    from public.billing_payment_intents
    where payment_method='BANK_TRANSFER'
      and status in ('CREATED','PENDING')
      and checkout_reference is not null
      and checkout_reference = upper(trim(coalesce(v_entry.external_reference,'')))
      and amount_kes = v_entry.amount_kes
      and expires_at > now()
    order by created_at asc
    limit 1
    for update;

    if not found then
      update public.billing_bank_statement_entries
         set reconciliation_status='EXCEPTION',
             metadata=metadata || jsonb_build_object('exception','NO_EXACT_PAYMENT_INTENT_MATCH')
       where id=p_entry_id;
      return jsonb_build_object('ok',false,'status','EXCEPTION','reason','NO_EXACT_PAYMENT_INTENT_MATCH');
    end if;

    v_match_reason := 'EXACT_REFERENCE_AND_AMOUNT';
  end if;

  if v_intent.invoice_id is null then
    update public.billing_bank_statement_entries
       set reconciliation_status='EXCEPTION',
           metadata=metadata || jsonb_build_object('exception','PAYMENT_INTENT_HAS_NO_INVOICE')
     where id=p_entry_id;
    return jsonb_build_object('ok',false,'status','EXCEPTION','reason','PAYMENT_INTENT_HAS_NO_INVOICE');
  end if;

  select * into v_invoice
  from public.billing_invoices
  where id=v_intent.invoice_id
    and institution_id=v_intent.institution_id
  for update;

  if not found or v_invoice.status not in ('ISSUED','PARTIALLY_PAID','OVERDUE') then
    update public.billing_bank_statement_entries
       set reconciliation_status='EXCEPTION',
           metadata=metadata || jsonb_build_object('exception','INVOICE_NOT_PAYABLE')
     where id=p_entry_id;
    return jsonb_build_object('ok',false,'status','EXCEPTION','reason','INVOICE_NOT_PAYABLE');
  end if;

  update public.billing_payment_intents
     set status='SUCCEEDED',
         external_reference=coalesce(external_reference,v_entry.external_reference),
         updated_at=now(),
         metadata=metadata || jsonb_build_object(
           'bank_reconciled',true,
           'bank_statement_entry_id',p_entry_id,
           'reconciliation_reason',v_match_reason
         )
   where id=v_intent.id;

  insert into public.billing_payments(
    institution_id,invoice_id,amount_kes,payment_method,status,
    provider,provider_reference,received_at,metadata
  )
  values(
    v_intent.institution_id,v_intent.invoice_id,v_intent.amount_kes,'BANK_TRANSFER','CONFIRMED',
    'BANK_TRANSFER',v_entry.external_reference,coalesce(v_entry.value_date,v_entry.transaction_date),
    jsonb_build_object('payment_intent_id',v_intent.id,'statement_entry_id',p_entry_id)
  )
  returning id into v_payment_id;

  insert into public.billing_payment_allocations(payment_id,invoice_id,amount_kes)
  values(v_payment_id,v_intent.invoice_id,v_intent.amount_kes);

  update public.billing_bank_statement_entries
     set matched_payment_intent_id=v_intent.id,
         matched_payment_id=v_payment_id,
         reconciliation_status='MATCHED',
         metadata=metadata || jsonb_build_object(
           'matched_at',now(),
           'match_reason',v_match_reason
         )
   where id=p_entry_id;

  update public.billing_bank_statement_imports i
     set status='RECONCILED'
   where i.id=v_entry.import_id
     and not exists (
       select 1 from public.billing_bank_statement_entries e
       where e.import_id=i.id and e.reconciliation_status in ('UNMATCHED','EXCEPTION')
     );

  insert into public.billing_events(
    institution_id,invoice_id,payment_id,event_type,metadata,idempotency_key
  ) values(
    v_intent.institution_id,v_intent.invoice_id,v_payment_id,
    'BANK_PAYMENT_RECONCILED',
    jsonb_build_object(
      'payment_intent_id',v_intent.id,
      'statement_entry_id',p_entry_id,
      'amount_kes',v_intent.amount_kes,
      'external_reference',v_entry.external_reference,
      'match_reason',v_match_reason
    ),
    'bank-reconcile:'||p_entry_id::text
  ) on conflict (idempotency_key) do nothing;

  return jsonb_build_object(
    'ok',true,
    'status','MATCHED',
    'payment_intent_id',v_intent.id,
    'payment_id',v_payment_id,
    'amount_kes',v_intent.amount_kes
  );
end;
$function$;

revoke execute on function public.platform_reconcile_bank_statement_entry(uuid,uuid) from public,anon,authenticated;
grant execute on function public.platform_reconcile_bank_statement_entry(uuid,uuid) to service_role;

create or replace function public.platform_mark_bank_statement_import_status(
  p_import_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if p_status not in ('RECEIVED','PROCESSING','RECONCILED','PARTIAL','FAILED') then
    raise exception 'INVALID_IMPORT_STATUS';
  end if;
  update public.billing_bank_statement_imports
     set status=p_status
   where id=p_import_id;
end;
$function$;

revoke execute on function public.platform_mark_bank_statement_import_status(uuid,text) from public,anon,authenticated;
grant execute on function public.platform_mark_bank_statement_import_status(uuid,text) to service_role;

create index if not exists billing_payment_intents_bank_reference_idx
  on public.billing_payment_intents(checkout_reference)
  where payment_method='BANK_TRANSFER' and checkout_reference is not null;
