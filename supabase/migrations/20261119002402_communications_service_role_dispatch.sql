-- Allow the automatic service-role worker to invoke the existing platform permission helper.
-- No user-facing role receives this grant.
grant usage on schema private to service_role;
grant execute on function private.has_platform_permission(text) to service_role;
