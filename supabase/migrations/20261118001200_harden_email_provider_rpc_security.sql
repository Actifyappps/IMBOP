-- IMBOP Communications: harden provider delivery RPCs
-- These functions already enforce the platform permission boundary internally.
-- SECURITY INVOKER keeps the exposed RPCs inside the caller's RLS boundary.

alter function public.claim_platform_email_delivery(uuid) security invoker;
alter function public.record_platform_email_delivery_result(uuid,text,text,text) security invoker;

revoke execute on function public.claim_platform_email_delivery(uuid) from anon;
revoke execute on function public.record_platform_email_delivery_result(uuid,text,text,text) from anon;
grant execute on function public.claim_platform_email_delivery(uuid) to authenticated;
grant execute on function public.record_platform_email_delivery_result(uuid,text,text,text) to authenticated;
