-- IMBOPwiki RLS adversarial test specification.
-- Requires the Supabase test-helper package in the local test environment.
-- This file is intentionally not executed against production.

begin;

select plan(12);

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
    (draft_content,space_a,inst_a,u_a,'ARTICLE','Draft Test','imbopwiki-draft-test',
     'DRAFT','PRIVATE',draft_v1,null);

  insert into public.wiki_communities(id,space_id,institution_id,name,slug,status,visibility,owner_user_id)
  values (community_a,space_a,inst_a,'Test Community A','imbopwiki-test-community-a','ACTIVE','INSTITUTION',u_a);

  insert into public.wiki_community_memberships(id,community_id,user_id,institution_id,role,status,joined_at,approved_at,approved_by_user_id)
  values (membership_b,community_a,u_b,inst_a,'MEMBER','ACTIVE',now(),now(),u_a);

  insert into public.wiki_content_versions(id,content_id,version_number,created_by_user_id,title,body)
  values
    (public_v1,public_content,1,u_a,'Public Test','Version 1'),
    (draft_v1,draft_content,1,u_a,'Draft Test','Private draft');

  perform set_config('request.jwt.claim.sub',u_b::text,true);
end $$;

select tests.authenticate_as('imbopwiki-a@test.invalid');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-public-test'),1,'owner can read public content');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-draft-test'),1,'author can read own draft');

select tests.authenticate_as('imbopwiki-b@test.invalid');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-draft-test'),0,'cross-tenant user cannot read draft by direct id');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-public-test'),1,'public published content remains discoverable');

select ok((select tests.rls_enabled('public.wiki_content')), 'wiki_content has RLS');
select ok((select tests.rls_enabled('public.wiki_content_versions')), 'wiki_content_versions has RLS');
select ok((select tests.rls_enabled('public.wiki_communities')), 'wiki_communities has RLS');

select tests.authenticate_as('imbopwiki-b@test.invalid');
select is((select count(*)::int from public.wiki_content_versions v join public.wiki_content c on c.id=v.content_id where c.slug='imbopwiki-draft-test'),0,'cross-tenant user cannot read draft version history');
select is((select count(*)::int from public.wiki_content where slug='imbopwiki-draft-test'),0,'draft remains undiscoverable');
select is((select count(*)::int from public.wiki_content_versions v join public.wiki_content c on c.id=v.content_id where c.slug='imbopwiki-public-test' and v.id=c.published_version_id),1,'published version is the public version');

select is_empty($ update public.wiki_community_memberships set role='OWNER' where id=(select id from public.wiki_community_memberships where user_id=(select tests.get_supabase_uid('imbopwiki-b@test.invalid')) and community_id=(select id from public.wiki_communities where slug='imbopwiki-test-community-a')) returning id $, 'member cannot self-escalate to community owner');

select is_empty(
  $ update public.wiki_content
     set title = 'Cross-tenant mutation'
   where slug='imbopwiki-public-test'
   returning id $,
  'cross-tenant user cannot mutate another institution content'
);

select * from finish();
rollback;