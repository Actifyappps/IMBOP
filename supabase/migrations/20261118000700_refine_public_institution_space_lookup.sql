-- Refine public institution discovery so direct institution-space routes
-- resolve by exact slug instead of scanning the first discovery page.

create or replace function private.search_public_institutions(
  p_query text default null, p_min_onboards integer default null, p_max_onboards integer default null,
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
      and (nullif(btrim(p_query), '') is null
        or i.slug = btrim(p_query)
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
  order by f.imbop_onboards desc, lower(f.name) asc
  limit greatest(1, least(coalesce(p_limit, 24), 100))
  offset greatest(coalesce(p_offset, 0), 0);
$$;

create index if not exists institutions_public_discovery_slug_idx
  on public.institutions (slug)
  where status='active' and deleted_at is null;
