-- IMBOP Communications: controlled SE Admin Centre and templates
create table if not exists public.communication_templates (
 id uuid primary key default gen_random_uuid(), template_code text unique not null, template_name text not null,
 communication_type text not null, default_subject text not null, default_body text not null,
 active boolean not null default true, updated_at timestamptz not null default now(),
 updated_by_user_id uuid references auth.users(id) on delete set null
);
alter table public.communication_templates enable row level security;
revoke all on table public.communication_templates from anon,authenticated;
grant select on table public.communication_templates to authenticated;
drop policy if exists communication_templates_admin_select on public.communication_templates;
create policy communication_templates_admin_select on public.communication_templates for select to authenticated using (private.has_platform_permission('institution_manage'));
insert into public.communication_templates(template_code,template_name,communication_type,default_subject,default_body) values
('PLATFORM_NOTICE','Platform Notice','PLATFORM_NOTICE','IMBOP platform notice','{{message}}'),
('PRICING_PLAN_CHANGED','Pricing Plan Changed','PRICING','Your IMBOP plan has changed','Your Institution is now on the {{plan_name}} plan based on {{imbop_onboards}} IMBOP Onboards.'),
('TRANSITION_PAYMENT_NOTICE','Transition Payment Notice','PRICING','Your IMBOP transition month','Your Institution has grown beyond the first 50 IMBOP Onboards. Your discounted transition minimum is KES {{transition_minimum}} this month.')
on conflict (template_code) do nothing;

create or replace function public.get_platform_communication_templates()
returns setof public.communication_templates language sql security invoker set search_path='public'
as $$ select * from public.communication_templates where active order by template_name $$;
revoke execute on function public.get_platform_communication_templates() from public,anon;
grant execute on function public.get_platform_communication_templates() to authenticated;

create or replace function public.get_platform_communication_recipients()
returns table(user_id uuid,institution_id uuid,institution_name text,email text,recipient_name text)
language sql security definer set search_path=''
as $function$
 select m.user_id,m.institution_id,i.name,u.email,u.email
 from public.memberships m join public.institutions i on i.id=m.institution_id
 join public.membership_roles mr on mr.membership_id=m.id join auth.users u on u.id=m.user_id
 where m.status='active' and i.status='active' and i.deleted_at is null
   and mr.role_code in ('institution_admin','institution_owner')
 order by i.name,u.email
$function$;
revoke execute on function public.get_platform_communication_recipients() from public,anon;
grant execute on function public.get_platform_communication_recipients() to authenticated;

create or replace function public.send_platform_in_app_communication(
 p_recipient_user_id uuid,p_institution_id uuid,p_subject text,p_body text,
 p_communication_type text default 'PLATFORM_NOTICE',p_event_type text default 'ADMIN_MESSAGE')
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_id uuid;
begin
 if auth.uid() is null or not private.has_platform_permission('institution_manage') then raise exception 'NOT_AUTHORIZED'; end if;
 if p_recipient_user_id is null or nullif(trim(p_subject),'') is null or nullif(trim(p_body),'') is null then raise exception 'RECIPIENT_SUBJECT_BODY_REQUIRED'; end if;
 v_id:=private.create_in_app_communication(p_institution_id,p_recipient_user_id,null,null,auth.uid(),'ADMIN',p_communication_type,p_event_type,trim(p_subject),trim(p_body),'admin_communication',null,jsonb_build_object('admin_user_id',auth.uid()));
 return jsonb_build_object('ok',true,'communication_id',v_id);
end;
$function$;
revoke execute on function public.send_platform_in_app_communication(uuid,uuid,text,text,text,text) from public,anon;
grant execute on function public.send_platform_in_app_communication(uuid,uuid,text,text,text,text) to authenticated;