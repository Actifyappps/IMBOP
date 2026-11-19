-- Canonical Institution Application intake
-- Application = identity + contact + basic institutional context + authorisation.
-- Readiness carries legal/registration/governance evidence later.

alter table public.institution_applications
  add column if not exists brand_name text,
  add column if not exists contact_role text,
  add column if not exists county text,
  add column if not exists hq_location text,
  add column if not exists logo_storage_path text,
  add column if not exists logo_upload_token text;

create index if not exists institution_applications_logo_upload_token_idx
  on public.institution_applications (logo_upload_token);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'imbop-application-logos',
  'imbop-application-logos',
  false,
  1048576,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 1048576,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.application_logo_upload_allowed(p_application_id uuid, p_token text)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.institution_applications a
    where a.id = p_application_id
      and a.status in ('SUBMITTED','PENDING_REVIEW','RETURNED')
      and a.logo_upload_token = p_token
  );
$$;

revoke all on function private.application_logo_upload_allowed(uuid,text) from public, anon, authenticated;

drop policy if exists "Public application logo uploads" on storage.objects;
create policy "Public application logo uploads"
on storage.objects
for insert
to anon
with check (
  bucket_id = 'imbop-application-logos'
  and (storage.foldername(name))[1] = 'applications'
  and array_length(storage.foldername(name),1) = 3
  and storage.extension(name) in ('jpg','jpeg','png','webp')
  and private.application_logo_upload_allowed(
    ((storage.foldername(name))[2])::uuid,
    split_part(storage.filename(name),'.',1)
  )
);

drop policy if exists "Platform admins can read application logos" on storage.objects;
create policy "Platform admins can read application logos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'imbop-application-logos'
  and (storage.foldername(name))[1] = 'applications'
  and private.has_platform_permission('institution_manage')
);

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
returns table(application_id uuid, status text, logo_upload_token text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  a public.institution_applications;
  v_logo_token text;
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

  insert into public.institution_applications(
    institution_name, legal_name, brand_name, institution_type, contact_name, contact_role,
    contact_email, contact_phone, membership_size, website, location, county, hq_location,
    description, logo_upload_token, application_payload, status, submitted_at
  ) values (
    btrim(p_institution_name), null, nullif(btrim(p_brand_name),''), btrim(p_institution_type),
    btrim(p_contact_name), btrim(p_contact_role), lower(btrim(p_contact_email)), btrim(p_contact_phone),
    p_membership_size, nullif(btrim(p_website),''), btrim(p_hq_location), btrim(p_hq_county),
    btrim(p_hq_location), btrim(p_description), v_logo_token,
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

  return query select a.id, a.status, a.logo_upload_token;
exception
  when check_violation then
    raise exception 'Please check the details you entered and try again.';
end;
$$;

drop function if exists public.create_public_institution_application(text,text,text,text,text,text,integer,text,text,text);

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
returns table(application_id uuid, status text, logo_upload_token text)
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

create or replace function private.attach_public_institution_application_logo_impl(
  p_application_id uuid,
  p_logo_token text,
  p_logo_storage_path text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  a public.institution_applications;
begin
  select * into a
  from public.institution_applications
  where id=p_application_id
    and logo_upload_token=p_logo_token
    and status in ('SUBMITTED','PENDING_REVIEW','RETURNED')
  for update;

  if not found then raise exception 'APPLICATION_LOGO_TOKEN_INVALID'; end if;

  if p_logo_storage_path !~ ('^applications/' || p_application_id::text || '/' || p_logo_token || '\\.(jpg|jpeg|png|webp)$') then
    raise exception 'INVALID_APPLICATION_LOGO_PATH';
  end if;

  update public.institution_applications
     set logo_storage_path=p_logo_storage_path, updated_at=now()
   where id=p_application_id;

  return true;
end;
$$;

drop function if exists public.attach_public_institution_application_logo(uuid,text,text);

create or replace function public.attach_public_institution_application_logo(
  p_application_id uuid,
  p_logo_token text,
  p_logo_storage_path text
)
returns boolean
language sql
set search_path = ''
as $$
  select private.attach_public_institution_application_logo_impl(
    p_application_id,p_logo_token,p_logo_storage_path
  );
$$;

revoke all on function public.attach_public_institution_application_logo(uuid,text,text) from public;
grant execute on function public.attach_public_institution_application_logo(uuid,text,text) to anon, authenticated;
