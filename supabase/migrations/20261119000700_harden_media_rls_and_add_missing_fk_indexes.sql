-- IMBOP media RLS hardening and missing foreign-key indexes
-- Applied to production 2026-11-19; kept in repository as source-of-truth migration.

create index if not exists market_items_created_by_user_id_idx
  on public.market_items(created_by_user_id);

create index if not exists market_items_published_by_user_id_idx
  on public.market_items(published_by_user_id);

create index if not exists platform_user_roles_assigned_by_idx
  on public.platform_user_roles(assigned_by);

create index if not exists platform_user_roles_role_id_idx
  on public.platform_user_roles(role_id);

drop policy if exists content_media_insert on public.content_media;
create policy content_media_insert on public.content_media
for insert to authenticated
with check (
  private.is_institution_member(institution_id)
  and owner_user_id = (select auth.uid())
);

drop policy if exists content_media_update on public.content_media;
create policy content_media_update on public.content_media
for update to authenticated
using (
  owner_user_id = (select auth.uid())
  or private.has_institution_permission(institution_id, 'business_manage')
)
with check (
  institution_id = (
    select cm.institution_id
    from public.content_media cm
    where cm.id = content_media.id
  )
  and owner_user_id = (
    select cm.owner_user_id
    from public.content_media cm
    where cm.id = content_media.id
  )
  and (
    owner_user_id = (select auth.uid())
    or private.has_institution_permission(institution_id, 'business_manage')
  )
);

drop policy if exists content_media_delete on public.content_media;
create policy content_media_delete on public.content_media
for delete to authenticated
using (
  owner_user_id = (select auth.uid())
  or private.has_institution_permission(institution_id, 'institution_admin')
);

drop policy if exists platform_user_roles_self_read on public.platform_user_roles;
create policy platform_user_roles_self_read on public.platform_user_roles
for select to authenticated
using (user_id = (select auth.uid()));
