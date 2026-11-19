-- Harden platform communication recipient lookup.
-- The function reads auth.users email addresses and is intended only for SE platform operators.
-- Keep the existing SECURITY DEFINER implementation, but enforce the same platform
-- permission boundary inside the function so an authenticated caller cannot use it
-- merely by possessing a valid session.

create or replace function public.get_platform_communication_recipients()
returns table(
  user_id uuid,
  institution_id uuid,
  institution_name text,
  email text,
  recipient_name text
)
language sql
security definer
set search_path = ''
as $function$
  select
    m.user_id,
    m.institution_id,
    i.name,
    u.email,
    u.email
  from public.memberships m
  join public.institutions i on i.id=m.institution_id
  join public.membership_roles mr on mr.membership_id=m.id
  join auth.users u on u.id=m.user_id
  where private.has_platform_permission('institution_manage')
    and m.status='active'
    and i.status='active'
    and i.deleted_at is null
    and mr.role_code in ('institution_admin','institution_owner')
  order by i.name,u.email
$function$;

revoke execute on function public.get_platform_communication_recipients() from public, anon;
grant execute on function public.get_platform_communication_recipients() to authenticated;
