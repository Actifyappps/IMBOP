# IMBOPwiki — Final Data Model Baseline

## Status
**Frozen for MVP engineering on feature/imbopwiki-foundation.**

IMBOPwiki remains a module inside the existing IMBOP repository. It does not create a second identity, institution, membership, communications, audit, or economic-object universe.

## Wiki-owned primitives

1. wiki_spaces — presentation/governance context; never an authorization boundary.
2. wiki_communities — institution-scoped or global/cross-institution communities.
3. wiki_community_memberships — participation in communities; separate from ordinary IMBOP institutional membership.
4. wiki_topics — reusable subject classification.
5. wiki_content — durable knowledge identity and publication state.
6. wiki_content_versions — authored snapshots; working and published versions are distinct.
7. wiki_content_topics — topic relation.
8. wiki_discussions — first-class collaboration objects.
9. wiki_discussion_entries — attributable contributions.
10. wiki_content_links — typed references into the wiki and existing IMBOP economic graph.
11. wiki_content_reviews — attributable wiki publication evidence.

## Existing IMBOP authorities reused

- Authenticated identity.
- Institutions and institutional memberships.
- Businesses, profiles, market items, opportunities, enquiries and introductions.
- Existing communication records and delivery infrastructure.
- Existing audit/security patterns.
- Existing storage/media governance.
- Existing publication vocabulary.

## Frozen publication model

DRAFT → SUBMITTED → PENDING_REVIEW → PUBLISHED

Exception paths:

RETURNED → SUBMITTED

REJECTED

PUBLISHED → UNPUBLISHED

ARCHIVED is controlled archival.

The public reader resolves only published_version_id.

## Frozen community model

- Global/cross-institution community: permitted.
- Institution-scoped community: permitted.
- Private working group: represented as a private governed community.
- No second working-group membership universe.

## Frozen collaboration model

Discussions are first-class objects because their access and moderation lifecycle differs from durable knowledge publication.

## Frozen integration model

LINK → WIDGET/EMBED → API → NATIVE ACTION → DEEP WORKFLOW

WhatsApp is complementary distribution/notification infrastructure, not the authoritative knowledge record.

## Frozen security model

RLS is the database authorization boundary.

- Direct UUID knowledge never bypasses scope.
- Links do not grant target access.
- Notifications do not grant target access.
- Space membership/presentation does not grant authorization.
- Published version remains stable while working edits are under review.
- Publication lifecycle columns are controlled through authenticated governance functions.
