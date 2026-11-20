-- Make public institution submissions idempotent across client retries.
-- The request key identifies one logical form submission; the email key identifies
-- its one receipt communication. Existing legacy clients are asked to reload.

alter table public.institution_applications
  add column if not exists submission_idempotency_key uuid;

create unique index if not exists institution_applications_submission_idempotency_key_uidx
  on public.institution_applications (submission_idempotency_key)
  where submission_idempotency_key is not null;

drop function if exists public.create_public_institution_application(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean
);
drop function if exists private.create_public_institution_application_impl(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean
);

create function private.create_public_institution_application_impl(
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
  p_authorised boolean,
  p_submission_idempotency_key uuid
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
  if p_submission_idempotency_key is null then
    raise exception 'SUBMISSION_IDEMPOTENCY_KEY_REQUIRED';
  end if;

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

  select * into a
  from public.institution_applications
  where submission_idempotency_key=p_submission_idempotency_key
  for update;

  if found then
    if a.institution_name is distinct from btrim(p_institution_name)
      or a.brand_name is distinct from nullif(btrim(p_brand_name),'')
      or a.institution_type is distinct from btrim(p_institution_type)
      or a.membership_size is distinct from p_membership_size
      or a.contact_name is distinct from btrim(p_contact_name)
      or a.contact_role is distinct from btrim(p_contact_role)
      or a.contact_email is distinct from lower(btrim(p_contact_email))
      or a.contact_phone is distinct from btrim(p_contact_phone)
      or a.website is distinct from nullif(btrim(p_website),'')
      or a.county is distinct from btrim(p_hq_county)
      or a.hq_location is distinct from btrim(p_hq_location)
      or a.description is distinct from btrim(p_description) then
      raise exception using errcode='22023', message='IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_DETAILS';
    end if;

    return query select a.id,a.application_reference,a.status,a.logo_upload_token;
    return;
  end if;

  v_logo_token := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
  v_reference := 'IMBOP-APP-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));

  insert into public.institution_applications(
    institution_name,legal_name,brand_name,institution_type,contact_name,contact_role,
    contact_email,contact_phone,membership_size,website,location,county,hq_location,
    description,logo_upload_token,application_reference,application_payload,status,submitted_at,
    submission_idempotency_key
  ) values (
    btrim(p_institution_name),null,nullif(btrim(p_brand_name),''),btrim(p_institution_type),
    btrim(p_contact_name),btrim(p_contact_role),lower(btrim(p_contact_email)),btrim(p_contact_phone),
    p_membership_size,nullif(btrim(p_website),''),btrim(p_hq_location),btrim(p_hq_county),
    btrim(p_hq_location),btrim(p_description),v_logo_token,v_reference,
    jsonb_build_object(
      'source','PUBLIC_IMBOP_APPLICATION',
      'applicant_type','INSTITUTION',
      'authorised_applicant',true,
      'schema_version','2026-11-19'
    ),
    'SUBMITTED',now(),p_submission_idempotency_key
  )
  on conflict (submission_idempotency_key)
    where submission_idempotency_key is not null
    do nothing
  returning * into a;

  if not found then
    select * into a
    from public.institution_applications
    where submission_idempotency_key=p_submission_idempotency_key
    for update;

    if a.id is null
      or a.institution_name is distinct from btrim(p_institution_name)
      or a.brand_name is distinct from nullif(btrim(p_brand_name),'')
      or a.institution_type is distinct from btrim(p_institution_type)
      or a.membership_size is distinct from p_membership_size
      or a.contact_name is distinct from btrim(p_contact_name)
      or a.contact_role is distinct from btrim(p_contact_role)
      or a.contact_email is distinct from lower(btrim(p_contact_email))
      or a.contact_phone is distinct from btrim(p_contact_phone)
      or a.website is distinct from nullif(btrim(p_website),'')
      or a.county is distinct from btrim(p_hq_county)
      or a.hq_location is distinct from btrim(p_hq_location)
      or a.description is distinct from btrim(p_description) then
      raise exception using errcode='22023', message='IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_DETAILS';
    end if;

    return query select a.id,a.application_reference,a.status,a.logo_upload_token;
    return;
  end if;

  update public.institution_applications
     set status='PENDING_REVIEW',updated_at=now()
   where id=a.id
   returning * into a;

  perform private.create_email_communication(
    null,null,a.contact_email,a.contact_name,null,'SYSTEM',
    'INSTITUTION_APPLICATION','INSTITUTION_APPLICATION_RECEIVED',
    'IMBOP application received — ' || a.application_reference,
    'Thank you. Your Institution application to IMBOP has been received. Application Reference: ' ||
      a.application_reference || '. Status: PENDING REVIEW. SE IMBOP will review your application and communicate the outcome or any required action. Application ≠ Publication.',
    'institution_application',a.id,
    jsonb_build_object(
      'application_reference',a.application_reference,
      'status','PENDING_REVIEW',
      'applicant_type','INSTITUTION',
      'idempotency_key','institution_application:' || a.id::text || ':RECEIVED'
    )
  );

  return query select a.id,a.application_reference,a.status,a.logo_upload_token;
exception
  when check_violation then
    raise exception 'Please check the details you entered and try again.';
end;
$$;

revoke all on function private.create_public_institution_application_impl(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean,uuid
) from public,anon,authenticated;
grant execute on function private.create_public_institution_application_impl(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean,uuid
) to anon,authenticated;

create function public.create_public_institution_application(
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
  p_authorised boolean,
  p_submission_idempotency_key uuid
)
returns table(application_id uuid, application_reference text, status text, logo_upload_token text)
language sql
set search_path = ''
as $$
  select * from private.create_public_institution_application_impl(
    p_institution_name,p_brand_name,p_institution_type,p_membership_size,
    p_contact_name,p_contact_role,p_contact_email,p_contact_phone,p_website,
    p_hq_county,p_hq_location,p_description,p_authorised,p_submission_idempotency_key
  );
$$;

revoke all on function public.create_public_institution_application(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean,uuid
) from public;
grant execute on function public.create_public_institution_application(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean,uuid
) to anon,authenticated;

-- Keep a clear response for stale browser clients without allowing the old
-- request shape to create an unkeyed application or receipt.
create function public.create_public_institution_application(
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
set search_path = ''
as $$
begin
  raise exception using errcode='55000',message='APPLICATION_RELOAD_REQUIRED: Reload the application form before submitting.';
end;
$$;

revoke all on function public.create_public_institution_application(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean
) from public;
grant execute on function public.create_public_institution_application(
  text,text,text,integer,text,text,text,text,text,text,text,text,boolean
) to anon,authenticated;
