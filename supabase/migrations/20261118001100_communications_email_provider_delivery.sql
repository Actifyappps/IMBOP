-- IMBOP Communications: provider delivery claim/result boundary
create or replace function public.claim_platform_email_delivery(p_delivery_id uuid)
returns table(delivery_id uuid,communication_id uuid,recipient_email text,recipient_name text,subject text,body text,retry_count integer)
language plpgsql security definer set search_path to ''
as $function$
declare d public.communication_deliveries%rowtype; c public.communication_records%rowtype; v_now timestamptz:=now(); v_backoff integer;
begin
 if auth.uid() is null or not private.has_platform_permission('institution_manage') then raise exception 'PLATFORM_PERMISSION_REQUIRED'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_delivery_id::text,0));
 select * into d from public.communication_deliveries where id=p_delivery_id and channel='EMAIL' for update;
 if not found then raise exception 'EMAIL_DELIVERY_NOT_FOUND'; end if;
 if d.status='DELIVERED' then return; end if;
 if d.status='FAILED' and d.retry_count>=5 then raise exception 'EMAIL_RETRY_LIMIT_REACHED'; end if;
 v_backoff:=case when d.retry_count<=0 then 0 when d.retry_count=1 then 60 when d.retry_count=2 then 300 when d.retry_count=3 then 900 else 1800 end;
 if d.attempted_at is not null and d.attempted_at>v_now-make_interval(secs=>v_backoff) then return; end if;
 select * into c from public.communication_records where id=d.communication_id;
 if not found then raise exception 'COMMUNICATION_NOT_FOUND'; end if;
 update public.communication_deliveries set status='QUEUED',attempted_at=v_now,failure_reason=null where id=d.id;
 return query select d.id,c.id,c.recipient_email,c.recipient_name,c.subject,c.body,d.retry_count;
end;
$function$;
revoke execute on function public.claim_platform_email_delivery(uuid) from anon;
grant execute on function public.claim_platform_email_delivery(uuid) to authenticated;

create or replace function public.record_platform_email_delivery_result(p_delivery_id uuid,p_status text,p_provider_message_id text default null,p_failure_reason text default null)
returns jsonb language plpgsql security definer set search_path to ''
as $function$
declare v_status text:=upper(trim(coalesce(p_status,''))); v_updated integer;
begin
 if auth.uid() is null or not private.has_platform_permission('institution_manage') then raise exception 'PLATFORM_PERMISSION_REQUIRED'; end if;
 if v_status not in ('DELIVERED','FAILED') then raise exception 'INVALID_EMAIL_DELIVERY_STATUS'; end if;
 update public.communication_deliveries set status=v_status,delivered_at=case when v_status='DELIVERED' then now() else delivered_at end,failure_reason=case when v_status='FAILED' then p_failure_reason else null end,retry_count=case when v_status='FAILED' then retry_count+1 else retry_count end where id=p_delivery_id and channel='EMAIL';
 get diagnostics v_updated=row_count;
 if v_updated=0 then raise exception 'EMAIL_DELIVERY_NOT_FOUND'; end if;
 update public.communication_records set metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('email_provider_message_id',nullif(p_provider_message_id,'')) where id=(select communication_id from public.communication_deliveries where id=p_delivery_id);
 return jsonb_build_object('ok',true,'status',v_status,'updated',v_updated);
end;
$function$;
revoke execute on function public.record_platform_email_delivery_result(uuid,text,text,text) from anon;
grant execute on function public.record_platform_email_delivery_result(uuid,text,text,text) to authenticated;
