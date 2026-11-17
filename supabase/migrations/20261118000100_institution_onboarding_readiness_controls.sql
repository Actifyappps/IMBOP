-- Institution onboarding readiness controls
-- Platform administration must be able to see and complete configuration
-- before activation, while activation remains guarded by configuration + active admin.

create or replace function public.platform_institution_onboarding_overview()
returns table(
  id uuid,
  name text,
  status text,
  configured boolean,
  configured_at timestamptz,
  active_admin_count bigint,
  admin_emails text[],
  ready_to_activate boolean
)
language sql
security definer
set search_path to ''
as $$
  select
    i.id,
    i.name,
    i.status,
    (s.configured_at is not null),
    s.configured_at,
    count(distinct m.id) filter (where m.status='active' and r.code='institution_admin' and r.scope='institution'),
    coalesce(array_agg(distinct up.email) filter (where m.status='active' and r.code='institution_admin' and r.scope='institution' and up.email is not null), '{}'::text[]),
    (s.configured_at is not null and count(distinct m.id) filter (where m.status='active' and r.code='institution_admin' and r.scope='institution') > 0)
  from public.institutions i
  left join public.institution_settings s on s.institution_id=i.id
  left join public.memberships m on m.institution_id=i.id
  left join public.membership_roles mr on mr.membership_id=m.id
  left join public.roles r on r.id=mr.role_id
  left join public.user_profiles up on up.id=m.user_id
  where private.has_platform_permission('institution_manage')
  group by i.id,i.name,i.status,s.configured_at
  order by i.created_at asc;
$$;

revoke all on function public.platform_institution_onboarding_overview() from public;
grant execute on function public.platform_institution_onboarding_overview() to authenticated;

create or replace function public.platform_configure_institution(
  p_institution_id uuid,
  p_membership_mode text default 'APPLICATION',
  p_application_enabled boolean default true,
  p_require_membership_review boolean default true,
  p_publication_requires_review boolean default true,
  p_default_member_visibility text default 'INSTITUTION',
  p_default_business_visibility text default 'INSTITUTION',
  p_default_opportunity_visibility text default 'INSTITUTION',
  p_public_discovery_enabled boolean default true,
  p_public_profile_enabled boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare v jsonb;
begin
  if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not private.has_platform_permission('institution_manage') then
    raise exception 'PLATFORM_PERMISSION_REQUIRED';
  end if;

  update public.institution_settings
     set membership_mode=p_membership_mode,
         application_enabled=p_application_enabled,
         require_membership_review=p_require_membership_review,
         publication_requires_review=p_publication_requires_review,
         default_member_visibility=p_default_member_visibility,
         default_business_visibility=p_default_business_visibility,
         default_opportunity_visibility=p_default_opportunity_visibility,
         public_discovery_enabled=p_public_discovery_enabled,
         public_profile_enabled=p_public_profile_enabled,
         configured_at=now(),
         configured_by_user_id=auth.uid(),
         updated_at=now()
   where institution_id=p_institution_id
   returning to_jsonb(institution_settings.*) into v;

  if v is null then raise exception 'INSTITUTION_SETTINGS_NOT_FOUND'; end if;

  insert into public.audit_events(actor_user_id,institution_id,event_code,action,target_type,target_id,metadata)
  values(auth.uid(),p_institution_id,'INSTITUTION_CONFIGURED','UPDATE','INSTITUTION',p_institution_id,
    jsonb_build_object('source','PLATFORM_ONBOARDING','membership_mode',p_membership_mode,
      'application_enabled',p_application_enabled,'require_membership_review',p_require_membership_review,
      'publication_requires_review',p_publication_requires_review,'public_discovery_enabled',p_public_discovery_enabled,
      'public_profile_enabled',p_public_profile_enabled));

  return v;
end;
$$;

revoke all on function public.platform_configure_institution(uuid,text,boolean,boolean,boolean,text,text,text,boolean,boolean) from public;
grant execute on function public.platform_configure_institution(uuid,text,boolean,boolean,boolean,text,text,text,boolean,boolean) to authenticated;
