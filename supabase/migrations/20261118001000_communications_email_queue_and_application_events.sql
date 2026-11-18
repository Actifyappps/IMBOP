-- IMBOP Communications: provider-neutral email queue + institution application lifecycle events
-- Applied to production during implementation; retained here as the repository migration record.

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
begin
  if nullif(trim(coalesce(p_recipient_email,'')),'') is null then
    return null;
  end if;

  insert into public.communication_records(
    institution_id, recipient_user_id, recipient_email, recipient_name,
    sender_user_id, origin, communication_type, event_type,
    subject, body, reference_type, reference_id, metadata
  )
  values(
    p_institution_id, p_recipient_user_id, lower(trim(p_recipient_email)), p_recipient_name,
    p_sender_user_id, upper(coalesce(p_origin,'SYSTEM')),
    p_communication_type, p_event_type, p_subject, p_body,
    p_reference_type, p_reference_id, coalesce(p_metadata,'{}'::jsonb)
  )
  returning id into v_communication_id;

  insert into public.communication_deliveries(communication_id,channel,status)
  values(v_communication_id,'EMAIL','QUEUED');

  return v_communication_id;
end;
$function$;

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
security invoker
set search_path to 'public'
as $function$
  select c.id,d.id,c.institution_id,c.recipient_user_id,c.recipient_email,c.recipient_name,
         c.communication_type,c.event_type,c.subject,c.body,d.status,d.retry_count,
         d.failure_reason,c.created_at,d.attempted_at,d.delivered_at
    from public.communication_records c
    join public.communication_deliveries d on d.communication_id=c.id
   where d.channel='EMAIL'
     and d.status=upper(coalesce(p_status,'QUEUED'))
     and private.has_platform_permission('institution_manage')
   order by c.created_at asc
   limit greatest(1,least(coalesce(p_limit,50),200))
   offset greatest(0,coalesce(p_offset,0));
$function$;

revoke execute on function public.get_platform_email_queue(text,integer,integer) from anon, authenticated;
grant execute on function public.get_platform_email_queue(text,integer,integer) to authenticated;

create or replace function private.record_email_delivery_result(
  p_delivery_id uuid,
  p_status text,
  p_failure_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_status text := upper(trim(coalesce(p_status,'')));
  v_updated integer;
begin
  if v_status not in ('DELIVERED','FAILED') then
    raise exception 'INVALID_EMAIL_DELIVERY_STATUS';
  end if;

  update public.communication_deliveries
     set status=v_status,
         attempted_at=coalesce(attempted_at,now()),
         delivered_at=case when v_status='DELIVERED' then now() else delivered_at end,
         failure_reason=case when v_status='FAILED' then p_failure_reason else null end,
         retry_count=case when v_status='FAILED' then retry_count+1 else retry_count end
   where id=p_delivery_id and channel='EMAIL';

  get diagnostics v_updated=row_count;
  return jsonb_build_object('ok',v_updated=1,'updated',v_updated,'status',v_status);
end;
$function$;

-- Replace the existing implementation with lifecycle email events.
create or replace function private.review_institution_application_impl(
  p_application_id uuid,
  p_action text,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  a public.institution_applications%rowtype;
  v_institution_id uuid;
  v_slug text;
  v_user uuid := auth.uid();
  v_action text := upper(trim(coalesce(p_action,'')));
  v_event_action text;
  v_subject text;
  v_body text;
begin
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  select * into a from public.institution_applications where id=p_application_id for update;
  if not found then raise exception 'APPLICATION_NOT_FOUND'; end if;
  if v_action='APPROVE' then v_action:='APPROVED'; end if;
  if v_action not in ('PENDING_REVIEW','RETURNED','APPROVED','REJECTED','REMOVED') then
    raise exception 'INVALID_APPLICATION_ACTION';
  end if;

  if v_action='APPROVED' then
    if a.status not in ('SUBMITTED','PENDING_REVIEW','RETURNED') then raise exception 'INVALID_APPLICATION_STATE'; end if;

    v_slug := regexp_replace(lower(coalesce(a.institution_name,'institution')), '[^a-z0-9]+', '-', 'g');
    v_slug := trim(both '-' from v_slug);
    if v_slug='' then v_slug:='institution'; end if;
    if exists(select 1 from public.institutions where slug=v_slug and deleted_at is null) then
      v_slug := v_slug || '-' || substr(replace(gen_random_uuid()::text,'-',''),1,8);
    end if;

    insert into public.institutions(name,legal_name,slug,institution_type,description,status)
    values(a.institution_name,a.legal_name,v_slug,a.institution_type,a.description,'pending')
    returning id into v_institution_id;

    insert into public.institution_settings(institution_id) values(v_institution_id) on conflict (institution_id) do nothing;

    insert into public.institution_billing_accounts(
      institution_id,plan_code,member_limit,monthly_fee_kes,billing_status,
      compliance_status,notes,updated_by_user_id
    ) values(
      v_institution_id,'FOUNDING_PILOT',50,0,'PILOT_WAIVED','COMPLIANT',
      'Founding Institution Programme: up to 50 members at KES 0 pilot fee.',v_user
    );

    update public.institution_applications
       set status='APPROVED',institution_id=v_institution_id,reviewed_at=now(),
           reviewed_by_user_id=v_user,review_notes=p_notes,updated_at=now()
     where id=p_application_id;

    insert into public.institution_application_review_events(institution_application_id,action,actor_user_id,notes)
    values(p_application_id,'APPROVE',v_user,p_notes);

    perform private.create_email_communication(
      v_institution_id,null,a.contact_email,a.contact_name,v_user,'SYSTEM',
      'INSTITUTION_APPLICATION','INSTITUTION_APPLICATION_APPROVED',
      'Your IMBOP Institution application has been approved',
      'Congratulations. Your Institution application to IMBOP has been approved. Your Institution is now being prepared for onboarding. You will receive further instructions as your IMBOP space is made ready.',
      'institution_application',p_application_id,
      jsonb_build_object('institution_id',v_institution_id,'status','APPROVED')
    );

    return jsonb_build_object('ok',true,'status','APPROVED','institution_id',v_institution_id,'slug',v_slug,'onboarding_status','PENDING');
  end if;

  v_event_action := case v_action
    when 'RETURNED' then 'RETURN'
    when 'REJECTED' then 'REJECT'
    when 'REMOVED' then 'REMOVE'
    when 'PENDING_REVIEW' then 'REVIEW'
  end;

  update public.institution_applications
     set status=v_action,reviewed_at=now(),reviewed_by_user_id=v_user,
         review_notes=p_notes,updated_at=now()
   where id=p_application_id;

  insert into public.institution_application_review_events(institution_application_id,action,actor_user_id,notes)
  values(p_application_id,v_event_action,v_user,p_notes);

  if v_action='PENDING_REVIEW' then
    v_subject:='Your IMBOP Institution application is under review';
    v_body:='Your Institution application has moved into SE IMBOP review. We will communicate the next decision or required action to you.';
  elsif v_action='RETURNED' then
    v_subject:='Action required on your IMBOP Institution application';
    v_body:='Your Institution application has been returned for further information or correction.' ||
      case when nullif(trim(coalesce(p_notes,'')),'') is not null then ' Review notes: '||trim(p_notes) else '' end;
  elsif v_action='REJECTED' then
    v_subject:='Decision on your IMBOP Institution application';
    v_body:='Your Institution application has been rejected.' ||
      case when nullif(trim(coalesce(p_notes,'')),'') is not null then ' Reason: '||trim(p_notes) else '' end;
  else
    v_subject:='Update on your IMBOP Institution application';
    v_body:='There has been an update to your Institution application.';
  end if;

  perform private.create_email_communication(
    a.institution_id,null,a.contact_email,a.contact_name,v_user,'SYSTEM',
    'INSTITUTION_APPLICATION','INSTITUTION_APPLICATION_'||v_action,
    v_subject,v_body,'institution_application',p_application_id,
    jsonb_build_object('status',v_action,'review_notes',p_notes)
  );

  return jsonb_build_object('ok',true,'status',v_action);
end;
$function$;
