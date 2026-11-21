# IMBOPwiki — Decisions

## Decision 001 — In-App Product
**Decision:** IMBOPwiki is an in-app IMBOP capability, not an external documentation site.
**Reason:** Its purpose is knowledge and collaboration among people and institutions already participating in the IMBOP economic network.

## Decision 002 — Shared IMBOP Architecture
**Decision:** IMBOPwiki extends the existing IMBOP architecture.
**Reason:** Institutions, members, businesses and opportunities already exist in IMBOP. Wiki knowledge should connect to those objects rather than duplicate them.

## Decision 003 — Governed Publication
**Decision:** Creation does not equal publication.
**Reason:** Institutional trust requires deliberate publication control.

## Decision 004 — Open to Discover; Authenticated to Participate
**Decision:** Publicly published knowledge may be discoverable; participation requires authentication and appropriate authorization.
**Reason:** This supports reach without sacrificing accountable participation.

## Decision 005 — WhatsApp Is Complementary
**Decision:** WhatsApp may be a notification/distribution and future integration channel, but IMBOPwiki remains the authoritative knowledge record.
**Reason:** IMBOP should integrate with ecosystems rather than attempt to replace them.

## Decision 006 — Knowledge Over Disposable Conversation
**Decision:** Favor discussions and contributions that can become durable, searchable institutional knowledge.
**Reason:** The strategic value is institutional memory, not merely message volume.

## Decision 007 — RLS Is the Security Boundary
**Decision:** Supabase/Postgres RLS and server-side authorization remain the fundamental security boundary.
**Reason:** UI filtering is insufficient for a multi-tenant institutional system.

## Decision 008 — No Parallel Audit Universe
**Decision:** Reuse the existing IMBOP audit approach.
**Reason:** Governance evidence should remain coherent across the platform.

## Decision 009 — No Premature Integrations
**Decision:** External integrations follow:
**LINK → WIDGET/EMBED → API → NATIVE ACTION → DEEP WORKFLOW**
**Reason:** Integration depth should be earned by demonstrated value.

## Decision 010 — Documentation Before Code
**Decision:** No IMBOPwiki application coding begins until product, information architecture, governance, security and MVP boundaries are sufficiently defined.
**Reason:** Prevents premature schema/UI decisions and reduces rework.

## Decision 011 — Sibling Learning
**Decision:** YetuCareWiki is a source of architectural lessons, not a template to copy blindly.
**Reason:** IMBOPwiki serves an institutional economic-network domain with different objects, permissions and workflows.

## Decision 012 — One Core, Many Networks
**Decision:** IMBOPwiki is designed to serve many institutional networks from shared infrastructure.
**Reason:** This preserves the IMBOP multi-tenant platform model and avoids a fork-per-institution architecture.


## Decision 013 — Reuse IMBOP Authority Before Adding Wiki Infrastructure
**Decision:** IMBOPwiki must extend and reuse the existing IMBOP identity, tenancy, membership, publication, communications, audit and security architecture wherever those capabilities already satisfy the requirement.

**Reason:** IMBOPwiki is a native knowledge and collaboration domain inside IMBOP, not a second platform. Duplicate identity, tenancy, communication, audit or economic records would create conflicting sources of truth and unnecessary security risk.

**Implementation consequence:** New wiki-specific primitives are limited to knowledge/content, communities, community membership, versions, discussions, content links and other capabilities demonstrated to be genuinely absent from the existing IMBOP domain model.


## Decision 014 — Published Version Is Separate from Working Version
**Decision:** Wiki content must distinguish the latest working version from the version currently authorized for publication.

**Reason:** Editing a published article must never expose an unreviewed draft. The content record therefore carries separate current and published version references.

## Decision 015 — Working Groups Are Governed Communities in MVP
**Decision:** A private working group is represented by a private, governed community rather than a second membership universe.

**Reason:** This keeps participation, moderation and RLS in one model while still supporting sensitive collaboration.

## Decision 016 — Links and Notifications Never Grant Access
**Decision:** Wiki links and notifications are references only. They cannot grant access to their targets.

**Reason:** The target object's own authorization must always be evaluated independently, preventing cross-tenant leakage and notification-based side doors.

## Decision 017 — Reuse IMBOP Publication Vocabulary
**Decision:** IMBOPwiki should reuse the established IMBOP publication lifecycle wherever semantically appropriate.

**Reason:** A second publication vocabulary would create unnecessary governance and implementation divergence.

## Decision 018 — Space Is Not an Authorization Boundary
**Decision:** A wiki space may organize presentation and governance, but it cannot independently grant access.

**Reason:** Multiple overlapping scope fields are a security risk. Authorization must derive from explicit publication, institution, community, private-group and platform permissions.


## Decision 019 — Product and Information Architecture Frozen
**Decision:** The MVP product boundary and information architecture are now frozen for engineering planning.
**Reason:** Schema work must implement a settled product, not continue to invent one.

## Decision 020 — Global Communities Are Allowed in MVP
**Decision:** Communities may be global/cross-institution or institution-scoped. A private working group is a private community.
**Reason:** IMBOPwiki must support cross-institution economic communities while preserving explicit membership control.

## Decision 021 — Discussions Are First-Class Collaboration Objects
**Decision:** Discussions are separate first-class records, not a content type.
**Reason:** Discussion access, moderation and lifecycle differ from durable knowledge publication.

## Decision 022 — Wiki Review Evidence Is Wiki-Specific
**Decision:** Use a wiki-specific review ledger unless an existing generic IMBOP event mechanism is proven to provide equivalent review evidence.
**Reason:** Existing review functions are domain-specific; wiki governance needs attributable state-transition evidence without duplicating business-domain review logic.

## Decision 023 — Communications Infrastructure Is Reused
**Decision:** Wiki notifications use the existing IMBOP Communications Infrastructure. A second wiki notification/delivery system is prohibited unless a concrete gap is proven.
**Reason:** IMBOP already has auditable communication records, delivery state, in-app inbox/read behaviour, idempotency and delivery infrastructure.

## Decision 024 — MVP Media Reuses Existing Governance
**Decision:** Wiki media/attachments reuse existing IMBOP storage/media security and publication rules. No parallel wiki media subsystem is part of the first migration unless a concrete gap is demonstrated.
**Reason:** Stored media must inherit the authorization discipline of the record it belongs to.

## Decision 025 — Final Model Gate
**Decision:** The next engineering artifact is a migration design plus RLS policy/test matrix. No production schema change is authorized until that design is checked against the frozen model.
**Reason:** The highest-risk surface is scope → RLS → publication → membership → links → notifications, not table creation itself.
