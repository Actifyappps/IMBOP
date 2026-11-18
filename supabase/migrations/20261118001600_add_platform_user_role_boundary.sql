-- IMBOP platform access boundary
-- Platform users are not institution members. Keep platform roles in a
-- dedicated access table instead of forcing them into tenant memberships.

create table if not exists public.platform_user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete restrict,
  status text not null default 'active'
    check (status in ('active','suspended','revoked')),
  assigned_at timestamptz not null default now(),
  assigned_by uuid references auth.users(id) on delete set null,
  primary key (user_id, role_id)
);

create index if not exists platform_user_roles_active_user_idx
  on public.platform_user_roles(user_id)
  where status = 'active';

alter table public.platform_user_roles enable row level security;

revoke all on public.platform_user_roles from anon, authenticated;
grant select on public.platform_user_roles to authenticated;

drop policy if exists platform_user_roles_self_read on public.platform_user_roles;
create policy platform_user_roles_self_read
on public.platform_user_roles
for select
to authenticated
using (user_id = auth.uid());

create or replace function private.has_platform_permission(p_permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
select exists(
  select 1
  from public.platform_user_roles pur
  join public.roles r on r.id = pur.role_id
  join public.role_permissions rp on rp.role_id = r.id
  join public.permissions p on p.id = rp.permission_id
  where pur.user_id = (select auth.uid())
    and pur.status = 'active'
    and r.scope = 'platform'
    and p.code = p_permission_code
)
or exists(
  select 1
  from public.memberships m
  join public.membership_roles mr on mr.membership_id = m.id
  join public.roles r on r.id = mr.role_id
  join public.role_permissions rp on rp.role_id = r.id
  join public.permissions p on p.id = rp.permission_id
  where m.user_id = (select auth.uid())
    and m.status = 'active'
    and r.scope = 'platform'
    and p.code = p_permission_code
);
$function$;

revoke execute on function private.has_platform_permission(text) from public, anon, authenticated;
grant execute on function private.has_platform_permission(text) to authenticated;

insert into public.platform_user_roles(user_id, role_id, status)
select u.id, r.id, 'active'
from auth.users u
join public.roles r on r.code = 'se_platform_owner' and r.scope = 'platform'
where u.id = '91dd2b9f-f973-4beb-93af-e4549fe4dc07'
on conflict (user_id, role_id) do update
set status = 'active';

insert into public.platform_user_roles(user_id, role_id, status)
select u.id, r.id, 'active'
from auth.users u
join public.roles r on r.code = 'se_operations_admin' and r.scope = 'platform'
where u.id = '89c730ec-4cd7-42cd-bfd4-327d3b1bdd48'
on conflict (user_id, role_id) do update
set status = 'active';

comment on table public.platform_user_roles is
  'Authoritative platform-scoped role assignments. Platform users are not institution memberships.';
