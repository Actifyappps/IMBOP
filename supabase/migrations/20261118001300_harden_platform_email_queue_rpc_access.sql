-- Restrict the platform email queue reader to authenticated callers.
-- The function performs its own platform-permission check; PUBLIC/anon execution
-- is unnecessary and creates avoidable exposed RPC surface.
revoke execute on function public.get_platform_email_queue(text, integer, integer) from public;
grant execute on function public.get_platform_email_queue(text, integer, integer) to authenticated;
