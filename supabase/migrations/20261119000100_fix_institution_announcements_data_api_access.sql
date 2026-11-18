-- Allow authenticated institution members/admins to read institution announcements through the Data API.
-- RLS remains the row-level authorization boundary.
grant select on table public.institution_announcements to authenticated;
