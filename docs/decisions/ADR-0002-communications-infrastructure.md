# ADR-0002 — IMBOP Communications Infrastructure

**Status:** Accepted  
**Date:** 2026-11-18

## Decision

IMBOP will use one unified **Communications Infrastructure** rather than separate systems for email, application notices, pricing messages, admin broadcasts and member notifications.

The domain is seated at:

`src/features/communications/`

Its architecture is:

**EVENT → COMMUNICATION → DELIVERY → AUDIT**

## Context

IMBOP has multiple authoritative domains that generate important events:

- applications
- institutions
- memberships
- publication
- pricing
- administration

These events require reliable, auditable communication to different audiences.

Building separate notification mechanisms for each domain would create duplicated templates, inconsistent delivery state, weak auditability and avoidable maintenance.

## Consequences

### Positive

- one communication history
- consistent templates and variables
- common delivery/retry model
- clear audit trail
- future channels can be added without redesigning business domains
- application and pricing communications use the same infrastructure
- system-generated and admin-generated messages remain distinguishable but auditable

### Constraints

- communications does not own business decisions
- recipient authorization remains with the relevant domain/security boundary
- public discovery must never expose private communications
- every material communication action must remain traceable

### Non-goals

This ADR does not authorize:

- payment processing
- automatic commercial collection
- SMS/WhatsApp integration
- bulk marketing automation
- replacement of application or institution authorization logic

Those require separate implementation decisions.

## Initial delivery strategy

Implement the first vertical slice as:

**Approved event → communication record → in-app notification → audit**

Then add:

**Email delivery → retry handling → delivery status**

Future channels are extensions of the same communication contract.
