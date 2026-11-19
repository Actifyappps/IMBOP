-- IMBOP Performance Hardening
-- Consolidate duplicate authenticated SELECT policies on institutions into one predicate.

drop policy if exists institutions_authenticated_read_permitted on public.institutions;
drop policy if exists institutions_platform_admin_read on public.institutions;

create policy institutions_authenticated_read_permitted
on public.institutions
for select
to authenticated
using (
  (
    (status='active' and private.is_institution_member(id))
    or private.is_institution_admin(id)
    or private.has_platform_permission('institution_manage')
  )
);
