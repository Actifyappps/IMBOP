-- IMBOP application acknowledgement and tracking reference
-- Gives each public institution application a durable applicant-facing reference
-- and queues an immediate Application Received email through the existing
-- provider-neutral communications pipeline.

alter table public.institution_applications
  add column if not exists application_reference text;

create unique index if not exists institution_applications_application_reference_uidx
  on public.institution_applications(application_reference)
  where application_reference is not null;

drop function if exists private.create_public_institution_application_impl(text,text,text,integer,text,text,text,text,text,text,text,text,boolean);

create or replace function private.create_public_institution_application_impl(
  p_institution_name text,
  p_brand_name text,
  p_institution_type text,
  p_membership_size integer,
  p_contact_name text,
  p_contact_role text,
  p_contact_email text,
  p_contact_phone text,
  p_website text,
  p_hq_county text,
  p_hq_location text,
  p_description text,
  p_authorised boolean
)
returns table(application_id uuid, application_reference text, status text, logo_upload_token text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  a public.institution_applications;
  v_logo_token text;
  v_reference text;
begin
  if nullif(btrim(p_institution_name),'') is null then raise exception 'Please enter the institution name.'; end if;
  if nullif(btrim(p_institution_type),'') is null then raise exception 'Please select the institution type.'; end if;
  if p_membership_size is null or p_membership_size < 0 then raise exception 'Please enter the current membership estimate.'; end if;
  if nullif(btrim(p_contact_name),'') is null then raise exception 'Please enter a contact name.'; end if;
  if nullif(btrim(p_contact_role),'') is null then raise exception 'Please enter the contact role or position.'; end if;
  if nullif(btrim(p_contact_email),'') is null then raise exception 'Please enter a contact email.'; end if;
  if nullif(btrim(p_contact_phone),'') is null then raise exception 'Please enter a contact phone.'; end if;
  if nullif(btrim(p_hq_county),'') is null then raise exception 'Please enter the HQ county.'; end if;
  if nullif(btrim(p_hq_location),'') is null then raise exception 'Please enter the HQ location.'; end if;
  if nullif(btrim(p_description),'') is null then raise exception 'Please tell us about the institution.'; end if;
  if coalesce(p_authorised,false) is not true then raise exception 'Please confirm that you are authorised to submit this application.'; end if;

  v_logo_token := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
  v_reference := 'IMBOP-APP-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));

  insert into public.institution_applications(
    institution_name, legal_name, brand_name, institution_type, contact_name, contact_role,
    contact_email, contact_phone, membership_size, website, location, county, hq_location,
    description, logo_upload_token, application_reference, application_payload, status, submitted_at
  ) values (
    btrim(p_institution_name), null, nullif(btrim(p_brand_name),''), btrim(p_institution_type),
    btrim(p_contact_name), btrim(p_contact_role), lower(btrim(p_contact_email)), btrim(p_contact_phone),
    p_membership_size, nullif(btrim(p_website),''), btrim(p_hq_location), btrim(p_hq_county),
    btrim(p_hq_location), btrim(p_description), v_logo_token, v_reference,
    jsonb_build_object(
      'source','PUBLIC_IMBOP_APPLICATION',
      'applicant_type','INSTITUTION',
      'authorised_applicant',true,
      'schema_version','2026-11-19'
    ),
    'SUBMITTED', now()
  ) returning * into a;

  update public.institution_applications
     set status='PENDING_REVIEW', updated_at=now()
   where id=a.id
   returning * into a;

  perform private.create_email_communication(
    null,
    null,
    a.contact_email,
    a.contact_name,
    null,
    'SYSTEM',
    'INSTITUTION_APPLICATION',
    'INSTITUTION_APPLICATION_RECEIVED',
    'IMBOP application received — ' || a.application_reference,
    'Thank you. Your Institution application to IMBOP has been received. Application Reference: ' ||
      a.application_reference || '. Status: PENDING REVIEW. SE IMBOP will review your application and communicate the outcome or any required action. Application ≠ Publication.',
    'institution_application',
    a.id,
    jsonb_build_object(
      'application_reference',a.application_reference,
      'status','PENDING_REVIEW',
      'applicant_type','INSTITUTION'
    )
  );

  return query select a.id, a.application_reference, a.status, a.logo_upload_token;
exception
  when check_violation then
    raise exception 'Please check the details you entered and try again.';
end;
$$;

drop function if exists public.create_public_institution_application(text,text,text,integer,text,text,text,text,text,text,text,text,boolean);

create or replace function public.create_public_institution_application(
  p_institution_name text,
  p_brand_name text,
  p_institution_type text,
  p_membership_size integer,
  p_contact_name text,
  p_contact_role text,
  p_contact_email text,
  p_contact_phone text,
  p_website text,
  p_hq_county text,
  p_hq_location text,
  p_description text,
  p_authorised boolean
)
returns table(application_id uuid, application_reference text, status text, logo_upload_token text)
language sql
set search_path = ''
as $$
  select * from private.create_public_institution_application_impl(
    p_institution_name,p_brand_name,p_institution_type,p_membership_size,
    p_contact_name,p_contact_role,p_contact_email,p_contact_phone,p_website,
    p_hq_county,p_hq_location,p_description,p_authorised
  );
$$;

revoke all on function public.create_public_institution_application(text,text,text,integer,text,text,text,text,text,text,text,text,boolean) from public;
grant execute on function public.create_public_institution_application(text,text,text,integer,text,text,text,text,text,text,text,text,boolean) to anon, authenticated;


-- Member application acknowledgement uses the same communication pipeline.
alter table public.member_applications
  add column if not exists application_reference text;

create unique index if not exists member_applications_application_reference_uidx
  on public.member_applications(application_reference)
  where application_reference is not null;

drop function if exists private.create_public_member_application_impl(uuid,text,text,text,jsonb);

create or replace function private.create_public_member_application_impl(
  p_institution_id uuid,
  p_applicant_name text,
  p_email text,
  p_phone text,
  p_payload jsonb
)
returns table(application_id uuid, submission_token uuid, application_reference text, status text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  a public.member_applications;
  v_reference text;
begin
  if not exists (
    select 1 from public.institutions i
    join public.institution_settings s on s.institution_id=i.id
    where i.id=p_institution_id and i.status='active' and i.deleted_at is null and s.application_enabled=true
  ) then raise exception 'Institution is not accepting public applications'; end if;
  if nullif(trim(p_applicant_name),'') is null then raise exception 'Applicant name is required'; end if;
  if nullif(trim(p_email),'') is null then raise exception 'Email is required'; end if;

  v_reference := 'IMBOP-MEM-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));

  insert into public.member_applications(
    institution_id,applicant_name,email,phone,application_payload,status,submitted_at,public_submission_token,application_reference
  ) values (
    p_institution_id,trim(p_applicant_name),lower(trim(p_email)),nullif(trim(p_phone),''),
    coalesce(p_payload,'{}'::jsonb),'SUBMITTED',now(),gen_random_uuid(),v_reference
  ) returning * into a;

  update public.member_applications set status='PENDING_REVIEW',updated_at=now()
  where id=a.id returning * into a;

  perform private.create_email_communication(
    p_institution_id,
    null,
    a.email,
    a.applicant_name,
    null,
    'SYSTEM',
    'MEMBER_APPLICATION',
    'MEMBER_APPLICATION_RECEIVED',
    'IMBOP member application received — ' || a.application_reference,
    'Thank you. Your application to join your Institution on IMBOP has been received. Application Reference: ' ||
      a.application_reference || '. Status: PENDING REVIEW by your Institution. Your Institution will review the application and decide whether to publish your member record. Application ≠ Publication.',
    'member_application',
    a.id,
    jsonb_build_object(
      'application_reference',a.application_reference,
      'status','PENDING_REVIEW',
      'institution_id',p_institution_id
    )
  );

  return query select a.id,a.public_submission_token,a.application_reference,a.status;
end;
$$;

drop function if exists public.create_public_member_application(uuid,text,text,text,jsonb);

create or replace function public.create_public_member_application(
  p_institution_id uuid,
  p_applicant_name text,
  p_email text,
  p_phone text,
  p_payload jsonb
)
returns table(application_id uuid, submission_token uuid, application_reference text, status text)
language sql
set search_path = ''
as $$
  select * from private.create_public_member_application_impl(
    p_institution_id,p_applicant_name,p_email,p_phone,p_payload
  );
$$;

revoke all on function public.create_public_member_application(uuid,text,text,text,jsonb) from public;
grant execute on function public.create_public_member_application(uuid,text,text,text,jsonb) to anon, authenticated;
