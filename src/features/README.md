# IMBOP Feature Architecture

Domain capabilities live here. Route files in `src/app/` are the presentation and routing layer; reusable domain logic belongs in feature modules.

## Active capability boundaries

- `administration/` — SE and institution administration, including commercial/billing controls.
- `communications/` — event-driven notifications, templates, delivery and communication audit.

## Capability map

The platform capability model is:

- `institutions/` — institution identity, lifecycle and public spaces
- `memberships/` — institution membership and IMBOP Onboards
- `applications/` — institution/member applications and review workflows
- `publication/` — publication authority and lifecycle
- `discovery/` — public institution discovery
- `economic-network/` — businesses, profiles, offers, needs, opportunities, enquiries and introductions
- `pricing/` — plans, thresholds and institutional commercial state
- `billing/` — invoices, payment intents, payments, allocations, receipts, settlement, reconciliation and refunds
- `administration/` — SE and institution administration
- `reporting/` — institutional and platform reporting

These capability names describe domain ownership. A capability should become a physical feature directory when it has enough real domain logic to justify isolation; the repository should not create empty folders merely for symmetry.

## Billing boundary

Billing owns the commercial lifecycle:

**PRICE → BILL → PAY → RECONCILE → REFUND → AUDIT**

It does not own:

- institution admission
- member authorisation
- publication authority
- business content decisions
- provider credentials outside the approved adapter boundary

## Engineering rule

Create or expand a feature module when the boundary improves ownership, testability, security review, reuse or future development.

Do not create empty abstractions merely for symmetry.
