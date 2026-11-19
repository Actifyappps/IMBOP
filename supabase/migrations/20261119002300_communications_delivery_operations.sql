-- IMBOP Communications: delivery operations queue and safe retry
-- Adds controlled SE Admin visibility for email delivery state and retryable failures.

create or replace function public.get_platform_email_delivery_dashboard(
  p_limit integer default 100,
  p_offset integer default 0
)
returns table(
  communication_id uuid,
  delivery_id uuid,
  institution_id uuid,
  institution_name text,
  recipient_email text,
  recipient_name text,
  communication_type text,
  event_type text,
  subject text,
  delivery_status text,
  retry_count integer,
  failure_reason text,
  created_at timestamptz,
  attempted_at timestamptz,
  delivered_at timestamptz,
  provider_message_id text,
  operational_state text
)
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if auth.uid() is null or not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  return query
  select
    c.id,d.id,c.institution_id,i.name,c.recipient_email,c.recipient_name,
    c.communication_type,c.event_type,c.subject,d.status,d.retry_count,
    d.failure_reason,c.created_at,d.attempted_at,d.delivered_at,
    c.metadata->>'email_provider_message_id',
    case
      when d.status='DELIVERED' then 'DELIVERED'
      when d.status='FAILED' and d.retry_count < 5 then 'RETRYABLE'
      when d.status='FAILED' then 'RETRY_LIMIT'
      when d.status='QUEUED' and d.attempted_at is not null
        and d.attempted_at < now() - interval '15 minutes' then 'STUCK'
      when d.status='QUEUED' then 'QUEUED'
      else d.status
    end
  from public.communication_deliveries d
  join public.communication_records c on c.id=d.communication_id
  left join public.institutions i on i.id=c.institution_id
  where d.channel='EMAIL'
  order by
    case
      when d.status='FAILED' and d.retry_count < 5 then 1
      when d.status='QUEUED' and d.attempted_at is not null
        and d.attempted_at < now() - interval '15 minutes' then 2
      when d.status='QUEUED' then 3
      else 4
    end,
    c.created_at asc
  limit greatest(1,least(coalesce(p_limit,100),200))
  offset greatest(0,coalesce(p_offset,0));
end;
$function$;

revoke execute on function public.get_platform_email_delivery_dashboard(integer,integer) from public,anon;
grant execute on function public.get_platform_email_delivery_dashboard(integer,integer) to authenticated;

create or replace function public.retry_platform_email_delivery(p_delivery_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare d public.communication_deliveries%rowtype; v_updated integer;
begin
  if auth.uid() is null or not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  select * into d
  from public.communication_deliveries
  where id=p_delivery_id and channel='EMAIL'
  for update;

  if not found then raise exception 'EMAIL_DELIVERY_NOT_FOUND'; end if;
  if d.status='DELIVERED' then
    return jsonb_build_object('ok',true,'status','ALREADY_DELIVERED');
  end if;
  if d.retry_count >= 5 then
    return jsonb_build_object('ok',false,'status','RETRY_LIMIT_REACHED');
  end if;
  if d.status not in ('FAILED','QUEUED') then
    return jsonb_build_object('ok',false,'status','NOT_RETRYABLE','delivery_status',d.status);
  end if;

  update public.communication_deliveries
     set status='QUEUED',attempted_at=null,delivered_at=null,failure_reason=null
   where id=p_delivery_id;

  get diagnostics v_updated=row_count;
  return jsonb_build_object('ok',v_updated=1,'status','QUEUED_FOR_RETRY','delivery_id',p_delivery_id);
end;
$function$;

revoke execute on function public.retry_platform_email_delivery(uuid) from public,anon;
grant execute on function public.retry_platform_email_delivery(uuid) to authenticated;
