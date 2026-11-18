-- Alphabetical public institution discovery.
create or replace function public.search_public_institutions_by_initial(
  p_initial text default null, p_query text default null,
  p_min_onboards integer default null, p_max_onboards integer default null,
  p_limit integer default 24, p_offset integer default 0
)
returns table (
  institution_id uuid, name text, legal_name text, slug text, institution_type text, description text,
  stated_membership_count integer, imbop_onboards bigint, total_count bigint
)
language sql stable security definer set search_path = public, private
as $$
  with base as (
    select i.id institution_id, i.name, i.legal_name, i.slug, i.institution_type, i.description,
           i.stated_membership_count, count(m.id) filter (where m.status = 'active') imbop_onboards
    from public.institutions i left join public.memberships m on m.institution_id = i.id
    where i.status = 'active' and i.deleted_at is null
      and (nullif(btrim(p_initial), '') is null
        or upper(left(btrim(i.name), 1)) = upper(left(btrim(p_initial), 1)))
      and (nullif(btrim(p_query), '') is null
        or i.name ilike '%' || btrim(p_query) || '%'
        or coalesce(i.legal_name, '') ilike '%' || btrim(p_query) || '%'
        or coalesce(i.institution_type, '') ilike '%' || btrim(p_query) || '%'
        or coalesce(i.description, '') ilike '%' || btrim(p_query) || '%')
    group by i.id, i.name, i.legal_name, i.slug, i.institution_type, i.description, i.stated_membership_count
  ), filtered as (
    select * from base
    where (p_min_onboards is null or imbop_onboards >= p_min_onboards)
      and (p_max_onboards is null or imbop_onboards <= p_max_onboards)
  )
  select f.*, count(*) over () total_count from filtered f
  order by lower(f.name) asc
  limit greatest(1, least(coalesce(p_limit, 24), 100))
  offset greatest(coalesce(p_offset, 0), 0);
$$;
revoke all on function public.search_public_institutions_by_initial(text,text,integer,integer,integer,integer) from public;
grant execute on function public.search_public_institutions_by_initial(text,text,integer,integer,integer,integer) to anon, authenticated;
