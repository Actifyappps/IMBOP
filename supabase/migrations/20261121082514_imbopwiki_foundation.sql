-- IMBOPwiki foundation
-- Generated for branch feature/imbopwiki-foundation.
-- DESIGN/IMPLEMENTATION ARTIFACT ONLY: not applied to production.

create table public.wiki_spaces (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid references public.institutions(id) on delete cascade,
  name text not null,
  slug text not null,
  description text,
  visibility text not null default 'INSTITUTION' check (visibility in ('PRIVATE','INSTITUTION','PUBLIC')),
  status text not null default 'DRAFT' check (status in ('DRAFT','ACTIVE','PAUSED','ARCHIVED')),
  governance_owner_user_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index wiki_spaces_global_slug_uq on public.wiki_spaces (slug) where institution_id is null;
create unique index wiki_spaces_institution_slug_uq on public.wiki_spaces (institution_id, slug) where institution_id is not null;
create index wiki_spaces_institution_idx on public.wiki_spaces (institution_id);

create table public.wiki_communities (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.wiki_spaces(id) on delete cascade,
  institution_id uuid references public.institutions(id) on delete cascade,
  name text not null,
  slug text not null,
  description text,
  membership_policy text not null default 'OPEN' check (membership_policy in ('OPEN','APPROVAL','INVITE_ONLY')),
  visibility text not null default 'INSTITUTION' check (visibility in ('PRIVATE','INSTITUTION','PUBLIC')),
  status text not null default 'DRAFT' check (status in ('DRAFT','ACTIVE','PAUSED','ARCHIVED')),
  owner_user_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index wiki_communities_space_slug_uq on public.wiki_communities (space_id, slug);
create index wiki_communities_institution_idx on public.wiki_communities (institution_id);
create index wiki_communities_status_visibility_idx on public.wiki_communities (status, visibility);

create table public.wiki_community_memberships (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.wiki_communities(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  institution_id uuid references public.institutions(id) on delete set null,
  role text not null default 'MEMBER' check (role in ('MEMBER','CONTRIBUTOR','MODERATOR','OWNER')),
  status text not null default 'PENDING' check (status in ('PENDING','ACTIVE','SUSPENDED','REVOKED')),
  joined_at timestamptz,
  approved_at timestamptz,
  approved_by_user_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (community_id, user_id)
);

create index wiki_community_memberships_user_idx on public.wiki_community_memberships (user_id, status);
create index wiki_community_memberships_community_idx on public.wiki_community_memberships (community_id, status);

create table public.wiki_topics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','ARCHIVED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wiki_content (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.wiki_spaces(id) on delete restrict,
  community_id uuid references public.wiki_communities(id) on delete set null,
  institution_id uuid references public.institutions(id) on delete set null,
  created_by_user_id uuid not null references auth.users(id),
  content_type text not null check (content_type in ('ARTICLE','OPPORTUNITY','QUESTION','RESOURCE','ANNOUNCEMENT','EVENT')),
  title text not null,
  slug text not null,
  summary text,
  current_version_id uuid,
  published_version_id uuid,
  publication_state text not null default 'DRAFT' check (publication_state in ('DRAFT','SUBMITTED','PENDING_REVIEW','PUBLISHED','RETURNED','REJECTED','UNPUBLISHED','ARCHIVED')),
  visibility text not null default 'PRIVATE' check (visibility in ('PRIVATE','INSTITUTION','PUBLIC')),
  published_at timestamptz,
  published_by_user_id uuid references auth.users(id),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index wiki_content_institution_idx on public.wiki_content (institution_id, publication_state, visibility);
create index wiki_content_community_idx on public.wiki_content (community_id, publication_state, visibility);
create index wiki_content_creator_idx on public.wiki_content (created_by_user_id, publication_state);
create unique index wiki_content_space_slug_uq on public.wiki_content (space_id, slug);

create table public.wiki_content_versions (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.wiki_content(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  created_by_user_id uuid not null references auth.users(id),
  title text not null,
  summary text,
  body text not null,
  change_reason text,
  created_at timestamptz not null default now(),
  unique (content_id, version_number),
  unique (id, content_id)
);

alter table public.wiki_content
  add constraint wiki_content_current_version_fk
  foreign key (current_version_id, id)
  references public.wiki_content_versions (id, content_id)
  deferrable initially deferred;

alter table public.wiki_content
  add constraint wiki_content_published_version_fk
  foreign key (published_version_id, id)
  references public.wiki_content_versions (id, content_id)
  deferrable initially deferred;

create index wiki_content_versions_content_idx on public.wiki_content_versions (content_id, version_number desc);
create index wiki_content_versions_creator_idx on public.wiki_content_versions (created_by_user_id);

create table public.wiki_content_topics (
  content_id uuid not null references public.wiki_content(id) on delete cascade,
  topic_id uuid not null references public.wiki_topics(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (content_id, topic_id)
);

create table public.wiki_discussions (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.wiki_spaces(id) on delete cascade,
  community_id uuid references public.wiki_communities(id) on delete cascade,
  content_id uuid references public.wiki_content(id) on delete cascade,
  institution_id uuid references public.institutions(id) on delete set null,
  created_by_user_id uuid not null references auth.users(id),
  title text not null,
  status text not null default 'OPEN' check (status in ('OPEN','LOCKED','ARCHIVED','REMOVED')),
  visibility text not null default 'INSTITUTION' check (visibility in ('PRIVATE','INSTITUTION','PUBLIC')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wiki_discussions_parent_ck check (community_id is not null or content_id is not null)
);

create index wiki_discussions_community_idx on public.wiki_discussions (community_id, status);
create index wiki_discussions_content_idx on public.wiki_discussions (content_id, status);
create index wiki_discussions_institution_idx on public.wiki_discussions (institution_id, status);

create table public.wiki_discussion_entries (
  id uuid primary key default gen_random_uuid(),
  discussion_id uuid not null references public.wiki_discussions(id) on delete cascade,
  author_user_id uuid not null references auth.users(id),
  body text not null,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','HIDDEN','REMOVED')),
  edited_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index wiki_discussion_entries_discussion_idx on public.wiki_discussion_entries (discussion_id, status, created_at);
create index wiki_discussion_entries_author_idx on public.wiki_discussion_entries (author_user_id);

create table public.wiki_content_links (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.wiki_content(id) on delete cascade,
  target_type text not null check (target_type in ('WIKI_CONTENT','INSTITUTION','BUSINESS','BUSINESS_PROFILE','MARKET_ITEM','OPPORTUNITY','ENQUIRY','INTRODUCTION','COMMUNITY')),
  target_id uuid not null,
  relationship_type text not null,
  created_by_user_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  unique (content_id, target_type, target_id, relationship_type)
);

create index wiki_content_links_target_idx on public.wiki_content_links (target_type, target_id);
create index wiki_content_links_content_idx on public.wiki_content_links (content_id);

create or replace function private.wiki_link_target_allowed(p_content_id uuid, p_target_type text, p_target_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $function$
  select case p_target_type
    when 'WIKI_CONTENT' then exists (select 1 from public.wiki_content t join public.wiki_content s on s.id = p_content_id where t.id = p_target_id and (s.institution_id is null or t.institution_id is null or s.institution_id = t.institution_id))
    when 'INSTITUTION' then exists (select 1 from public.wiki_content s where s.id = p_content_id and exists (select 1 from public.institutions t where t.id = p_target_id) and (s.institution_id is null or s.institution_id = p_target_id))
    when 'BUSINESS' then exists (select 1 from public.wiki_content s join public.businesses t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or s.institution_id = t.institution_id))
    when 'BUSINESS_PROFILE' then exists (select 1 from public.wiki_content s join public.business_profiles t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or s.institution_id = t.institution_id))
    when 'MARKET_ITEM' then exists (select 1 from public.wiki_content s join public.market_items t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or s.institution_id = t.institution_id))
    when 'OPPORTUNITY' then exists (select 1 from public.wiki_content s join public.opportunities t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or s.institution_id = t.institution_id))
    when 'ENQUIRY' then exists (select 1 from public.wiki_content s join public.enquiries t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or s.institution_id = t.institution_id))
    when 'INTRODUCTION' then exists (select 1 from public.wiki_content s join public.introductions t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or s.institution_id = t.institution_id))
    when 'COMMUNITY' then exists (select 1 from public.wiki_content s join public.wiki_communities t on t.id = p_target_id where s.id = p_content_id and (s.institution_id is null or t.institution_id is null or s.institution_id = t.institution_id))
    else false
  end;
$function$;

revoke all on function private.wiki_link_target_allowed(uuid,text,uuid) from public, anon;
grant execute on function private.wiki_link_target_allowed(uuid,text,uuid) to authenticated;

create table public.wiki_content_reviews (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.wiki_content(id) on delete cascade,
  action text not null check (action in ('SUBMIT','START_REVIEW','PUBLISH','RETURN','REJECT','UNPUBLISH','ARCHIVE')),
  from_state text not null,
  to_state text not null,
  reviewer_user_id uuid not null references auth.users(id),
  notes text,
  created_at timestamptz not null default now()
);

create index wiki_content_reviews_content_idx on public.wiki_content_reviews (content_id, created_at desc);
create index wiki_content_reviews_reviewer_idx on public.wiki_content_reviews (reviewer_user_id, created_at desc);

create or replace function private.is_wiki_community_member(p_community_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.wiki_community_memberships m
    join public.wiki_communities c on c.id = m.community_id
    where m.community_id = p_community_id
      and m.user_id = (select auth.uid())
      and m.status = 'ACTIVE'
      and c.status = 'ACTIVE'
  );
$$;

create or replace function private.is_wiki_community_owner(p_community_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.wiki_community_memberships m
    where m.community_id = p_community_id
      and m.user_id = (select auth.uid())
      and m.status = 'ACTIVE'
      and m.role = 'OWNER'
  )
  or exists (
    select 1
    from public.wiki_communities c
    where c.id = p_community_id
      and c.owner_user_id = (select auth.uid())
  )
  or private.has_platform_permission('platform_admin');
$$;

revoke all on function private.is_wiki_community_owner(uuid) from public, anon;
grant execute on function private.is_wiki_community_owner(uuid) to authenticated;

create or replace function private.is_wiki_community_manager(p_community_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.wiki_community_memberships m
    where m.community_id = p_community_id
      and m.user_id = (select auth.uid())
      and m.status = 'ACTIVE'
      and m.role in ('MODERATOR','OWNER')
  )
  or exists (
    select 1
    from public.wiki_communities c
    where c.id = p_community_id
      and private.has_platform_permission('platform_admin')
  );
$$;

revoke all on function private.is_wiki_community_member(uuid) from public, anon;
revoke all on function private.is_wiki_community_manager(uuid) from public, anon;
grant execute on function private.is_wiki_community_member(uuid) to authenticated;
grant execute on function private.is_wiki_community_manager(uuid) to authenticated;

alter table public.wiki_spaces enable row level security;
alter table public.wiki_communities enable row level security;
alter table public.wiki_community_memberships enable row level security;
alter table public.wiki_topics enable row level security;
alter table public.wiki_content enable row level security;
alter table public.wiki_content_versions enable row level security;
alter table public.wiki_content_topics enable row level security;
alter table public.wiki_discussions enable row level security;
alter table public.wiki_discussion_entries enable row level security;
alter table public.wiki_content_links enable row level security;
alter table public.wiki_content_reviews enable row level security;

revoke all on table public.wiki_spaces, public.wiki_communities, public.wiki_community_memberships,
  public.wiki_topics, public.wiki_content, public.wiki_content_versions, public.wiki_content_topics,
  public.wiki_discussions, public.wiki_discussion_entries, public.wiki_content_links, public.wiki_content_reviews
from anon;

grant select on public.wiki_spaces, public.wiki_communities, public.wiki_topics, public.wiki_content,
  public.wiki_content_versions, public.wiki_content_topics, public.wiki_discussions, public.wiki_discussion_entries,
  public.wiki_content_links to anon;

grant select, insert, update, delete on public.wiki_spaces, public.wiki_communities, public.wiki_community_memberships,
  public.wiki_topics, public.wiki_content, public.wiki_content_versions, public.wiki_content_topics,
  public.wiki_discussions, public.wiki_discussion_entries, public.wiki_content_links, public.wiki_content_reviews
to authenticated;

create policy wiki_spaces_public_read on public.wiki_spaces for select to anon, authenticated
using (visibility = 'PUBLIC' and status = 'ACTIVE');

create policy wiki_spaces_scoped_read on public.wiki_spaces for select to authenticated
using (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.is_institution_member(institution_id))
  or (governance_owner_user_id = (select auth.uid()))
);

create policy wiki_spaces_manage on public.wiki_spaces for all to authenticated
using (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
)
with check (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
);

create policy wiki_communities_public_read on public.wiki_communities for select to anon, authenticated
using (visibility = 'PUBLIC' and status = 'ACTIVE');

create policy wiki_communities_scoped_read on public.wiki_communities for select to authenticated
using (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.is_institution_member(institution_id))
  or private.is_wiki_community_member(id)
);

create policy wiki_communities_insert on public.wiki_communities for insert to authenticated
with check (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
);

create policy wiki_communities_update on public.wiki_communities for update to authenticated
using (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
)
with check (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
);

create policy wiki_communities_delete_platform_only on public.wiki_communities for delete to authenticated
using (private.has_platform_permission('platform_admin'));

create policy wiki_community_memberships_read on public.wiki_community_memberships for select to authenticated
using (
  user_id = (select auth.uid())
  or private.has_platform_permission('platform_admin')
  or private.is_wiki_community_manager(community_id)
);

create policy wiki_community_memberships_manage on public.wiki_community_memberships for all to authenticated
using (
  private.has_platform_permission('platform_admin')
  or private.is_wiki_community_manager(community_id)
)
with check (
  private.has_platform_permission('platform_admin')
  or (
    private.is_wiki_community_manager(community_id)
    and (
      role in ('MEMBER','CONTRIBUTOR')
      or (
        role = 'MODERATOR'
        and (
          private.is_wiki_community_owner(community_id)
          or exists (
            select 1
            from public.wiki_community_memberships me
            where me.community_id = community_id
              and me.user_id = (select auth.uid())
              and me.status = 'ACTIVE'
              and me.role = 'OWNER'
          )
        )
      )
      or (
        role = 'OWNER'
        and private.is_wiki_community_owner(community_id)
      )
    )
  )
);

create policy wiki_topics_public_read on public.wiki_topics for select to anon, authenticated
using (status = 'ACTIVE');

create policy wiki_topics_manage on public.wiki_topics for all to authenticated
using (private.has_platform_permission('platform_admin'))
with check (private.has_platform_permission('platform_admin'));

create policy wiki_content_public_read on public.wiki_content for select to anon, authenticated
using (
  publication_state = 'PUBLISHED'
  and visibility = 'PUBLIC'
  and published_version_id is not null
  and archived_at is null
);

create policy wiki_content_scoped_read on public.wiki_content for select to authenticated
using (
  private.has_platform_permission('platform_admin')
  or created_by_user_id = (select auth.uid())
  or (institution_id is not null and private.is_institution_member(institution_id))
  or (community_id is not null and private.is_wiki_community_member(community_id))
);

create policy wiki_content_insert on public.wiki_content for insert to authenticated
with check (
  created_by_user_id = (select auth.uid())
  and (
    private.has_platform_permission('platform_admin')
    or (institution_id is not null and private.is_institution_member(institution_id))
    or (community_id is not null and private.is_wiki_community_member(community_id))
  )
);

create policy wiki_content_reviewer_update on public.wiki_content for update to authenticated
using (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
)
with check (
  private.has_platform_permission('platform_admin')
  or (institution_id is not null and private.has_institution_permission(institution_id,'publication_manage'))
);

create policy wiki_content_versions_public_read on public.wiki_content_versions for select to anon, authenticated
using (
  exists (
    select 1 from public.wiki_content c
    where c.id = content_id
      and c.publication_state = 'PUBLISHED'
      and c.visibility = 'PUBLIC'
      and c.published_version_id = id
      and c.archived_at is null
  )
);

create policy wiki_content_versions_scoped_read on public.wiki_content_versions for select to authenticated
using (
  exists (
    select 1 from public.wiki_content c
    where c.id = content_id
      and (
        private.has_platform_permission('platform_admin')
        or c.created_by_user_id = (select auth.uid())
        or (c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
      )
  )
);

create policy wiki_content_versions_insert on public.wiki_content_versions for insert to authenticated
with check (
  created_by_user_id = (select auth.uid())
  and exists (
    select 1 from public.wiki_content c
    where c.id = content_id
      and (
        private.has_platform_permission('platform_admin')
        or (c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
      )
  )
);

create policy wiki_content_topics_read on public.wiki_content_topics for select to anon, authenticated
using (
  exists (select 1 from public.wiki_content c where c.id = content_id and c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.archived_at is null)
  or exists (select 1 from public.wiki_content c where c.id = content_id and (private.has_platform_permission('platform_admin') or (c.institution_id is not null and private.is_institution_member(c.institution_id)) or (c.community_id is not null and private.is_wiki_community_member(c.community_id))))
);

create policy wiki_content_topics_manage on public.wiki_content_topics for all to authenticated
using (
  exists (select 1 from public.wiki_content c where c.id = content_id and (private.has_platform_permission('platform_admin') or c.created_by_user_id = (select auth.uid())))
)
with check (
  exists (select 1 from public.wiki_content c where c.id = content_id and (private.has_platform_permission('platform_admin') or c.created_by_user_id = (select auth.uid())))
);

create policy wiki_discussions_read on public.wiki_discussions for select to anon, authenticated
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
  or (institution_id is not null and private.is_institution_member(institution_id))
  or (community_id is not null and private.is_wiki_community_member(community_id))
  or created_by_user_id = (select auth.uid())
);

create policy wiki_discussions_insert on public.wiki_discussions for insert to authenticated
with check (
  created_by_user_id = (select auth.uid())
  and (
    private.has_platform_permission('platform_admin')
    or (institution_id is not null and private.is_institution_member(institution_id))
    or (community_id is not null and private.is_wiki_community_member(community_id))
  )
);

create policy wiki_discussions_manage on public.wiki_discussions for update to authenticated
using (
  private.has_platform_permission('platform_admin')
  or created_by_user_id = (select auth.uid())
  or (community_id is not null and private.is_wiki_community_manager(community_id))
)
with check (
  private.has_platform_permission('platform_admin')
  or created_by_user_id = (select auth.uid())
  or (community_id is not null and private.is_wiki_community_manager(community_id))
);

create policy wiki_discussion_entries_read on public.wiki_discussion_entries for select to anon, authenticated
using (
  status = 'ACTIVE'
  and exists (
    select 1 from public.wiki_discussions d
    where d.id = discussion_id
      and (
        (d.visibility = 'PUBLIC' and d.status = 'OPEN' and exists (
          select 1 from public.wiki_content c
          where c.id = d.content_id and c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.archived_at is null
        ))
        or private.has_platform_permission('platform_admin')
        or (d.institution_id is not null and private.is_institution_member(d.institution_id))
        or (d.community_id is not null and private.is_wiki_community_member(d.community_id))
      )
  )
);

create policy wiki_discussion_entries_insert on public.wiki_discussion_entries for insert to authenticated
with check (
  author_user_id = (select auth.uid())
  and exists (
    select 1 from public.wiki_discussions d
    where d.id = discussion_id
      and d.status = 'OPEN'
      and (
        private.has_platform_permission('platform_admin')
        or (d.institution_id is not null and private.is_institution_member(d.institution_id))
        or (d.community_id is not null and private.is_wiki_community_member(d.community_id))
      )
  )
);

create policy wiki_discussion_entries_update on public.wiki_discussion_entries for update to authenticated
using (
  author_user_id = (select auth.uid())
  or exists (select 1 from public.wiki_discussions d where d.id = discussion_id and (private.has_platform_permission('platform_admin') or (d.community_id is not null and private.is_wiki_community_manager(d.community_id))))
)
with check (
  author_user_id = (select auth.uid())
  or exists (select 1 from public.wiki_discussions d where d.id = discussion_id and (private.has_platform_permission('platform_admin') or (d.community_id is not null and private.is_wiki_community_manager(d.community_id))))
);

create policy wiki_content_links_read on public.wiki_content_links for select to anon, authenticated
using (
  exists (
    select 1 from public.wiki_content c
    where c.id = content_id
      and (
        (c.publication_state = 'PUBLISHED' and c.visibility = 'PUBLIC' and c.published_version_id is not null and c.archived_at is null)
        or private.has_platform_permission('platform_admin')
        or (c.institution_id is not null and private.is_institution_member(c.institution_id))
        or (c.community_id is not null and private.is_wiki_community_member(c.community_id))
      )
  )
  and (
    target_type = 'WIKI_CONTENT' and exists (
      select 1 from public.wiki_content t
      where t.id = target_id
        and t.publication_state = 'PUBLISHED'
        and t.visibility = 'PUBLIC'
        and t.published_version_id is not null
        and t.archived_at is null
    )
    or target_type = 'COMMUNITY' and exists (
      select 1 from public.wiki_communities t
      where t.id = target_id
        and t.status = 'ACTIVE'
        and t.visibility = 'PUBLIC'
    )
    or target_type = 'INSTITUTION' and exists (
      select 1 from public.institutions t
      where t.id = target_id
    )
    or target_type not in ('WIKI_CONTENT','COMMUNITY','INSTITUTION')
  )
);

create policy wiki_content_links_insert on public.wiki_content_links for insert to authenticated
with check (
  (
    private.has_platform_permission('platform_admin')
    or exists (select 1 from public.wiki_content c where c.id = content_id and c.created_by_user_id = (select auth.uid()))
  )
  and private.wiki_link_target_allowed(content_id, target_type, target_id)
);

create policy wiki_content_links_delete on public.wiki_content_links for delete to authenticated
using (
  private.has_platform_permission('platform_admin')
  or exists (select 1 from public.wiki_content c where c.id = content_id and c.created_by_user_id = (select auth.uid()))
);

create policy wiki_content_reviews_read on public.wiki_content_reviews for select to authenticated
using (
  private.has_platform_permission('platform_admin')
  or (exists (select 1 from public.wiki_content c where c.id = content_id and c.institution_id is not null and private.has_institution_permission(c.institution_id,'publication_manage')))
);

create policy wiki_content_reviews_insert on public.wiki_content_reviews for insert to authenticated
with check (
  private.has_platform_permission('platform_admin')
  or (exists (select 1 from public.wiki_content c where c.id = content_id and c.institution_id is not null and private.has_institution_permission(c.institution_id,'publication_manage')))
);

comment on table public.wiki_spaces is 'IMBOPwiki organizational/presentation context; never an authorization boundary.';
comment on table public.wiki_content is 'IMBOPwiki durable knowledge identity. current_version_id is working; published_version_id is authorized publication.';
comment on table public.wiki_content_links is 'References do not grant authorization to target objects.';
comment on table public.wiki_content_reviews is 'Attributable wiki publication/review evidence.';


-- IMBOPwiki governance RPCs.
-- These functions keep publication transitions attributable and prevent direct state
-- mutation from bypassing the governed lifecycle. Working versions are immutable;
-- publication always points to an explicit version.

create or replace function public.wiki_create_version(
  p_content_id uuid,
  p_title text,
  p_body text,
  p_summary text default null,
  p_change_reason text default null
)
returns public.wiki_content_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_content public.wiki_content;
  v_version public.wiki_content_versions;
  v_next integer;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  select * into v_content from public.wiki_content where id = p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if v_content.created_by_user_id <> (select auth.uid())
     and not private.has_platform_permission('platform_admin')
     and not (v_content.institution_id is not null and private.has_institution_permission(v_content.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if v_content.publication_state = 'ARCHIVED' then raise exception 'Archived content cannot be edited'; end if;

  select coalesce(max(version_number),0)+1 into v_next
  from public.wiki_content_versions where content_id = p_content_id;

  insert into public.wiki_content_versions(content_id,version_number,created_by_user_id,title,summary,body,change_reason)
  values(p_content_id,v_next,(select auth.uid()),p_title,p_summary,p_body,p_change_reason)
  returning * into v_version;

  update public.wiki_content
     set current_version_id = v_version.id,
         updated_at = now()
   where id = p_content_id;

  return v_version;
end $$;

create or replace function public.wiki_submit(p_content_id uuid)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if r.created_by_user_id <> (select auth.uid())
     and not private.has_platform_permission('platform_admin')
  then raise exception 'Not authorized'; end if;
  if r.current_version_id is null then raise exception 'A working version is required'; end if;
  if r.publication_state = 'PUBLISHED' and r.current_version_id = r.published_version_id then
    raise exception 'No unpublished working changes are waiting for review';
  end if;
  if r.publication_state not in ('DRAFT','RETURNED','UNPUBLISHED','PUBLISHED') then
    raise exception 'Content cannot be submitted from its current state';
  end if;
  update public.wiki_content set publication_state='SUBMITTED', updated_at=now() where id=p_content_id returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id)
  values(p_content_id,'SUBMIT',r.publication_state,'SUBMITTED',(select auth.uid()));
  return r;
end $$;

create or replace function public.wiki_start_review(p_content_id uuid)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content; v_from text;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if not private.has_platform_permission('platform_admin')
     and not (r.institution_id is not null and private.has_institution_permission(r.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if r.publication_state <> 'SUBMITTED' then raise exception 'Content is not awaiting review'; end if;
  v_from:=r.publication_state;
  update public.wiki_content set publication_state='PENDING_REVIEW', updated_at=now() where id=p_content_id returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id)
  values(p_content_id,'START_REVIEW',v_from,'PENDING_REVIEW',(select auth.uid()));
  return r;
end $$;

create or replace function public.wiki_publish(p_content_id uuid, p_notes text default null)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content; v_from text;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if not private.has_platform_permission('platform_admin')
     and not (r.institution_id is not null and private.has_institution_permission(r.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if r.publication_state not in ('SUBMITTED','PENDING_REVIEW') then raise exception 'Content is not ready to publish'; end if;
  if r.current_version_id is null then raise exception 'A working version is required'; end if;
  v_from:=r.publication_state;
  update public.wiki_content
     set publication_state='PUBLISHED',
         visibility='PUBLIC',
         published_version_id=current_version_id,
         published_at=now(),
         published_by_user_id=(select auth.uid()),
         updated_at=now()
   where id=p_content_id
   returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id,notes)
  values(p_content_id,'PUBLISH',v_from,'PUBLISHED',(select auth.uid()),p_notes);
  return r;
end $$;

create or replace function public.wiki_return(p_content_id uuid, p_notes text)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content; v_from text;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  if nullif(trim(p_notes),'') is null then raise exception 'A return reason is required'; end if;
  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if not private.has_platform_permission('platform_admin')
     and not (r.institution_id is not null and private.has_institution_permission(r.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if r.publication_state <> 'PENDING_REVIEW' then raise exception 'Content is not in review'; end if;
  v_from:=r.publication_state;
  update public.wiki_content set publication_state='RETURNED', updated_at=now() where id=p_content_id returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id,notes)
  values(p_content_id,'RETURN',v_from,'RETURNED',(select auth.uid()),p_notes);
  return r;
end $$;

create or replace function public.wiki_reject(p_content_id uuid, p_notes text)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content; v_from text;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  if nullif(trim(p_notes),'') is null then raise exception 'A rejection reason is required'; end if;
  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if not private.has_platform_permission('platform_admin')
     and not (r.institution_id is not null and private.has_institution_permission(r.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if r.publication_state <> 'PENDING_REVIEW' then raise exception 'Content is not in review'; end if;
  v_from:=r.publication_state;
  update public.wiki_content set publication_state='REJECTED', updated_at=now() where id=p_content_id returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id,notes)
  values(p_content_id,'REJECT',v_from,'REJECTED',(select auth.uid()),p_notes);
  return r;
end $$;

create or replace function public.wiki_unpublish(p_content_id uuid, p_notes text default null)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content; v_from text;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if not private.has_platform_permission('platform_admin')
     and not (r.institution_id is not null and private.has_institution_permission(r.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if r.publication_state <> 'PUBLISHED' then raise exception 'Content is not published'; end if;
  v_from:=r.publication_state;
  update public.wiki_content
     set publication_state='UNPUBLISHED', visibility='PRIVATE', published_version_id=null, updated_at=now()
   where id=p_content_id returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id,notes)
  values(p_content_id,'UNPUBLISH',v_from,'UNPUBLISHED',(select auth.uid()),p_notes);
  return r;
end $$;

create or replace function public.wiki_archive(p_content_id uuid, p_notes text default null)
returns public.wiki_content
language plpgsql security definer set search_path = ''
as $$
declare r public.wiki_content; v_from text;
begin

  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;  select * into r from public.wiki_content where id=p_content_id for update;
  if not found then raise exception 'Wiki content not found'; end if;
  if not private.has_platform_permission('platform_admin')
     and not (r.institution_id is not null and private.has_institution_permission(r.institution_id,'publication_manage'))
  then raise exception 'Not authorized'; end if;
  if r.publication_state='ARCHIVED' then return r; end if;
  v_from:=r.publication_state;
  update public.wiki_content set publication_state='ARCHIVED', archived_at=now(), published_version_id=null, updated_at=now() where id=p_content_id returning * into r;
  insert into public.wiki_content_reviews(content_id,action,from_state,to_state,reviewer_user_id,notes)
  values(p_content_id,'ARCHIVE',v_from,'ARCHIVED',(select auth.uid()),p_notes);
  return r;
end $$;

revoke all on function public.wiki_create_version(uuid,text,text,text,text),
  public.wiki_submit(uuid),
  public.wiki_start_review(uuid),
  public.wiki_publish(uuid,text),
  public.wiki_return(uuid,text),
  public.wiki_reject(uuid,text),
  public.wiki_unpublish(uuid,text),
  public.wiki_archive(uuid,text)
from public, anon;

grant execute on function public.wiki_create_version(uuid,text,text,text,text),
  public.wiki_submit(uuid),
  public.wiki_start_review(uuid),
  public.wiki_publish(uuid,text),
  public.wiki_return(uuid,text),
  public.wiki_reject(uuid,text),
  public.wiki_unpublish(uuid,text),
  public.wiki_archive(uuid,text)
to authenticated;

-- Governance hardening: direct clients may not bypass publication state transitions.
-- Do not grant table-wide UPDATE to authenticated clients; expose only ordinary editable metadata.
revoke update on public.wiki_content from authenticated;
grant update (title, slug, summary) on public.wiki_content to authenticated;
