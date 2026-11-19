-- Institution publication review boundary for business profiles and member content.
-- Publishing content also promotes its attached images to PUBLIC visibility.

create or replace function public.review_institution_business_profile(p_profile_id uuid,p_action text,p_notes text default null)
returns public.business_profiles
language plpgsql
security invoker
set search_path='public,private'
as $$
declare r public.business_profiles;
begin
 if not private.has_institution_permission((select institution_id from public.business_profiles where id=p_profile_id),'publication_manage') then
   raise exception 'Publication authority required';
 end if;
 select * into r from public.business_profiles where id=p_profile_id for update;
 if r.id is null then raise exception 'Business profile not found'; end if;

 if p_action='SUBMIT_FOR_REVIEW' and r.publication_state in ('SUBMITTED','RETURNED') then
   update public.business_profiles set publication_state='PENDING_REVIEW' where id=p_profile_id returning * into r;
 elsif p_action='PUBLISH' and r.publication_state='PENDING_REVIEW' then
   update public.business_profiles set publication_state='PUBLISHED',published_at=now(),published_by_user_id=(select auth.uid()),visibility='PUBLIC' where id=p_profile_id returning * into r;
   update public.content_media set visibility='PUBLIC' where institution_id=r.institution_id and ((entity_type='BUSINESS_PROFILE' and entity_id=r.id) or (entity_type='BUSINESS' and entity_id=r.business_id)) and media_type='IMAGE';
 elsif p_action='RETURN' and r.publication_state='PENDING_REVIEW' then
   update public.business_profiles set publication_state='RETURNED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_profile_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and ((entity_type='BUSINESS_PROFILE' and entity_id=r.id) or (entity_type='BUSINESS' and entity_id=r.business_id));
 elsif p_action='REJECT' and r.publication_state in ('SUBMITTED','PENDING_REVIEW') then
   update public.business_profiles set publication_state='REJECTED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_profile_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and ((entity_type='BUSINESS_PROFILE' and entity_id=r.id) or (entity_type='BUSINESS' and entity_id=r.business_id));
 elsif p_action='UNPUBLISH' and r.publication_state='PUBLISHED' then
   update public.business_profiles set publication_state='UNPUBLISHED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_profile_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and ((entity_type='BUSINESS_PROFILE' and entity_id=r.id) or (entity_type='BUSINESS' and entity_id=r.business_id));
 else
   raise exception 'Invalid business profile review transition';
 end if;
 return r;
end $$;

create or replace function public.review_institution_market_item(p_item_id uuid,p_action text,p_notes text default null)
returns public.market_items language plpgsql security invoker set search_path='public,private'
as $$
declare r public.market_items;
begin
 if not private.has_institution_permission((select institution_id from public.market_items where id=p_item_id),'publication_manage') then raise exception 'Publication authority required'; end if;
 select * into r from public.market_items where id=p_item_id for update;
 if r.id is null then raise exception 'Market item not found'; end if;
 if p_action='SUBMIT_FOR_REVIEW' and r.publication_state in ('SUBMITTED','RETURNED') then
   update public.market_items set publication_state='PENDING_REVIEW' where id=p_item_id returning * into r;
 elsif p_action='PUBLISH' and r.publication_state='PENDING_REVIEW' then
   update public.market_items set publication_state='PUBLISHED',published_at=now(),published_by_user_id=(select auth.uid()),visibility='PUBLIC' where id=p_item_id returning * into r;
   update public.content_media set visibility='PUBLIC' where institution_id=r.institution_id and entity_type=r.intent_type and entity_id=r.id and media_type='IMAGE';
 elsif p_action='RETURN' and r.publication_state='PENDING_REVIEW' then
   update public.market_items set publication_state='RETURNED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_item_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and entity_type=r.intent_type and entity_id=r.id;
 elsif p_action='REJECT' and r.publication_state in ('SUBMITTED','PENDING_REVIEW') then
   update public.market_items set publication_state='REJECTED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_item_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and entity_type=r.intent_type and entity_id=r.id;
 else raise exception 'Invalid market item review transition'; end if;
 return r;
end $$;

create or replace function public.review_institution_opportunity(p_opportunity_id uuid,p_action text,p_notes text default null)
returns public.opportunities language plpgsql security invoker set search_path='public,private'
as $$
declare r public.opportunities;
begin
 if not private.has_institution_permission((select institution_id from public.opportunities where id=p_opportunity_id),'publication_manage') then raise exception 'Publication authority required'; end if;
 select * into r from public.opportunities where id=p_opportunity_id for update;
 if r.id is null then raise exception 'Opportunity not found'; end if;
 if p_action='SUBMIT_FOR_REVIEW' and r.publication_state in ('SUBMITTED','RETURNED') then
   update public.opportunities set publication_state='PENDING_REVIEW' where id=p_opportunity_id returning * into r;
 elsif p_action='PUBLISH' and r.publication_state='PENDING_REVIEW' then
   update public.opportunities set publication_state='PUBLISHED',published_at=now(),published_by_user_id=(select auth.uid()),visibility='PUBLIC' where id=p_opportunity_id returning * into r;
   update public.content_media set visibility='PUBLIC' where institution_id=r.institution_id and entity_type='OPPORTUNITY' and entity_id=r.id and media_type='IMAGE';
 elsif p_action='RETURN' and r.publication_state='PENDING_REVIEW' then
   update public.opportunities set publication_state='RETURNED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_opportunity_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and entity_type='OPPORTUNITY' and entity_id=r.id;
 elsif p_action='REJECT' and r.publication_state in ('SUBMITTED','PENDING_REVIEW') then
   update public.opportunities set publication_state='REJECTED',published_at=null,published_by_user_id=null,visibility='INSTITUTION' where id=p_opportunity_id returning * into r;
   update public.content_media set visibility='INSTITUTION' where institution_id=r.institution_id and entity_type='OPPORTUNITY' and entity_id=r.id;
 else raise exception 'Invalid opportunity review transition'; end if;
 return r;
end $$;

revoke execute on function public.review_institution_business_profile(uuid,text,text) from public,anon;
grant execute on function public.review_institution_business_profile(uuid,text,text) to authenticated;
revoke execute on function public.review_institution_market_item(uuid,text,text) from public,anon;
grant execute on function public.review_institution_market_item(uuid,text,text) to authenticated;
revoke execute on function public.review_institution_opportunity(uuid,text,text) from public,anon;
grant execute on function public.review_institution_opportunity(uuid,text,text) to authenticated;