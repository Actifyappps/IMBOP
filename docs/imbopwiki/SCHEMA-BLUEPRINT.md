# IMBOPwiki — Schema Design Blueprint

## Status
**Blueprint only. No database migration is authorized by this document.**

## 1. Design Rule

IMBOPwiki is an extension of IMBOP. Existing IMBOP tables remain authoritative for identity, institutions, memberships, businesses, opportunities, enquiries, communications and platform governance.

The wiki schema owns knowledge and collaboration objects only.

## 2. Proposed Tables

### 2.1 `wiki_spaces`
Represents a governed wiki context.

Key fields:
- `id`
- `space_type`: GLOBAL / INSTITUTION / COMMUNITY / WORKING_GROUP
- `institution_id` nullable
- `name`
- `slug`
- `description`
- `visibility`
- `status`
- `governance_owner_user_id`
- `created_at`, `updated_at`

**Important:** do not use a space as a substitute for an institution or community. It is a presentation/governance context.

### 2.2 `wiki_communities`
A first-class subject/interest/community object.

Key fields:
- `id`
- `space_id`
- `institution_id` nullable
- `name`
- `slug`
- `description`
- `membership_policy`
- `visibility`
- `status`
- `owner_user_id`
- timestamps

A community may be institution-scoped or explicitly permitted to operate across institutional contexts.

### 2.3 `wiki_community_memberships`
Participation in a community.

Key fields:
- `id`
- `community_id`
- `user_id`
- `institution_id` nullable
- `role`
- `status`
- `joined_at`
- `approved_at`
- `approved_by_user_id`
- timestamps

**Boundary:** this does not replace `public.memberships`.

### 2.4 `wiki_topics`
Reusable subject classifications.

Key fields:
- `id`
- `name`
- `slug`
- `description`
- `status`
- timestamps

Topics may be global or scoped through a separate relation if required.

### 2.5 `wiki_content`
The durable knowledge record.

Key fields:
- `id`
- `space_id`
- `community_id` nullable
- `institution_id` nullable
- `created_by_user_id`
- `content_type`
- `title`
- `slug`
- `summary`
- `current_version_id` — latest working version
- `published_version_id` — version currently authorized for publication; nullable while unpublished
- `publication_state`
- `visibility`
- `published_at`
- `published_by_user_id`
- `archived_at`
- timestamps

**Design rule:** content identity and content version are separate. The content row is the durable identity; versions preserve the actual authored snapshots.

### 2.6 `wiki_content_versions`
Immutable or append-only authored snapshots.

Key fields:
- `id`
- `content_id`
- `version_number`
- `created_by_user_id`
- `title`
- `summary`
- `body`
- `change_reason`
- `created_at`

Unique:
- `(content_id, version_number)`

### 2.7 `wiki_content_topics`
Many-to-many content/topic relationship.

Key fields:
- `content_id`
- `topic_id`

Primary key:
- `(content_id, topic_id)`

### 2.8 `wiki_discussions`
A structured discussion context.

Key fields:
- `id`
- `space_id`
- `community_id` nullable
- `content_id` nullable
- `institution_id` nullable
- `created_by_user_id`
- `title`
- `status`
- `visibility`
- timestamps

At least one useful parent context should normally be required.

### 2.9 `wiki_discussion_entries`
Individual contributions.

Key fields:
- `id`
- `discussion_id`
- `author_user_id`
- `body`
- `status`
- timestamps
- optional `edited_at`

Deletion should normally be represented by moderation state, not silent destructive deletion.

### 2.10 `wiki_content_links`
Typed links into the existing IMBOP economic graph and wiki graph.

Key fields:
- `id`
- `content_id`
- `target_type`
- `target_id`
- `relationship_type`
- `created_by_user_id`
- timestamps

Target types must be an explicit allow-list. Do not permit arbitrary table names.

Initial target families:
- wiki content
- institution
- business
- business profile
- market item
- opportunity
- enquiry
- introduction
- community

### 2.11 `wiki_content_reviews`
Only if the existing IMBOP review-event mechanism cannot represent wiki-specific review evidence.

Key fields:
- `id`
- `content_id`
- `action`
- `from_state`
- `to_state`
- `reviewer_user_id`
- `notes`
- timestamps

Before implementation, confirm whether this can instead use an existing review/event structure.

### 2.12 `wiki_notifications`
In-app notification index.

Key fields:
- `id`
- `recipient_user_id`
- `institution_id` nullable
- `event_type`
- `reference_type`
- `reference_id`
- `read_at`
- timestamps

This table is not an email queue and not a provider delivery ledger.

## 3. Relationships

```
Institution ────────┐
                    ├── Wiki Space
                    │      ├── Community
                    │      │      └── Community Membership
                    │      └── Content
                    │             ├── Versions
                    │             ├── Topics
                    │             ├── Discussions
                    │             └── Content Links ──> Existing IMBOP Objects
                    │
User ───────────────┼── Content / Discussion / Membership
                    │
Existing Membership ┘
```

## 4. Tenant and Scope Rules

Every wiki query must resolve scope before returning data.

Priority:

1. public visibility + published state;
2. authenticated global access;
3. active institutional membership;
4. active community membership;
5. explicit private working-group membership;
6. platform/SE authority where applicable.

No UI-only filtering.

## 5. RLS Blueprint

### Public
Anonymous users may read only records that are:
- published;
- public;
- not archived;
- not deleted.

### Authenticated
Authenticated users may read published authenticated content according to its scope.

### Institution
Users must have an active `public.memberships` record for the relevant institution, unless an explicit platform permission applies.

### Community
Community-restricted records require active `wiki_community_memberships`.

### Working Group
Require explicit active membership/role in the working group context.

### Writes
- authors create/edit their own draft content;
- contributors submit their own content;
- reviewers require explicit wiki/institution governance permission;
- publication requires publication authority;
- community administration requires community governance permission.

### Direct-ID protection
Every select/update/delete policy must independently enforce scope. Knowing a UUID must never bypass RLS.

## 6. Publication State Machine

Conceptual states:

```
DRAFT
  ↓
SUBMITTED
  ↓
IN_REVIEW
  ├──→ RETURNED → SUBMITTED
  ├──→ REJECTED
  └──→ APPROVED → PUBLISHED
                         ↓
                    UNPUBLISHED
                         ↓
                       DRAFT
```

ARCHIVED is a terminal/controlled archival state rather than a casual delete.

Use the existing IMBOP publication-state vocabulary wherever semantically appropriate: DRAFT, SUBMITTED, PENDING_REVIEW, PUBLISHED, RETURNED, REJECTED, UNPUBLISHED. Do not expose current working versions as public merely because current_version_id changed.

## 7. Community State Machine

Conceptual:

```
DRAFT → ACTIVE → PAUSED → ACTIVE
                 └──────→ ARCHIVED
```

Community creation and activation authority must be explicit.

## 8. Discussion Moderation

Discussions should support controlled states such as:
- OPEN
- LOCKED
- ARCHIVED
- REMOVED

Entries should support at least:
- ACTIVE
- HIDDEN
- REMOVED

Moderation must be attributable and auditable.

## 9. Constraints

Before implementation, enforce at database level where appropriate:
- unique slugs within their scope;
- valid visibility/state combinations;
- version numbers unique per content;
- only one current version;
- valid content/community/space relationships;
- no cross-institution link without explicit authorization;
- publication metadata required when published;
- publication metadata absent when not published;
- no community membership granting institution administration;
- no invalid self-referential or unsupported content-link targets.

## 10. Search

Do not create a second independent search authority.

Search should derive from `wiki_content` and related authorized records.

Potential future indexes:
- lower title/slug;
- publication state + visibility;
- institution/community;
- topics;
- full-text/search vector.

Search optimization must never weaken RLS.

## 11. Notifications

`wiki_notifications` is only an in-app recipient index.

For email/WhatsApp/SMS/push:
- create an IMBOP communication record;
- use existing delivery infrastructure;
- preserve idempotency;
- preserve provider/audit evidence;
- never duplicate the delivery system.

## 12. Schema Decisions Still Requiring Final Lock

Before SQL is written, settle:

1. whether `wiki_spaces` is retained for organization/governance presentation in MVP;
2. whether global communities are allowed in MVP;
3. exact content-type list for MVP;
4. whether discussions remain first-class objects or become a content type;
5. whether existing review events can reuse existing IMBOP review structures;
6. exact community roles;
7. exact allowed economic-object link types;
8. whether notifications can reuse an existing in-app notification table;
9. media/attachment model;
10. search implementation;
11. retention/deletion policy;
12. final RLS policy matrix and test fixtures.

## 13. Schema Verdict

The proposed model is deliberately conservative.

It creates a **knowledge/collaboration layer**, not a duplicate IMBOP.

The highest-risk design areas are not the tables themselves. They are:

**scope → RLS → publication → community membership → cross-object links → notifications**

Those must be settled before the first migration.
