# IMBOPwiki — Architecture Reconciliation

## Purpose

This document reconciles the IMBOPwiki foundation with the existing IMBOP production architecture before any application or database code is written.

**Rule:** reuse existing IMBOP authority, tenancy, governance, communications and audit mechanisms wherever they already solve the requirement. Add new primitives only where wiki-specific behaviour genuinely requires them.

## 1. Reuse Map

| IMBOPwiki need | Existing IMBOP authority to reuse | Wiki-specific addition |
|---|---|---|
| Institution identity | `institutions` | none |
| Institutional tenancy | `institution_id` + existing RLS/permission helpers | none |
| User identity | Supabase Auth / existing users | none |
| Institutional membership | `memberships` + active-status checks | community membership is a separate scope |
| Institution roles | existing institution/platform permission model | wiki/community roles where needed |
| Businesses | `businesses` / `business_profiles` | link only |
| Offers / Needs | `market_items` | link only |
| Opportunities | `opportunities` | link only |
| Enquiries / introductions | existing IMBOP domain | link/reference only |
| Publication authority | existing publication permission and transition patterns | wiki content lifecycle |
| Review reasons | existing review-note/review-event patterns | wiki review records where necessary |
| Audit | existing IMBOP audit approach | wiki events feed existing audit |
| In-app communication | existing communication records/functions | wiki event types/templates |
| Email delivery | existing communication queue + dispatcher + Resend adapter | no second email system |
| Notifications | existing communications foundation | wiki notification records if needed for targeted in-app delivery |
| Public discovery | existing publication/visibility model and public search patterns | wiki search/indexing |
| Security | Supabase/Postgres RLS + server authorization | wiki-specific policies |
| Deployment | existing GitHub → Supabase → Vercel flow | none |

## 2. Existing IMBOP Rules That IMBOPwiki Must Inherit

### Database is the security boundary

IMBOPwiki must not introduce UI-only tenant filtering.

Every restricted read/write must be authorized through the existing database/server security model.

### Institution authority remains institution authority

IMBOPwiki does not create a parallel institution governance system.

For institution-owned knowledge, the institution remains the governing authority within its granted scope.

SE remains the platform authority.

### Publication remains explicit

The existing IMBOP rule:

**CREATE → SAVE DRAFT → SUBMIT → REVIEW → PUBLISH**

must remain true for wiki content.

Creating a wiki article, discussion, report or resource must never make it public merely because a route exists.

### Communications remain downstream

The existing IMBOP communications principle is:

**BUSINESS STATE CHANGE → COMMUNICATION RECORD → CHANNEL DELIVERY**

IMBOPwiki must follow the same pattern:

**WIKI EVENT → COMMUNICATION RECORD → CHANNEL DELIVERY**

A notification must never become the source of truth for the underlying wiki state.

## 3. Existing Economic Graph

IMBOPwiki should connect to existing economic objects instead of copying them.

The intended relationship is:

**Wiki Knowledge → Institution / Member / Business / Offer / Need / Opportunity**

Examples:

- an agriculture research note references existing businesses;
- an export brief points to an existing opportunity;
- a discussion references an existing offer;
- a market report points to an existing value-chain community;
- an opportunity conversation can lead to the existing enquiry workflow.

The wiki stores the knowledge relationship; the economic domain remains authoritative for the economic object.

## 4. Membership Boundary

An IMBOP membership and a wiki/community membership are not automatically the same thing.

- Active institutional membership may be a prerequisite for participation in an institution's wiki space.
- Community membership grants the additional scope required for restricted communities.
- A community role must not silently grant institution administration.
- Platform roles remain separate from institution memberships.

This preserves the existing distinction between platform authority and tenant membership.

## 5. Visibility and Publication

The wiki should use controlled visibility states aligned with IMBOP:

- PUBLIC
- AUTHENTICATED
- INSTITUTION
- COMMUNITY
- PRIVATE WORKING GROUP

But visibility is not enough.

A record is publicly discoverable only when:

**publication_state = PUBLISHED**

and its visibility permits public discovery.

This is an explicit combination, not a single flag.

## 6. Lifecycle Reconciliation

Existing IMBOP publication governance uses controlled state transitions and database enforcement.

IMBOPwiki should follow the same philosophy rather than inventing a loosely governed CMS.

Conceptual wiki lifecycle:

**DRAFT → SUBMITTED → IN REVIEW → APPROVED → PUBLISHED**

Correction:

**RETURNED → SUBMITTED**

Decision:

**REJECTED**

Removal:

**PUBLISHED → UNPUBLISHED / ARCHIVED**

The exact database states and transition functions should be finalized only after the schema is designed.

## 7. Communications Reuse

The existing communications architecture already provides:

- communication records;
- delivery records;
- idempotency;
- provider message IDs;
- provider responses;
- retry handling;
- auditability;
- email dispatch;
- in-app communication patterns.

Therefore IMBOPwiki must **not** create:

- a second email queue;
- a second Resend integration;
- a second delivery ledger;
- a separate provider abstraction;
- a competing audit universe.

Wiki notifications should create ordinary IMBOP communication events and use the existing delivery infrastructure.

## 8. Audit Reuse

Wiki governance actions should feed the existing IMBOP audit approach.

At minimum, future implementation should be able to evidence:

- who created content;
- who edited it;
- who submitted it;
- who reviewed it;
- who approved it;
- who published it;
- who returned/rejected it;
- who moderated it;
- who changed community membership/roles;
- what changed and when.

A wiki-specific audit table should only be introduced if the existing audit mechanism cannot safely represent the required evidence.

## 9. Search and Discovery

Search must remain a derived discovery mechanism, never an authorization mechanism.

The existing public institution discovery pattern demonstrates the correct principle:

**authorized/public source data → controlled search function → published result**

IMBOPwiki search should follow the same model.

Private or unpublished content must not become discoverable through:

- search;
- direct IDs;
- related-content lists;
- notification previews;
- cached metadata.

## 10. Media

IMBOPwiki should reuse the existing media/storage security model.

A wiki attachment is not public merely because it is stored.

Public access must depend on the associated record's authorization and publication/visibility state.

No separate unrestricted public bucket should be introduced merely for convenience.

## 11. What Is Genuinely New

The reconciliation identifies several capabilities that are genuinely wiki-specific:

1. **Wiki content record** — durable knowledge independent of a business/opportunity record.
2. **Community** — governed subject/interest/workspace context.
3. **Community membership** — explicit participation scope.
4. **Content version** — durable knowledge revision history.
5. **Discussion thread/entry** — structured collaboration around knowledge and economic objects.
6. **Content-to-object links** — typed relationships between knowledge and existing IMBOP records.
7. **Wiki review context** — only where existing review records cannot express wiki-specific review requirements.
8. **Wiki-specific notification events** — using existing communications infrastructure.

These are extensions, not a replacement platform.

## 12. What We Should Not Build

Before implementation, explicitly reject:

- parallel user identity;
- parallel institution tables;
- parallel membership tables for ordinary institutional membership;
- second email provider stack;
- second notification delivery ledger;
- second audit universe;
- duplicate business/opportunity records;
- unrestricted public content tables;
- UI-only authorization;
- automatic publication;
- per-institution databases;
- microservices;
- AI matchmaking;
- a WhatsApp clone.

## 13. Architectural Shape

The reconciled architecture is:

**SE IMBOP**

→ Institutions  
→ Memberships  
→ Businesses  
→ Offers / Needs  
→ Opportunities  
→ Enquiries / Introductions  
→ Communications / Audit

and alongside those existing domains:

**IMBOPwiki**

→ Wiki Content  
→ Communities  
→ Community Membership  
→ Topics  
→ Content Versions  
→ Discussions  
→ Content Links

The wiki objects connect into the existing graph rather than replacing it.

## 14. Implementation Gate

No schema migration should be written until the following are explicitly settled:

- exact wiki content types;
- exact lifecycle states;
- community ownership and cross-institution rules;
- role/permission matrix;
- visibility rules;
- discussion moderation boundary;
- content versioning behaviour;
- notification event catalogue;
- exact links to existing IMBOP objects;
- RLS policy design;
- search approach;
- media/access approach.

## 15. Reconciliation Verdict

**IMBOPwiki fits the existing IMBOP architecture.**

It does not require a second platform.

The correct design is an **IMBOP-native knowledge and collaboration domain** that reuses existing:

**identity → tenancy → membership → governance → publication → communications → audit → deployment**

and adds only the wiki-specific objects required to turn conversations and knowledge into durable institutional memory.

That is the architecture we should freeze before coding.
