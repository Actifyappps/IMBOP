-- IMBOPwiki RLS adversarial test specification.
-- Requires the Supabase test-helper package in the local test environment.
-- This file is intentionally not executed against production.
--
-- The suite is designed for the branch migration stack. It deliberately
-- exercises direct table access, governed RPCs, scope changes, and revoked
-- community membership.

begin;

select plan(23);

select tests.create_supabase_user('imbopwiki-a@test.invalid');
select tests.create_supabase_user('imbopwiki-b@test.invalid');

select tests.authenticate_as_service_role();

do $$
declare
  u_a uuid := tests.get_supabase_uid('imbopwiki-a@test.invalid');
  u_b uuid := tests.get_supabase_uid('imbopwiki-b@test.invalid');
  inst_a uuid := gen_random_uuid();
  inst_b uuid := gen_random_uuid();
  space_a uuid := gen_random_uuid();
  space_b uuid := gen_random_uuid();
  public_content uuid := gen_random_uuid();
  public_v1 uuid := gen_random_uuid();
  draft_content uuid := gen_random_uuid();
  draft_v1 uuid := gen_random_uuid();
  community_content uuid := gen_random_uuid();
  community_v1 uuid := gen_random_uuid();
  community_a uuid := gen_random_uuid();
  membership_b uuid := gen_random_uuid();
begin
  insert into public.institutions(id,name,slug,status)
  values
    (inst_a,'IMBOPwiki Test Institution A','imbopwiki-test-a','pending'),
    (inst_b,'IMBOPwiki Test Institution B','imbopwiki-test-b','pending');

  insert into public.wiki_spaces(id,institution_id,name,slug,status,visibility,governance_owner_user_id)
  values
    (space_a,inst_a,'Test Space A','imbopwiki-test-space-a','ACTIVE','INSTITUTION',u_a),
    (space_b,inst_b,'Test Space B','imbopwiki-test-space-b','ACTIVE','INSTITUTION',u_b);

  insert into public.wiki_content(
    id,space_id,institution_id,created_by_user_id,content_type,title,slug,
    publication_state,visibility,current_version_id,published_version_id
  )
  values
    (public_content,space_a,inst_a,u_a,'ARTICLE','Public Test','imbopwiki-public-test',
     'PUBLISHED','PUBLIC',public_v1,public_v1),
    (draft_content,space_a,null,null,u_a,'ARTICLE','Draft Test','imbopwiki-draft-test',
     'DRAFT','PRIVATE',draft_v1,null),
    (community_content,space_a,community_a,inst_a,u_b,'ARTICLE','Community Draft','imbopwiki-community-draft',
     'DRAFT','PRIVATE',community_v1,null);

  insert into public.wiki_communities(id,space_id,institution_id,name,slug,status,visibility,owner_user_id)
  values (community_a,space_a,inst_a,'Test Community A','imbopwiki-test-community-a','ACTIVE','PRIVATE',u_a);

  insert into public.wiki_community_memberships(id,community_id,user_id,institution_id,role,status,joined_at,approved_at,approved_by_user_id)
  values (membership_b,community_a,u_b,inst_a,'MEMBER','ACTIVE',now(),now(),u_a);

  insert into public.wiki_content_versions(id,content_id,version_number,created_by_user_id,title,body)
  values
    (public_v1,public_content,1,u_a,'Public Test','Version 1'),
    (draft_v1,draft_content,1,u_a,'Draft Test','Private draft'),
    (community_v1,community_content,1,u_b,'Community Draft','Private community draft');

  perform set_config('request.jwt.claim.sub',u_b::text,true);
end $$;

select tests.authenticate_as('imbopwiki-a@test.invalid');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-public-test'),1,'owner can read public content');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-draft-test'),1,'author can read own global draft');

select tests.authenticate_as('imbopwiki-b@test.invalid');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-draft-test'),0,'cross-tenant user cannot read draft by direct id');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-public-test'),1,'public published content remains discoverable');

select ok((select tests.rls_enabled('public.wiki_content')), 'wiki_content has RLS');
select ok((select tests.rls_enabled('public.wiki_content_versions')), 'wiki_content_versions has RLS');
select ok((select tests.rls_enabled('public.wiki_communities')), 'wiki_communities has RLS');

select is((select count(*)::int from public.wiki_communities where slug='imbopwiki-test-community-a'),1,'active community member can read private community');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-community-draft'),1,'active community member can read private community content');

select tests.authenticate_as_service_role();
update public.wiki_community_memberships
   set status='REVOKED'
 where id=(select id from public.wiki_community_memberships where user_id=tests.get_supabase_uid('imbopwiki-b@test.invalid'));

select tests.authenticate_as('imbopwiki-b@test.invalid');
select is((select count(*)::int from public.wiki_communities where slug='imbopwiki-test-community-a'),0,'revoked community member loses private community access');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-community-draft'),0,'revoked community membership cannot expose private community content');
select is((select count(*)::int from public.wiki_content_versions v join public.wiki_content c on c.id=v.content_id where c.slug='imbopwiki-draft-test'),0,'revoked member cannot read private version history');

select tests.authenticate_as('imbopwiki-a@test.invalid');
select is((select count(*)::int from public.wiki_content_versions v join public.wiki_content c on c.id=v.content_id where c.slug='imbopwiki-public-test' and v.id=c.published_version_id),1,'published version is the public version');

select is(
  (select count(*)::int from public.wiki_content where slug='imbopwiki-public-test' and current_version_id=published_version_id),
  1,
  'working version initially equals published version'
);

select tests.authenticate_as_service_role();
update public.wiki_content
   set visibility='PRIVATE', publication_state='UNPUBLISHED', published_version_id=null
 where slug='imbopwiki-public-test';

select tests.authenticate_as('imbopwiki-b@test.invalid');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-public-test'),0,'unpublished/private content is no longer publicly readable');

select tests.authenticate_as('imbopwiki-a@test.invalid');
select throws_ok(
  $$select public.wiki_start_review((select id from public.wiki_content where slug='imbopwiki-draft-test'))$$,
  'P0001',
  'unauthorized reviewer cannot start review'
);

select tests.authenticate_as_service_role();
update public.wiki_content
   set publication_state='PUBLISHED', visibility='PUBLIC', published_version_id=current_version_id, published_at=now(), published_by_user_id=tests.get_supabase_uid('imbopwiki-a@test.invalid')
 where slug='imbopwiki-public-test';

select tests.authenticate_as('imbopwiki-a@test.invalid');
select is(
  (select public.wiki_create_version((select id from public.wiki_content where slug='imbopwiki-public-test'),'Public Test v2','Version 2',null,'QC working edit')).version_number,
  2,
  'new working version can be created'
);
select is(
  (select current_version_id from public.wiki_content where slug='imbopwiki-public-test'),
  (select id from public.wiki_content_versions where content_id=(select id from public.wiki_content where slug='imbopwiki-public-test') and version_number=2),
  'current version advances to working version'
);
select is(
  (select published_version_id from public.wiki_content where slug='imbopwiki-public-test'),
  (select id from public.wiki_content_versions where content_id=(select id from public.wiki_content where slug='imbopwiki-public-test') and version_number=1),
  'published version remains stable while working version changes'
);

select tests.authenticate_as('imbopwiki-b@test.invalid');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-public-test'),1,'public readers still see only the published content identity');
select is((select count(*)::int from public.wiki_content_versions v join public.wiki_content c on c.id=v.content_id where c.slug='imbopwiki-public-test' and v.id=c.published_version_id),1,'public readers resolve the authorized published version');
select is_empty(
  $ update public.wiki_content
     set title='Cross-tenant mutation'
   where slug='imbopwiki-public-test'
   returning id $,
  'cross-tenant user cannot mutate another institution content'
);
select is_empty(
  $ update public.wiki_community_memberships
     set role='OWNER'
   where id=(select id from public.wiki_community_memberships where user_id=tests.get_supabase_uid('imbopwiki-b@test.invalid'))
   returning id $,
  'member cannot self-escalate to community owner'
);
select throws_ok(
  $ update public.wiki_content
     set publication_state='PUBLISHED'
   where slug='imbopwiki-draft-test'
   returning id $,
  '42501',
  'authenticated client cannot bypass publication lifecycle columns'
);

select * from finish();
rollback;