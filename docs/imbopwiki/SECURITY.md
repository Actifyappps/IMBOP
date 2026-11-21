# IMBOPwiki — Security & RLS Model
**Status:** Frozen for MVP engineering

## Security boundary
**The database is the security boundary.**
UI hiding, route guards, search filters, notification links and client identifiers are not security controls.

## Identity and membership
Reuse Supabase Auth and existing IMBOP identity. Reuse public.memberships for institutional membership. Use wiki_community_memberships only for community participation. Community roles cannot grant institution or platform administration.

## RLS
Every exposed wiki table must have RLS enabled. TO authenticated alone is insufficient. UPDATE requires both correct USING and WITH CHECK. Knowing a UUID never bypasses scope.

## Public
Anonymous users may read only records that are PUBLISHED + PUBLIC + not archived/deleted and whose published_version_id is the authorized public version.

## Institution
Institution-scoped content requires current active membership unless explicit platform authority applies.

## Community
Community/private content requires current active community membership unless an explicit public publication or platform-authority path applies.

## Working groups
Private working groups are private communities. Removing membership immediately removes access to old URLs/direct IDs.

## Version security
current_version_id = latest working version.
published_version_id = version currently authorized for publication.
Public readers never receive private draft history.

## Links and notifications
Links are relationships, not permissions. Target authorization always wins.
Notifications do not grant object access; opening one re-checks target authorization and previews minimize sensitive data.

## Required denial tests
Institution A → B content; non-member → private community; removed member → old discussion; public → unpublished/private content; community moderator → institution-admin action; direct-ID outside scope.