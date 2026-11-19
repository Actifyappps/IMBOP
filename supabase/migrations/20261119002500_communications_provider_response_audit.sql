-- Preserve the provider response on every delivery outcome.
-- provider_message_id remains indexed/available as a first-class delivery field.

create or replace function public.record_platform_email_delivery_result(
  p_delivery_id uuid,
  p_status text,
  p_provider_message_id text default null,
  p_failure_reason text default null,
  p_provider_response jsonb default '{}'::jsonb
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
         retry_count=case when v_status='FAILED' then retry_count+1 else retry_count end,
         provider_message_id=coalesce(nullif(p_provider_message_id,''),provider_message_id),
         provider_response=coalesce(p_provider_response,'{}'::jsonb)
   where id=p_delivery_id and channel='EMAIL';

  get diagnostics v_updated=row_count;

  if v_updated=0 then raise exception 'EMAIL_DELIVERY_NOT_FOUND'; end if;

  return jsonb_build_object(
    'ok',true,
    'status',v_status,
    'updated',v_updated,
    'delivery_id',p_delivery_id
  );
end;
$function$;

revoke all on function public.record_platform_email_delivery_result(uuid,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.record_platform_email_delivery_result(uuid,text,text,text,jsonb) to service_role,authenticated;
