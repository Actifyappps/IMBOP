# IMBOPwiki — RLS Policy & Test Matrix

**Status:** Frozen implementation gate

## Authorization axes

- auth.uid() identity
- active public.memberships
- active wiki_community_memberships
- explicit institution/platform permissions
- publication_state
- visibility
- published_version_id
- community status
- target-object authorization

## Policy matrix

| Object | Anonymous | Authenticated | Institution member | Community member | Author | Reviewer/Publisher | Platform authority |
|---|---|---|---|---|---|---|---|
| wiki_spaces | public only where applicable | scoped | own institution | n/a | n/a | manage granted scope | full |
| wiki_communities | public only | eligible public | institution-scoped | own community | n/a | manage granted scope | full |
| community_memberships | none/private | own membership where permitted | own institution context | own community context | n/a | manage granted community scope | full |
| wiki_content | published+public only | published+eligible scope | institution scope | community scope | own permitted working records | review/publish scope | full |
| wiki_content_versions | published version only where public | eligible published/working history | scoped history | scoped history | own versions | review scope | full |
| wiki_discussions | public/open only if published/public | eligible scope | institution scope | community scope | own discussions | moderation scope | full |
| wiki_discussion_entries | public/open only if published/public | eligible scope | institution scope | community scope | own entries | moderation scope | full |
| wiki_content_links | only through authorized parent content | authorized parent | authorized parent | authorized parent | own permitted content | review scope | full |
| wiki_content_reviews | none | no ordinary read | reviewer scope | reviewer scope if applicable | no | own review scope | full |

## Non-negotiable policy rules

1. Every exposed table has RLS.
2. TO authenticated is never the sole authorization condition.
3. UPDATE has both USING and WITH CHECK.
4. Direct UUID access is tested against every scope boundary.
5. Current membership is evaluated at access time for private content.
6. Public reads require PUBLISHED + PUBLIC and the authorized published version.
7. Working versions are never public by inheritance from the parent row.
8. Community membership never grants institution administration.
9. Links never grant target access.
10. Notifications never grant target access.
11. Search is derived from authorized rows.
12. Privileged functions are minimized and never used as a shortcut around authorization.

## Adversarial fixtures

Create synthetic users: SE_PLATFORM, INST_A_ADMIN, INST_A_MEMBER, INST_B_ADMIN, INST_B_MEMBER, CROSS_COMMUNITY_MEMBER, PRIVATE_GROUP_MEMBER, PRIVATE_GROUP_NONMEMBER, UNRELATED_AUTH_USER, anonymous.

Synthetic scopes: Institution A, Institution B, global community, Institution A community, private working group, public article, institution-only article, private article, published version 1 + working version 2, public article linking to private opportunity.

## Required assertions

- A sees A; A does not see B.
- Cross-community member sees the community only because of community membership.
- Private-group nonmember is denied even with a direct UUID.
- Removed member loses access immediately.
- Public reader sees published version 1 while version 2 is under review.
- Returning/rejecting a draft does not expose it publicly.
- Publishing version 2 switches the authorized public version atomically.
- A public content link to a private target does not expose target data.
- Community moderator cannot call institution-admin actions.
- Notification reference cannot be used as an access side door.
