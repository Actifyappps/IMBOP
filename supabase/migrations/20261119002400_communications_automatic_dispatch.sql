-- Automatic IMBOP email queue dispatch.
-- The scheduler wakes the existing transactional outbox worker every minute.
-- Secrets are stored in Supabase Vault, never in this migration.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault with schema vault;

create or replace function public.get_platform_email_queue(
  p_status text default 'QUEUED',
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  communication_id uuid,
  delivery_id uuid,
  institution_id uuid,
  recipient_user_id uuid,
  recipient_email text,
  recipient_name text,
  communication_type text,
  event_type text,
  subject text,
  body text,
  delivery_status text,
  retry_count integer,
  failure_reason text,
  created_at timestamptz,
  attempted_at timestamptz,
  delivered_at timestamptz
)
language sql
set search_path = public
as $function$
  select
    c.id,
    d.id,
    c.institution_id,
    c.recipient_user_id,
    c.recipient_email,
    c.recipient_name,
    c.communication_type,
    c.event_type,
    c.subject,
    c.body,
    d.status,
    d.retry_count,
    d.failure_reason,
    c.created_at,
    d.attempted_at,
    d.delivered_at
  from public.communication_records c
  join public.communication_deliveries d on d.communication_id=c.id
  where d.channel='EMAIL'
    and d.status=upper(coalesce(p_status,'QUEUED'))
    and (
      current_user = 'service_role'
      or private.has_platform_permission('institution_manage')
    )
  order by c.created_at asc
  limit greatest(1,least(coalesce(p_limit,50),200))
  offset greatest(0,coalesce(p_offset,0));
$function$;

create or replace function public.claim_platform_email_delivery(p_delivery_id uuid)
returns table(
  delivery_id uuid,
  communication_id uuid,
  recipient_email text,
  recipient_name text,
  subject text,
  body text,
  retry_count integer
)
language plpgsql
set search_path = ''
as $function$
declare
  d public.communication_deliveries%rowtype;
  c public.communication_records%rowtype;
  v_now timestamptz := now();
  v_backoff integer;
begin
  if not (
    current_user = 'service_role'
    or (
      auth.uid() is not null
      and private.has_platform_permission('institution_manage')
    )
  ) then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_delivery_id::text, 0));

  select * into d
    from public.communication_deliveries
   where id=p_delivery_id and channel='EMAIL'
   for update;

  if not found then raise exception 'EMAIL_DELIVERY_NOT_FOUND'; end if;

  if d.status='DELIVERED' then return; end if;
  if d.status='FAILED' and d.retry_count >= 5 then raise exception 'EMAIL_RETRY_LIMIT_REACHED'; end if;

  v_backoff := case
    when d.retry_count <= 0 then 0
    when d.retry_count = 1 then 60
    when d.retry_count = 2 then 300
    when d.retry_count = 3 then 900
    else 1800
  end;

  if d.attempted_at is not null and d.attempted_at > v_now - make_interval(secs=>v_backoff) then
    return;
  end if;

  select * into c from public.communication_records where id=d.communication_id;
  if not found then raise exception 'COMMUNICATION_NOT_FOUND'; end if;

  update public.communication_deliveries
     set status='QUEUED', attempted_at=v_now, failure_reason=null
   where id=d.id;

  return query
  select d.id,c.id,c.recipient_email,c.recipient_name,c.subject,c.body,d.retry_count;
end;
$function$;

create or replace function public.record_platform_email_delivery_result(
  p_delivery_id uuid,
  p_status text,
  p_provider_message_id text default null,
  p_failure_reason text default null
)
returns jsonb
language plpgsql
set search_path = ''
as $function$
declare
  v_status text := upper(trim(coalesce(p_status,'')));
  v_updated integer;
begin
  if not (
    current_user = 'service_role'
    or (
      auth.uid() is not null
      and private.has_platform_permission('institution_manage')
    )
  ) then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  if v_status not in ('DELIVERED','FAILED') then
    raise exception 'INVALID_EMAIL_DELIVERY_STATUS';
  end if;

  update public.communication_deliveries
     set status=v_status,
         delivered_at=case when v_status='DELIVERED' then now() else delivered_at end,
         failure_reason=case when v_status='FAILED' then p_failure_reason else null end,
         retry_count=case when v_status='FAILED' then retry_count+1 else retry_count end
   where id=p_delivery_id and channel='EMAIL';

  get diagnostics v_updated=row_count;

  if v_updated=0 then raise exception 'EMAIL_DELIVERY_NOT_FOUND'; end if;

  update public.communication_records
     set metadata = coalesce(metadata,'{}'::jsonb) ||
       jsonb_build_object('email_provider_message_id',nullif(p_provider_message_id,''))
   where id=(select communication_id from public.communication_deliveries where id=p_delivery_id);

  return jsonb_build_object('ok',true,'status',v_status,'updated',v_updated);
end;
$function$;

create or replace function public.verify_imbop_email_dispatch_secret(p_secret text)
returns boolean
language sql
security definer
set search_path = ''
stable
as $function$
  select exists (
    select 1
      from vault.decrypted_secrets
     where name = 'imbop_email_dispatch_secret'
       and decrypted_secret = p_secret
  );
$function$;

revoke all on function public.verify_imbop_email_dispatch_secret(text) from public, anon, authenticated;
grant execute on function public.verify_imbop_email_dispatch_secret(text) to service_role;

select cron.schedule(
  'imbop-email-dispatcher-every-minute',
  '* * * * *',
  $job$
    select net.http_post(
      url := 'https://jvzbrdcudzwbjmwlpzfe.supabase.co/functions/v1/imbop-email-dispatcher-worker',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'imbop_dispatch_publishable_key'),
        'x-imbop-dispatch-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'imbop_email_dispatch_secret')
      ),
      body := jsonb_build_object('source', 'supabase-cron', 'scheduled_at', now()),
      timeout_milliseconds := 5000
    ) as request_id;
  $job$
);
