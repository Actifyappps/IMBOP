-- IMBOP Communications Maturity — Batch 3
-- Institution activation + lifecycle communication hardening.
--
-- BUSINESS STATE CHANGE -> COMMUNICATION RECORD -> CHANNEL DELIVERY
-- Institution status remains authoritative; communications report it.

create or replace function private.queue_institution_activation_communications()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  m record;
  v_idempotency_key text;
  v_subject text := 'Your IMBOP Institution space is now active';
  v_body text := 'Your Institution has been activated on IMBOP. Your IMBOP Institution space is now ready for you to sign in, configure your Institution presence, and manage your authorised Members, profiles, businesses, offers, needs and opportunities.';
begin
  if upper(coalesce(new.status,'')) <> 'ACTIVE'
     or upper(coalesce(old.status,'')) = 'ACTIVE' then
    return new;
  end if;

  for m in
    select distinct
      mb.user_id,
      u.email,
      coalesce(nullif(trim(up.first_name || ' ' || up.last_name),''), u.email) as recipient_name
    from public.memberships mb
    join public.membership_roles mr on mr.membership_id=mb.id
    join public.auth_users_placeholder au on false
    join auth.users u on u.id=mb.user_id
    left join public.user_profiles up on up.user_id=mb.user_id
    where mb.institution_id=new.id
      and mb.status='active'
      and mr.role_code in ('institution_admin','institution_owner')
      and nullif(trim(coalesce(u.email,'')),'') is not null
  loop
    v_idempotency_key := 'institution:' || new.id::text || ':ACTIVATED:' || m.user_id::text;

    perform private.create_in_app_communication(
      new.id,
      m.user_id,
      m.email,
      m.recipient_name,
      null,
      'SYSTEM',
      'INSTITUTION_LIFECYCLE',
      'INSTITUTION_ACTIVATED',
      v_subject,
      v_body,
      'institution',
      new.id,
      jsonb_build_object(
        'institution_id',new.id,
        'institution_slug',new.slug,
        'status','ACTIVE',
        'idempotency_key',v_idempotency_key,
        'template_key','institution_activated',
        'template_version','1'
      )
    );

    perform private.create_email_communication(
      new.id,
      m.user_id,
      m.email,
      m.recipient_name,
      null,
      'SYSTEM',
      'INSTITUTION_LIFECYCLE',
      'INSTITUTION_ACTIVATED',
      v_subject,
      v_body,
      'institution',
      new.id,
      jsonb_build_object(
        'institution_id',new.id,
        'institution_slug',new.slug,
        'status','ACTIVE',
        'idempotency_key',v_idempotency_key,
        'template_key','institution_activated',
        'template_version','1'
      )
    );
  end loop;

  return new;
end;
$function$;

drop trigger if exists institutions_activation_communications on public.institutions;
create trigger institutions_activation_communications
after update of status on public.institutions
for each row
execute function private.queue_institution_activation_communications();

revoke execute on function private.queue_institution_activation_communications() from public, anon, authenticated;

-- Make institution application lifecycle emails durable/idempotent under Batch 1.
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
  v_idempotency_key text;
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
    if a.status not in ('SUBMITTED','PENDING_REVIEW','RETURNED') then
      raise exception 'INVALID_APPLICATION_STATE';
    end if;

    v_slug := regexp_replace(lower(coalesce(a.institution_name,'institution')), '[^a-z0-9]+', '-', 'g');
    v_slug := trim(both '-' from v_slug);
    if v_slug='' then v_slug:='institution'; end if;
    if exists(select 1 from public.institutions where slug=v_slug and deleted_at is null) then
      v_slug := v_slug || '-' || substr(replace(gen_random_uuid()::text,'-',''),1,8);
    end if;

    insert into public.institutions(name,legal_name,slug,institution_type,description,status)
    values(a.institution_name,a.legal_name,v_slug,a.institution_type,a.description,'pending')
    returning id into v_institution_id;

    insert into public.institution_settings(institution_id)
    values(v_institution_id)
    on conflict (institution_id) do nothing;

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

    insert into public.institution_application_review_events(
      institution_application_id,action,actor_user_id,notes
    )
    values(p_application_id,'APPROVE',v_user,p_notes);

    v_idempotency_key := 'institution_application:' || p_application_id::text || ':APPROVED';

    perform private.create_email_communication(
      v_institution_id,null,a.contact_email,a.contact_name,v_user,'SYSTEM',
      'INSTITUTION_APPLICATION','INSTITUTION_APPLICATION_APPROVED',
      'Your IMBOP Institution application has been approved',
      'Congratulations. Your Institution application to IMBOP has been approved. Your Institution is now being prepared for onboarding. You will receive further instructions as your IMBOP space is made ready.',
      'institution_application',p_application_id,
      jsonb_build_object(
        'institution_id',v_institution_id,
        'status','APPROVED',
        'idempotency_key',v_idempotency_key,
        'template_key','institution_application_approved',
        'template_version','1'
      )
    );

    return jsonb_build_object(
      'ok',true,'status','APPROVED','institution_id',v_institution_id,
      'slug',v_slug,'onboarding_status','PENDING'
    );
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

  insert into public.institution_application_review_events(
    institution_application_id,action,actor_user_id,notes
  )
  values(p_application_id,v_event_action,v_user,p_notes);

  if v_action='PENDING_REVIEW' then
    v_subject:='Your IMBOP Institution application is under review';
    v_body:='Your Institution application has moved into SE IMBOP review. We will communicate the next decision or required action to you.';
  elsif v_action='RETURNED' then
    v_subject:='Action required on your IMBOP Institution application';
    v_body:='Your Institution application has been returned for further information or correction.' ||
      case when nullif(trim(coalesce(p_notes,'')),'') is not null
        then ' Review notes: '||trim(p_notes) else '' end;
  elsif v_action='REJECTED' then
    v_subject:='Decision on your IMBOP Institution application';
    v_body:='Your Institution application has been rejected.' ||
      case when nullif(trim(coalesce(p_notes,'')),'') is not null
        then ' Reason: '||trim(p_notes) else '' end;
  else
    v_subject:='Update on your IMBOP Institution application';
    v_body:='There has been an update to your Institution application.';
  end if;

  v_idempotency_key := 'institution_application:' || p_application_id::text || ':' || v_action;

  perform private.create_email_communication(
    a.institution_id,null,a.contact_email,a.contact_name,v_user,'SYSTEM',
    'INSTITUTION_APPLICATION','INSTITUTION_APPLICATION_'||v_action,
    v_subject,v_body,'institution_application',p_application_id,
    jsonb_build_object(
      'status',v_action,
      'review_notes',p_notes,
      'idempotency_key',v_idempotency_key,
      'template_key','institution_application_'||lower(v_action),
      'template_version','1'
    )
  );

  return jsonb_build_object('ok',true,'status',v_action);
end;
$function$;
