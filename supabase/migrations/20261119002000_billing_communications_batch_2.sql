-- IMBOP Billing Communications — Batch 2
-- Billing state changes queue institution communications in the same transaction
-- as the authoritative ledger change.
--
-- Payment language is deliberately state-specific:
-- intent/request != confirmed payment; receipt is emitted only from confirmed payment.

alter table public.communication_records
  add column if not exists idempotency_key text,
  add column if not exists template_key text,
  add column if not exists template_version text;

create unique index if not exists communication_records_idempotency_uidx
  on public.communication_records(idempotency_key)
  where idempotency_key is not null;

create or replace function private.create_email_communication(
  p_institution_id uuid,
  p_recipient_user_id uuid,
  p_recipient_email text,
  p_recipient_name text,
  p_sender_user_id uuid,
  p_origin text,
  p_communication_type text,
  p_event_type text,
  p_subject text,
  p_body text,
  p_reference_type text,
  p_reference_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_communication_id uuid;
  v_idempotency_key text := nullif(trim(coalesce(p_metadata->>'idempotency_key','')), '');
  v_template_key text := nullif(trim(coalesce(p_metadata->>'template_key','')), '');
  v_template_version text := nullif(trim(coalesce(p_metadata->>'template_version','')), '');
begin
  if nullif(trim(coalesce(p_recipient_email,'')),'') is null then
    return null;
  end if;

  if v_idempotency_key is not null then
    select id into v_communication_id
      from public.communication_records
     where idempotency_key=v_idempotency_key
     limit 1;
    if v_communication_id is not null then return v_communication_id; end if;
  end if;

  insert into public.communication_records(
    institution_id,recipient_user_id,recipient_email,recipient_name,
    sender_user_id,origin,communication_type,event_type,subject,body,
    reference_type,reference_id,metadata,idempotency_key,template_key,template_version
  )
  values(
    p_institution_id,p_recipient_user_id,lower(trim(p_recipient_email)),p_recipient_name,
    p_sender_user_id,upper(coalesce(p_origin,'SYSTEM')),p_communication_type,p_event_type,
    p_subject,p_body,p_reference_type,p_reference_id,coalesce(p_metadata,'{}'::jsonb),
    v_idempotency_key,v_template_key,v_template_version
  )
  on conflict (idempotency_key) where idempotency_key is not null do nothing
  returning id into v_communication_id;

  if v_communication_id is null and v_idempotency_key is not null then
    select id into v_communication_id from public.communication_records
     where idempotency_key=v_idempotency_key limit 1;
  end if;

  insert into public.communication_deliveries(communication_id,channel,status)
  values(v_communication_id,'EMAIL','QUEUED')
  on conflict (communication_id,channel) do nothing;

  return v_communication_id;
end;
$function$;

-- One reusable trigger queues email to every active institution admin/owner.
create or replace function private.queue_billing_communication()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_event text;
  v_subject text;
  v_body text;
  v_reference_type text;
  v_reference_id uuid;
  v_institution_id uuid;
  v_key text;
  v_name text;
  v_amount numeric;
  v_number text;
  r record;
begin
  v_institution_id := case TG_TABLE_NAME
    when 'billing_invoices' then coalesce(NEW.institution_id,OLD.institution_id)
    when 'billing_payment_intents' then coalesce(NEW.institution_id,OLD.institution_id)
    when 'billing_payments' then coalesce(NEW.institution_id,OLD.institution_id)
    when 'billing_receipts' then coalesce(NEW.institution_id,OLD.institution_id)
    when 'billing_payment_refunds' then coalesce(NEW.institution_id,OLD.institution_id)
    when 'billing_bank_statement_entries' then (
      select pi.institution_id
        from public.billing_payment_intents pi
       where pi.id=coalesce(NEW.matched_payment_intent_id,OLD.matched_payment_intent_id)
       limit 1
    )
    else null
  end;

  if v_institution_id is null then return NEW; end if;

  if TG_TABLE_NAME='billing_invoices' then
    if NEW.status='ISSUED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='INVOICE_ISSUED';
      v_subject:='IMBOP invoice issued — '||NEW.invoice_number;
      v_body:='Your IMBOP invoice '||NEW.invoice_number||' has been issued for KES '||
        to_char(NEW.total_kes,'FM999,999,999,990.00')||'. Due date: '||NEW.due_date::text||'.';
      v_reference_type:='billing_invoice'; v_reference_id:=NEW.id;
    elsif NEW.status='OVERDUE' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='INVOICE_OVERDUE';
      v_subject:='IMBOP invoice overdue — '||NEW.invoice_number;
      v_body:='Your IMBOP invoice '||NEW.invoice_number||' is overdue. Outstanding amount should be reviewed in your IMBOP billing space.';
      v_reference_type:='billing_invoice'; v_reference_id:=NEW.id;
    elsif NEW.status='WAIVED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='INVOICE_WAIVED';
      v_subject:='IMBOP invoice waived — '||NEW.invoice_number;
      v_body:='Your IMBOP invoice '||NEW.invoice_number||' has been recorded as waived. No payment is required for this invoice unless IMBOP communicates otherwise.';
      v_reference_type:='billing_invoice'; v_reference_id:=NEW.id;
    end if;
  elsif TG_TABLE_NAME='billing_payment_intents' then
    if NEW.status='PENDING' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_PENDING';
      v_subject:='IMBOP payment pending — KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00');
      v_body:='A payment request for KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00')||
        ' is pending through '||upper(NEW.payment_method)||'. This message is a payment prompt/status notice only; it is not confirmation that payment has been received.';
      v_reference_type:='billing_payment_intent'; v_reference_id:=NEW.id;
    elsif NEW.status in ('FAILED','CANCELLED','EXPIRED') and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_INTENT_'||NEW.status;
      v_subject:='IMBOP payment request '||lower(NEW.status);
      v_body:='Your IMBOP payment request for KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00')||
        ' is now '||lower(NEW.status)||'. No payment confirmation or receipt is implied by this notice.';
      v_reference_type:='billing_payment_intent'; v_reference_id:=NEW.id;
    end if;
  elsif TG_TABLE_NAME='billing_payments' then
    if NEW.status='CONFIRMED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_CONFIRMED';
      v_subject:='IMBOP payment confirmed — KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00');
      v_body:='IMBOP has validated and recorded a payment of KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00')||
        ' through '||upper(NEW.payment_method)||'. A receipt is issued separately from the confirmed ledger state.';
      v_reference_type:='billing_payment'; v_reference_id:=NEW.id;
    elsif NEW.status='FAILED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_FAILED';
      v_subject:='IMBOP payment failed';
      v_body:='An IMBOP payment attempt has been recorded as failed. Please review the payment status in your billing space before trying again.';
      v_reference_type:='billing_payment'; v_reference_id:=NEW.id;
    elsif NEW.status='REFUNDED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_REFUNDED';
      v_subject:='IMBOP payment refunded';
      v_body:='An IMBOP payment has been recorded as refunded. Review the refund details and affected invoice in your billing space.';
      v_reference_type:='billing_payment'; v_reference_id:=NEW.id;
    end if;
  elsif TG_TABLE_NAME='billing_receipts' and TG_OP='INSERT' then
    v_event:='PAYMENT_RECEIPT_ISSUED';
    v_subject:='IMBOP receipt issued — '||NEW.receipt_number;
    v_body:='IMBOP has issued receipt '||NEW.receipt_number||' for KES '||
      to_char(NEW.amount_kes,'FM999,999,999,990.00')||'. This receipt follows a confirmed payment recorded by IMBOP.';
    v_reference_type:='billing_receipt'; v_reference_id:=NEW.id;
  elsif TG_TABLE_NAME='billing_payment_refunds' then
    if NEW.status='REQUESTED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_REFUND_REQUESTED';
      v_subject:='IMBOP refund requested';
      v_body:='A refund request for KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00')||
        ' has been recorded for your IMBOP payment. It is not yet a confirmed refund.';
      v_reference_type:='billing_payment_refund'; v_reference_id:=NEW.id;
    elsif NEW.status='CONFIRMED' and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_REFUND_CONFIRMED';
      v_subject:='IMBOP refund confirmed';
      v_body:='A refund of KES '||to_char(NEW.amount_kes,'FM999,999,999,990.00')||
        ' has been confirmed for your IMBOP payment.';
      v_reference_type:='billing_payment_refund'; v_reference_id:=NEW.id;
    elsif NEW.status in ('FAILED','CANCELLED') and (TG_OP='INSERT' or OLD.status is distinct from NEW.status) then
      v_event:='PAYMENT_REFUND_'||NEW.status;
      v_subject:='IMBOP refund '||lower(NEW.status);
      v_body:='Your IMBOP refund request is now '||lower(NEW.status)||'. Please review the refund details in your billing space.';
      v_reference_type:='billing_payment_refund'; v_reference_id:=NEW.id;
    end if;
  elsif TG_TABLE_NAME='billing_bank_statement_entries' and NEW.reconciliation_status='EXCEPTION'
      and (TG_OP='INSERT' or OLD.reconciliation_status is distinct from NEW.reconciliation_status) then
    v_event:='BANK_RECONCILIATION_EXCEPTION';
    v_subject:='IMBOP bank reconciliation exception';
    v_body:='A bank statement entry could not be automatically reconciled with an IMBOP payment. Please review the billing reconciliation details.';
    v_reference_type:='bank_statement_entry'; v_reference_id:=NEW.id;
  end if;

  if v_event is null then return NEW; end if;

  for r in
    select u.id user_id,u.email
      from public.memberships m
      join public.membership_roles mr on mr.membership_id=m.id
      join auth.users u on u.id=m.user_id
     where m.institution_id=v_institution_id
       and m.status='active'
       and mr.role_code in ('institution_admin','institution_owner')
       and u.email is not null
     order by u.email
  loop
    v_key:='billing:'||v_reference_type||':'||v_reference_id::text||':'||v_event||':'||r.user_id::text;
    perform private.create_email_communication(
      v_institution_id,r.user_id,r.email,r.email,null,'SYSTEM','BILLING',v_event,
      v_subject,v_body,v_reference_type,v_reference_id,
      jsonb_build_object(
        'idempotency_key',v_key,
        'template_key',lower(v_event),
        'template_version','1'
      )
    );
  end loop;

  return NEW;
end;
$function$;

drop trigger if exists billing_invoice_communication on public.billing_invoices;
create trigger billing_invoice_communication
after insert or update of status on public.billing_invoices
for each row execute function private.queue_billing_communication();

drop trigger if exists billing_payment_intent_communication on public.billing_payment_intents;
create trigger billing_payment_intent_communication
after insert or update of status on public.billing_payment_intents
for each row execute function private.queue_billing_communication();

drop trigger if exists billing_payment_communication on public.billing_payments;
create trigger billing_payment_communication
after insert or update of status on public.billing_payments
for each row execute function private.queue_billing_communication();

drop trigger if exists billing_receipt_communication on public.billing_receipts;
create trigger billing_receipt_communication
after insert on public.billing_receipts
for each row execute function private.queue_billing_communication();

drop trigger if exists billing_refund_communication on public.billing_payment_refunds;
create trigger billing_refund_communication
after insert or update of status on public.billing_payment_refunds
for each row execute function private.queue_billing_communication();

drop trigger if exists billing_bank_reconciliation_communication on public.billing_bank_statement_entries;
create trigger billing_bank_reconciliation_communication
after insert or update of reconciliation_status on public.billing_bank_statement_entries
for each row execute function private.queue_billing_communication();

revoke execute on function private.queue_billing_communication() from public,anon,authenticated;
