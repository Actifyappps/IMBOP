-- IMBOP Security Hardening
-- Tighten exposed SECURITY DEFINER functions without breaking intentional public read endpoints.

revoke execute on function public.get_imbop_public_stats() from authenticated;
grant execute on function public.get_imbop_public_stats() to anon;

revoke execute on function public.get_public_imbop_pricing_plans() from authenticated;
grant execute on function public.get_public_imbop_pricing_plans() to anon;

create or replace function public.get_platform_communication_recipients()
returns table(user_id uuid, institution_id uuid, institution_name text, email text, recipient_name text)
language sql
security definer
set search_path to ''
as $function$
  select m.user_id,m.institution_id,i.name,u.email,u.email
  from public.memberships m
  join public.institutions i on i.id=m.institution_id
  join public.membership_roles mr on mr.membership_id=m.id
  join auth.users u on u.id=m.user_id
  where m.status='active'
    and i.status='active'
    and i.deleted_at is null
    and mr.role_code in ('institution_admin','institution_owner')
    and private.has_platform_permission('institution_manage')
  order by i.name,u.email
$function$;

revoke execute on function public.get_platform_communication_recipients() from public,anon,authenticated;
grant execute on function public.get_platform_communication_recipients() to authenticated;
