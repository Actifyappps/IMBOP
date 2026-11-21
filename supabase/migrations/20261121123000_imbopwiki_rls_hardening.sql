-- IMBOPwiki RLS hardening
-- Branch-only follow-up to the foundation migration.
-- DESIGN/IMPLEMENTATION ARTIFACT ONLY: not applied to production.

-- Private working groups are governed by community membership, not merely
-- institution membership. Institution-scoped content remains available to
-- active institution members when it is not community-scoped.
alter policy wiki_communities_scoped_read
on public.wiki_communities
using (
  private.has_platform_permission('platform_admin')
  or private.is_wiki_community_member(id)
  or (visibility = 'INSTITUTION' and institution_id is not null and private.is_institution_member(institution_id))
);

alter policy wiki_content_scoped_read
on public.wiki_content
using (
  private.has_platform_permission('platform_admin')
  or (community_id is not null and private.is_wiki_community_member(community_id))
  or (community_id is null and institution_id is not null and private.is_institution_member(institution_id))
  or (community_id is null and institution_id is null and created_by_user_id = (select auth.uid()))
);

alter policy wiki_content_versions_scoped_read
on public.wiki_content_versions
using (
  exists (
    select 1
    from public.wiki_content c
    where c.id = content_id
      and (
        private.has_platform_permission('platform_admin')
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
        or (c.community_id is null and c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is null and c.institution_id is null and c.created_by_user_id = (select auth.uid()))
      )
  )
);

alter policy wiki_content_topics_read
on public.wiki_content_topics
using (
  exists (
    select 1
    from public.wiki_content c
    where c.id = content_id
      and (
        (c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.published_version_id is not null and c.archived_at is null)
        or private.has_platform_permission('platform_admin')
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
        or (c.community_id is null and c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is null and c.institution_id is null and c.created_by_user_id = (select auth.uid()))
      )
  )
);

alter policy wiki_discussions_read
on public.wiki_discussions
using (
  (
    visibility = 'PUBLIC' and status = 'OPEN'
    and (
      exists (
        select 1 from public.wiki_content c
        where c.id = content_id and c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.archived_at is null
      )
      or exists (
        select 1 from public.wiki_communities c
        where c.id = community_id and c.visibility = 'PUBLIC' and c.status = 'ACTIVE'
      )
    )
  )
  or private.has_platform_permission('platform_admin')
  or (community_id is not null and private.is_wiki_community_member(community_id))
  or (community_id is null and institution_id is not null and private.is_institution_member(institution_id))
  or (community_id is null and institution_id is null and created_by_user_id = (select auth.uid()))
);

alter policy wiki_discussion_entries_read
on public.wiki_discussion_entries
using (
  status = 'ACTIVE'
  and exists (
    select 1 from public.wiki_discussions d
    where d.id = discussion_id
      and (
        (d.visibility = 'PUBLIC' and d.status = 'OPEN' and (
          exists (
            select 1 from public.wiki_content c
            where c.id = d.content_id and c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.archived_at is null
          )
          or exists (
            select 1 from public.wiki_communities c
            where c.id = d.community_id and c.visibility = 'PUBLIC' and c.status = 'ACTIVE'
          )
        ))
        or private.has_platform_permission('platform_admin')
        or (d.community_id is not null and private.is_wiki_community_member(d.community_id))
        or (d.community_id is null and d.institution_id is not null and private.is_institution_member(d.institution_id))
        or (d.community_id is null and d.institution_id is null and d.created_by_user_id = (select auth.uid()))
      )
  )
);

alter policy wiki_content_links_read
on public.wiki_content_links
using (
  exists (
    select 1
    from public.wiki_content c
    where c.id = content_id
      and (
        (c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.published_version_id is not null and c.archived_at is null)
        or private.has_platform_permission('platform_admin')
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
        or (c.community_id is null and c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is null and c.institution_id is null and c.created_by_user_id = (select auth.uid()))
      )
  )
  and (
    (target_type = 'WIKI_CONTENT' and exists (
      select 1 from public.wiki_content t
      where t.id = target_id
        and (
          (t.publication_state = 'PUBLISHED' and t.visibility = 'PUBLIC' and t.published_version_id is not null and t.archived_at is null)
          or private.has_platform_permission('platform_admin')
          or (t.community_id is not null and private.is_wiki_community_member(t.community_id))
          or (t.community_id is null and t.institution_id is not null and private.is_institution_member(t.institution_id))
          or (t.community_id is null and t.institution_id is null and t.created_by_user_id = (select auth.uid()))
        )
    ))
    or (target_type = 'COMMUNITY' and exists (
      select 1 from public.wiki_communities t
      where t.id = target_id
        and (
          (t.visibility = 'PUBLIC' and t.status = 'ACTIVE')
          or private.has_platform_permission('platform_admin')
          or private.is_wiki_community_member(t.id)
          or (t.visibility = 'INSTITUTION' and t.institution_id is not null and private.is_institution_member(t.institution_id))
        )
    ))
    or (target_type = 'INSTITUTION' and exists (
      select 1 from public.institutions t where t.id = target_id
    ))
    or (target_type = 'BUSINESS' and exists (
      select 1 from public.businesses t where t.id = target_id
    ))
    or (target_type = 'BUSINESS_PROFILE' and exists (
      select 1 from public.business_profiles t where t.id = target_id
    ))
    or (target_type = 'MARKET_ITEM' and exists (
      select 1 from public.market_items t where t.id = target_id
    ))
    or (target_type = 'OPPORTUNITY' and exists (
      select 1 from public.opportunities t where t.id = target_id
    ))
    or (target_type = 'ENQUIRY' and exists (
      select 1 from public.enquiries t where t.id = target_id
    ))
    or (target_type = 'INTRODUCTION' and exists (
      select 1 from public.introductions t where t.id = target_id
    ))
  )
);

-- Community-scoped content creation/versioning must use the community
-- authorization boundary rather than institution membership as a bypass.
alter policy wiki_content_insert
on public.wiki_content
with check (
  created_by_user_id = (select auth.uid())
  and (
    private.has_platform_permission('platform_admin')
    or (community_id is not null and private.is_wiki_community_member(community_id))
    or (community_id is null and institution_id is not null and private.is_institution_member(institution_id))
    or (community_id is null and institution_id is null and private.has_platform_permission('platform_admin'))
  )
);

alter policy wiki_content_versions_insert
on public.wiki_content_versions
with check (
  created_by_user_id = (select auth.uid())
  and exists (
    select 1 from public.wiki_content c
    where c.id = content_id
      and (
        private.has_platform_permission('platform_admin')
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
        or (c.community_id is null and c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is null and c.institution_id is null and private.has_platform_permission('platform_admin'))
      )
  )
);
