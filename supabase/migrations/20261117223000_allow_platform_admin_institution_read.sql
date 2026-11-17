-- Allow SE platform staff with institution management permission to view all institutions,
-- including pending onboarding and non-active lifecycle states.
create policy "institutions_platform_admin_read"
on public.institutions
for select
to authenticated
using (private.has_platform_permission('institution_manage'));
