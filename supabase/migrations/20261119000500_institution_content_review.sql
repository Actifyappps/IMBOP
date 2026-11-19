-- Institution Admin review boundary for member offers, needs and opportunities.
-- Submission is separated from publication; institution publication authority is required.

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
 elsif p_action='RETURN' and r.publication_state='PENDING_REVIEW' then
   update public.market_items set publication_state='RETURNED',published_at=null,published_by_user_id=null where id=p_item_id returning * into r;
 elsif p_action='REJECT' and r.publication_state in ('SUBMITTED','PENDING_REVIEW') then
   update public.market_items set publication_state='REJECTED',published_at=null,published_by_user_id=null where id=p_item_id returning * into r;
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
 elsif p_action='RETURN' and r.publication_state='PENDING_REVIEW' then
   update public.opportunities set publication_state='RETURNED',published_at=null,published_by_user_id=null where id=p_opportunity_id returning * into r;
 elsif p_action='REJECT' and r.publication_state in ('SUBMITTED','PENDING_REVIEW') then
   update public.opportunities set publication_state='REJECTED',published_at=null,published_by_user_id=null where id=p_opportunity_id returning * into r;
 else raise exception 'Invalid opportunity review transition'; end if;
 return r;
end $$;

revoke execute on function public.review_institution_market_item(uuid,text,text) from public, anon;
grant execute on function public.review_institution_market_item(uuid,text,text) to authenticated;
revoke execute on function public.review_institution_opportunity(uuid,text,text) from public, anon;
grant execute on function public.review_institution_opportunity(uuid,text,text) to authenticated;
