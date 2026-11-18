revoke execute on function public.platform_configure_institution(uuid,text,boolean,boolean,boolean,text,text,text,boolean,boolean) from anon, authenticated;
revoke execute on function public.platform_institution_onboarding_overview() from anon, authenticated;
grant execute on function public.platform_configure_institution(uuid,text,boolean,boolean,boolean,text,text,text,boolean,boolean) to authenticated;
grant execute on function public.platform_institution_onboarding_overview() to authenticated;
