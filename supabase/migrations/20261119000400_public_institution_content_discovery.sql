-- Public institution content discovery boundary.
create or replace function public.get_public_institution_content(p_institution_id uuid)
returns jsonb language sql security invoker set search_path=public as $$
 select jsonb_build_object(
  'businesses',coalesce((select jsonb_agg(to_jsonb(b)-'created_by_user_id'-'institution_id') from public.businesses b join public.business_profiles bp on bp.business_id=b.id where b.institution_id=p_institution_id and b.status not in ('DELETED','ARCHIVED') and bp.publication_state='PUBLISHED' and bp.visibility='PUBLIC'),'[]'::jsonb),
  'offers_needs',coalesce((select jsonb_agg(to_jsonb(mi)-'created_by_user_id'-'institution_id') from public.market_items mi where mi.institution_id=p_institution_id and mi.publication_state='PUBLISHED' and mi.visibility='PUBLIC'),'[]'::jsonb),
  'opportunities',coalesce((select jsonb_agg(to_jsonb(o)-'created_by_user_id'-'institution_id') from public.opportunities o where o.institution_id=p_institution_id and o.publication_state='PUBLISHED' and o.visibility='PUBLIC'),'[]'::jsonb),
  'media',coalesce((select jsonb_agg(to_jsonb(cm)-'owner_user_id'-'institution_id'-'storage_path') from public.content_media cm where cm.institution_id=p_institution_id and cm.visibility='PUBLIC' and cm.media_type='IMAGE'),'[]'::jsonb)
 );
$$;
revoke execute on function public.get_public_institution_content(uuid) from public;
grant execute on function public.get_public_institution_content(uuid) to anon,authenticated;