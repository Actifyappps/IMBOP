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
