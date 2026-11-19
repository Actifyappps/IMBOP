-- IMBOP Communications: align delivery dashboard with authoritative delivery fields.
-- Remove the obsolete 4-argument delivery-result overload so there is one canonical write contract.
-- Keep provider response visible to authorized platform operations for troubleshooting.

drop function if exists public.record_platform_email_delivery_result(uuid,text,text,text);
drop function if exists public.get_platform_email_delivery_dashboard(integer,integer);

create function public.get_platform_email_delivery_dashboard(
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
  provider_response jsonb,
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
    c.id,
    d.id,
    c.institution_id,
    i.name,
    c.recipient_email,
    c.recipient_name,
    c.communication_type,
    c.event_type,
    c.subject,
    d.status,
    d.retry_count,
    d.failure_reason,
    c.created_at,
    d.attempted_at,
    d.delivered_at,
    d.provider_message_id,
    d.provider_response,
    case
      when d.status='DELIVERED' then 'DELIVERED'
      when d.status='FAILED' and d.retry_count<5 then 'RETRYABLE'
      when d.status='FAILED' then 'RETRY_LIMIT'
      when d.status='QUEUED'
        and d.attempted_at is not null
        and d.attempted_at<now()-interval '15 minutes' then 'STUCK'
      when d.status='QUEUED' then 'QUEUED'
      else d.status
    end
  from public.communication_deliveries d
  join public.communication_records c on c.id=d.communication_id
  left join public.institutions i on i.id=c.institution_id
  where d.channel='EMAIL'
  order by
    case
      when d.status='FAILED' and d.retry_count<5 then 1
      when d.status='QUEUED'
        and d.attempted_at is not null
        and d.attempted_at<now()-interval '15 minutes' then 2
      when d.status='QUEUED' then 3
      else 4
    end,
    c.created_at asc
  limit greatest(1,least(coalesce(p_limit,100),200))
  offset greatest(0,coalesce(p_offset,0));
end;
$function$;

revoke all on function public.record_platform_email_delivery_result(uuid,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.record_platform_email_delivery_result(uuid,text,text,text,jsonb) to service_role;

revoke all on function public.get_platform_email_delivery_dashboard(integer,integer) from public,anon;
grant execute on function public.get_platform_email_delivery_dashboard(integer,integer) to authenticated;
