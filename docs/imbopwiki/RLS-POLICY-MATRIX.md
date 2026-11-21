# IMBOPwiki — RLS Policy Matrix

## Status
**Engineering baseline — branch only. No production schema change.**

RLS is the authorization boundary. Search, links, notifications, space membership, and UI state never grant access independently.

| Object | Anonymous read | Authenticated read | Write authority | Critical deny |
|---|---|---|---|---|
| wiki_spaces | Public active only | Published/public scope or authorized institution/platform | Platform or authorized institution governance | Cross-institution direct-ID read |
| wiki_communities | Public active only | Public; institution-visible to active institution members; private only to active community members/platform | Platform or authorized institution governance | Private community must not leak to institution members who are not community members |
| wiki_community_memberships | None | Self/community governance as permitted | Community owner/platform; self-service only where policy permits | Member cannot self-escalate to OWNER |
| wiki_topics | Active public topics | Authenticated | Platform/governance | Unauthorized mutation |
| wiki_content | Published + PUBLIC only | Published/public, or active community membership for community-scoped content, or active institution membership for institution-scoped content | Author for ordinary editable metadata; governance RPCs for lifecycle | Cross-tenant direct-ID access; revoked member retains no private access |
| wiki_content_versions | Published version only | Same authorization scope as the parent content; public readers resolve only published_version_id | Append through controlled version creation | Working/history leakage after membership removal |
| wiki_content_topics | Through authorized content | Authorized content participants | Content author/governance | Cross-tenant attachment |
| wiki_discussions | Public published-content/community only | Parent-context authorization | Authorized participant/moderator | Membership removal does not preserve access |
| wiki_discussion_entries | Only through visible discussion | Authorized discussion participant | Authenticated participant; moderation controlled | Hidden/removed entry leakage |
| wiki_content_links | Only as part of authorized source content | Authorized source-content editor | Source-content author/governance | Link never grants target access |
| wiki_content_reviews | None | Authorized governance/reviewer | Governance RPCs | Review evidence cannot be forged by ordinary client |

## Scope order

1. Public + published.
2. Platform/SE authority.
3. Active community membership for community-scoped/private working-group content.
4. Active institutional membership for institution-scoped content.
5. Explicit global-content creator access only where the object is not institution- or community-scoped.
6. Search, links, notifications, and space presentation never grant access.

## Publication rule

current_version_id is the latest working version.

published_version_id is the version authorized for public/institutional publication.

Editing a published item creates or selects a new working version without changing published_version_id. Publication advances the published pointer only through the governance RPC.

## Cross-object rule

A wiki_content_links row is a reference. The target object's own RLS and authorization remain authoritative.

## Notification rule

A notification/reference is never an authorization grant.

## Required adversarial cases

- User belongs to multiple institutions.
- User loses or suspends an institutional membership.
- User leaves the institution that created content.
- Private community membership is revoked/suspended.
- Public content is changed to private/unpublished.
- Published content is edited before re-review.
- Private working-group membership is removed.
- Cross-institution target link is attempted.
- Direct UUID access is attempted.
- Community MEMBER attempts OWNER escalation.
- Review/reject/return is attempted without authority.
