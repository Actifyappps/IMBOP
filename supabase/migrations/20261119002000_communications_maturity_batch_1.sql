-- IMBOP Communications Maturity — Batch 1
-- Durable outbox hardening + complete member application lifecycle notifications.
--
-- Pattern:
-- BUSINESS STATE CHANGE -> COMMUNICATION RECORD -> CHANNEL DELIVERY
-- The business transaction remains authoritative; communications report it.

alter table public.communication_records
  add column if not exists idempotency_key text,
  add column if not exists template_key text,
  add column if not exists template_version text;

alter table public.communication_deliveries
  add column if not exists provider_message_id text,
  add column if not exists provider_response jsonb not null default '{}'::jsonb;

-- Seed deterministic keys for the existing acknowledgement records before
-- creating the unique constraint. If duplicate legacy rows exist, preserve the
-- oldest record as the authoritative event and leave later duplicates unkeyed.
with ranked as (
  select id,
         row_number() over (
           partition by reference_type, reference_id, event_type
           order by created_at asc, id asc
         ) as rn
    from public.communication_records
   where event_type in ('INSTITUTION_APPLICATION_RECEIVED','MEMBER_APPLICATION_RECEIVED')
     and reference_id is not null
)
update public.communication_records c
   set idempotency_key=case
     when r.rn=1 then c.reference_type || ':' || c.reference_id::text || ':RECEIVED'
     else null
   end
  from ranked r
 where c.id=r.id
   and c.idempotency_key is null;

create unique index if not exists communication_records_idempotency_uidx
  on public.communication_records(idempotency_key)
  where idempotency_key is not null;

create index if not exists communication_deliveries_provider_message_idx
  on public.communication_deliveries(provider_message_id)
  where provider_message_id is not null;

-- The metadata contract now supports safe, explicit idempotency and template
-- versioning without breaking the existing function signature.
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

    if v_communication_id is not null then
      return v_communication_id;
    end if;
  end if;

  insert into public.communication_records(
    institution_id, recipient_user_id, recipient_email, recipient_name,
    sender_user_id, origin, communication_type, event_type,
    subject, body, reference_type, reference_id, metadata,
    idempotency_key, template_key, template_version
  )
  values(
    p_institution_id, p_recipient_user_id, lower(trim(p_recipient_email)), p_recipient_name,
    p_sender_user_id, upper(coalesce(p_origin,'SYSTEM')),
    p_communication_type, p_event_type, p_subject, p_body,
    p_reference_type, p_reference_id, coalesce(p_metadata,'{}'::jsonb),
    v_idempotency_key, v_template_key, v_template_version
  )
  on conflict (idempotency_key) where idempotency_key is not null
  do nothing
  returning id into v_communication_id;

  if v_communication_id is null and v_idempotency_key is not null then
    select id into v_communication_id
      from public.communication_records
     where idempotency_key=v_idempotency_key
     limit 1;
  end if;

  insert into public.communication_deliveries(communication_id,channel,status)
  values(v_communication_id,'EMAIL','QUEUED')
  on conflict (communication_id,channel) do nothing;

  return v_communication_id;
end;
$function$;

-- Complete the member application communication lifecycle.
-- PUBLISH already had an in-app notice; this adds the durable email record.
-- RETURN and REJECT now notify the applicant with actionable notes.
create or replace function private.review_member_application_impl(
  p_application_id uuid,
  p_action text,
  p_notes text default null
)
returns public.member_applications
language plpgsql
security definer
set search_path to ''
as $function$
declare
  r public.member_applications;
  old_status text;
  new_status text;
  published_business_id uuid;
  business_owner_user_id uuid;
  v_business_name text;
  v_idempotency_key text;
  v_subject text;
  v_body text;
begin
  select * into r
    from public.member_applications
   where id=p_application_id
   for update;

  if not found then
    raise exception 'Application not found';
  end if;

  old_status:=r.status;

  if not private.has_institution_permission(r.institution_id,'publication_manage') then
    raise exception 'Not authorized';
  end if;

  p_action:=upper(trim(p_action));

  if p_action='PUBLISH' then
    if r.status<>'PENDING_REVIEW' then
      raise exception 'PUBLISH requires PENDING_REVIEW';
    end if;
    new_status:='PUBLISHED';
  elsif p_action='RETURN' then
    if r.status<>'PENDING_REVIEW' then
      raise exception 'RETURN requires PENDING_REVIEW';
    end if;
    new_status:='RETURNED';
  elsif p_action='REJECT' then
    if r.status not in ('SUBMITTED','PENDING_REVIEW','RETURNED') then
      raise exception 'REJECT not allowed from current status';
    end if;
    new_status:='REJECTED';
  elsif p_action='REMOVE' then
    if r.status not in ('PUBLISHED','REJECTED','RETURNED') then
      raise exception 'REMOVE not allowed from current status';
    end if;
    new_status:='REMOVED';
  else
    raise exception 'Unsupported review action';
  end if;

  if p_action='REMOVE' then
    select mp.published_business_id into published_business_id
      from public.member_application_publications mp
     where mp.application_id=p_application_id
     for update;
  end if;

  update public.member_applications
     set status=new_status,
         reviewed_at=now(),
         reviewed_by_user_id=auth.uid(),
         review_notes=p_notes,
         updated_at=now()
   where id=p_application_id
   returning * into r;

  v_idempotency_key := 'member_application:' || p_application_id::text || ':' || p_action;

  if p_action='PUBLISH' then
    perform private.activate_member_application_publication(p_application_id);

    select b.id,b.created_by_user_id,b.name
      into published_business_id,business_owner_user_id,v_business_name
      from public.member_application_publications mp
      join public.businesses b on b.id=mp.published_business_id
     where mp.application_id=p_application_id
     limit 1;

    if business_owner_user_id is not null then
      perform private.create_in_app_communication(
        r.institution_id,
        business_owner_user_id,
        r.email,
        r.applicant_name,
        auth.uid(),
        'SYSTEM',
        'MEMBER_APPLICATION',
        'MEMBER_APPLICATION_PUBLISHED',
        'Your IMBOP business profile has been published',
        'Your Institution has published your IMBOP business profile' ||
          case when v_business_name is not null then ': ' || v_business_name else '' end ||
          '. You can now use your IMBOP Space to present your business and opportunities.',
        'member_application',
        p_application_id,
        jsonb_build_object(
          'business_id',published_business_id,
          'status',new_status
        )
      );
    end if;

    v_subject := 'Your IMBOP business profile has been published';
    v_body := 'Your Institution has published your IMBOP business profile' ||
      case when v_business_name is not null then ': ' || v_business_name else '' end ||
      '. You can now use your IMBOP Space to present your business and opportunities.';
  elsif p_action='RETURN' then
    v_subject := 'Action required on your IMBOP member application';
    v_body := 'Your application to join your Institution on IMBOP has been returned for further information or correction.' ||
      case when nullif(trim(coalesce(p_notes,'')),'') is not null
        then ' Review notes: ' || trim(p_notes)
        else ' Please review the application requirements and resubmit the requested information.'
      end;
  elsif p_action='REJECT' then
    v_subject := 'Decision on your IMBOP member application';
    v_body := 'Your application to join your Institution on IMBOP has been rejected.' ||
      case when nullif(trim(coalesce(p_notes,'')),'') is not null
        then ' Reason: ' || trim(p_notes)
        else ''
      end;
  else
    v_subject := null;
    v_body := null;
  end if;

  if v_subject is not null then
    perform private.create_email_communication(
      r.institution_id,
      null,
      r.email,
      r.applicant_name,
      auth.uid(),
      'SYSTEM',
      'MEMBER_APPLICATION',
      'MEMBER_APPLICATION_' || p_action,
      v_subject,
      v_body,
      'member_application',
      p_application_id,
      jsonb_build_object(
        'application_reference',r.application_reference,
        'status',new_status,
        'review_notes',p_notes,
        'idempotency_key',v_idempotency_key,
        'template_key','member_application_' || lower(p_action),
        'template_version','1'
      )
    );
  end if;

  if p_action='REMOVE' and published_business_id is not null then
    perform private.unpublish_published_business(published_business_id,p_notes);
  end if;

  insert into public.application_review_events(
    application_id,institution_id,action,from_status,to_status,actor_user_id,notes
  )
  values(
    p_application_id,r.institution_id,p_action,old_status,new_status,auth.uid(),p_notes
  );

  return r;
end;
$function$;

