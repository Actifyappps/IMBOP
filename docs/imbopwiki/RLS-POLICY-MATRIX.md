# IMBOPwiki — RLS Policy Matrix

## Status
**Engineering baseline — branch only. No production schema change.**

RLS is the authorization boundary. Search, links, notifications, space membership, and UI state never grant access independently.

| Object | Anonymous read | Authenticated read | Write authority | Critical deny |
|---|---|---|---|---|
| wiki_spaces | Public active only | Published/public scope or authorized institution/platform | Platform or authorized institution governance | Cross-institution direct-ID read |
| wiki_communities | Public active only | Public/institution/community scope | Platform or authorized institution governance | Community manager cannot rewrite community authority |
| wiki_community_memberships | None | Self/community governance as permitted | Community owner/platform; self-service only where policy permits | Member cannot self-escalate to OWNER |
| wiki_topics | Active public topics | Authenticated | Platform/governance | Unauthorized mutation |
| wiki_content | Published + PUBLIC only | Scope-aware published/private working access | Author for ordinary editable metadata; governance RPCs for lifecycle | Cross-tenant direct-ID access |
| wiki_content_versions | Published version only through authorized content path | Author/reviewer/platform according to content scope | Append through controlled version creation | Working/history leakage |
| wiki_content_topics | Through authorized content | Authorized content participants | Content author/governance | Cross-tenant attachment |
| wiki_discussions | Public published-content/community only | Parent-context authorization | Authorized participant/moderator | Membership removal does not preserve access |
| wiki_discussion_entries | Only through visible discussion | Authorized discussion participant | Authenticated participant; moderation controlled | Hidden/removed entry leakage |
| wiki_content_links | Only as part of authorized source content | Authorized source-content editor | Source-content author/governance | Link never grants target access |
| wiki_content_reviews | None | Authorized governance/reviewer | Governance RPCs | Review evidence cannot be forged by ordinary client |

## Scope order

1. Public + published.
2. Authenticated global access where explicitly permitted.
3. Active institutional membership.
4. Active community membership.
5. Explicit private-community/working-group membership.
6. Platform/SE authority.

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
- Public content is changed to private/unpublished.
- Published content is edited before re-review.
- Private working-group membership is removed.
- Cross-institution target link is attempted.
- Direct UUID access is attempted.
- Community MEMBER attempts OWNER escalation.
- Review/reject/return is attempted without authority.
