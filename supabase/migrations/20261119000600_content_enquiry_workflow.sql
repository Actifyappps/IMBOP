-- Close the public discovery loop with a secure member enquiry action.
create or replace function public.create_content_enquiry(
  p_target_type text,
  p_target_id uuid,
  p_message text
)
returns uuid
language plpgsql
security invoker
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_institution uuid;
  v_owner uuid;
  v_target_label text;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'Authentication is required to send an enquiry';
  end if;
  if coalesce(length(trim(p_message)),0) < 10 then
    raise exception 'Please provide a meaningful enquiry';
  end if;
  if length(p_message) > 3000 then
    raise exception 'Enquiry message is too long';
  end if;

  if upper(p_target_type) = 'BUSINESS' then
    select b.institution_id, b.created_by_user_id, b.name
      into v_institution, v_owner, v_target_label
    from public.businesses b
    join public.business_profiles bp on bp.business_id=b.id
    where b.id=p_target_id
      and b.archived_at is null
      and bp.publication_state='PUBLISHED'
      and bp.visibility='PUBLIC'
    limit 1;
  elsif upper(p_target_type) = 'MARKET_ITEM' then
    select m.institution_id, m.created_by_user_id, m.title
      into v_institution, v_owner, v_target_label
    from public.market_items m
    where m.id=p_target_id
      and m.publication_state='PUBLISHED'
      and m.visibility='PUBLIC';
  elsif upper(p_target_type) = 'OPPORTUNITY' then
    select o.institution_id, o.created_by_user_id, o.title
      into v_institution, v_owner, v_target_label
    from public.opportunities o
    where o.id=p_target_id
      and o.publication_state='PUBLISHED'
      and o.visibility='PUBLIC';
  else
    raise exception 'Unsupported enquiry target';
  end if;

  if v_institution is null then
    raise exception 'This content is not currently available for enquiry';
  end if;

  if not private.is_institution_member(v_institution) then
    raise exception 'You must belong to the institution network to send this enquiry';
  end if;

  insert into public.enquiries(institution_id, source_user_id, target_type, target_id, message, status)
  values (v_institution, v_user, upper(p_target_type), p_target_id, trim(p_message), 'OPEN')
  returning id into v_id;

  if v_owner is not null and v_owner <> v_user then
    perform private.create_in_app_communication(
      v_institution, v_owner, null, null, v_user, 'SYSTEM', 'ENQUIRY',
      'CONTENT_ENQUIRY_RECEIVED', 'New IMBOP enquiry',
      'A member has sent an enquiry about: ' || coalesce(v_target_label,'your published content') || '.',
      'ENQUIRY', v_id,
      jsonb_build_object('target_type', upper(p_target_type), 'target_id', p_target_id)
    );
  end if;

  return v_id;
end;
$$;

revoke execute on function public.create_content_enquiry(text,uuid,text) from public, anon;
grant execute on function public.create_content_enquiry(text,uuid,text) to authenticated;