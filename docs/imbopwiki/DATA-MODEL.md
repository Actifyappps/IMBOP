# IMBOPwiki — Final Data Model
**Status:** Reconciled and frozen for migration planning
**No production migration is authorized by this document.**

## Reuse
Existing IMBOP: Auth/users, institutions, memberships, permissions, businesses, business_profiles, market_items, opportunities, enquiries, introductions, communications, audit and media/storage governance.

## Wiki-specific primitives
### wiki_spaces
id, institution_id nullable, name, slug, description, visibility, status, governance_owner_user_id, timestamps. Presentation/governance context only.

### wiki_communities
id, space_id, institution_id nullable, name, slug, description, membership_policy, visibility, status, owner_user_id, timestamps. Nullable institution_id permits global/cross-institution communities.

### wiki_community_memberships
id, community_id, user_id, institution_id nullable, role, status, joined_at, approved_at, approved_by_user_id, timestamps. Unique active membership per community/user.

### wiki_topics
id, name, slug, description, status, timestamps.

### wiki_content
id, space_id, community_id nullable, institution_id nullable, created_by_user_id, content_type, title, slug, summary, current_version_id, published_version_id nullable, publication_state, visibility, published_at, published_by_user_id, archived_at, timestamps.

### wiki_content_versions
id, content_id, version_number, created_by_user_id, title, summary, body, change_reason, created_at. Append-only; unique content_id + version_number.

### wiki_content_topics
content_id + topic_id primary key.

### wiki_discussions
id, space_id, community_id nullable, content_id nullable, institution_id nullable, created_by_user_id, title, status, visibility, timestamps. At least one governed parent context required.

### wiki_discussion_entries
id, discussion_id, author_user_id, body, status, edited_at nullable, timestamps.

### wiki_content_links
id, content_id, target_type, target_id, relationship_type, created_by_user_id, timestamps. Allow-list: WIKI_CONTENT, INSTITUTION, BUSINESS, BUSINESS_PROFILE, MARKET_ITEM, OPPORTUNITY, ENQUIRY, INTRODUCTION, COMMUNITY. A link never grants access.

### wiki_content_reviews
Retained because existing IMBOP review functions are domain-specific. Fields: id, content_id, action, from_state, to_state, reviewer_user_id, notes, created_at.

### Notifications
Prefer existing IMBOP Communications Infrastructure. Do not create wiki_notifications unless the existing inbox/read model demonstrably cannot represent wiki notifications.

## MVP content types
ARTICLE, OPPORTUNITY, QUESTION, RESOURCE, ANNOUNCEMENT, EVENT.

## Integrity
Enforce valid state/visibility combinations, unique scoped slugs, unique versions, valid current/published version references, publication metadata rules, coherent content/community/space relationships, explicit link target types, controlled archive/unpublish, and no privilege escalation through community roles.

## Migration boundary
First migration must be additive and isolated to IMBOPwiki. Do not alter billing or unrelated production workflows.