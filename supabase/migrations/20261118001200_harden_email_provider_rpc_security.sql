-- IMBOP Communications: harden provider delivery RPC security
-- These functions enforce the platform permission boundary internally.
-- SECURITY INVOKER keeps the exposed RPCs inside the caller's RLS boundary.
-- PUBLIC execution is revoked explicitly; only authenticated callers may invoke them.

alter function public.claim_platform_email_delivery(uuid) security invoker;
alter function public.record_platform_email_delivery_result(uuid,text,text,text) security invoker;

revoke execute on function public.claim_platform_email_delivery(uuid) from public;
revoke execute on function public.record_platform_email_delivery_result(uuid,text,text,text) from public;
grant execute on function public.claim_platform_email_delivery(uuid) to authenticated;
grant execute on function public.record_platform_email_delivery_result(uuid,text,text,text) to authenticated;
