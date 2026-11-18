# IMBOP Communications Architecture

## Status

**Accepted architecture — initial implementation boundary**

## Purpose

IMBOP needs one communications infrastructure spanning platform events, applications, institutions, members and commercial lifecycle.

The design avoids building separate email, notification, pricing-message and admin-message systems.

## Architecture

```
DOMAIN EVENT
    ↓
COMMUNICATION ORCHESTRATOR
    ↓
COMMUNICATION RECORD
    ↓
DELIVERY CHANNEL
    ↓
DELIVERY STATUS
    ↓
AUDIT / HISTORY
```

The communications layer sits beside the core domains. It does not become the owner of their business decisions.

## Domain ownership

| Domain | Owns | Communications does |
|---|---|---|
| Applications | application state and review decisions | communicates decisions/events |
| Institutions | institution lifecycle and authorization | communicates approved lifecycle events |
| Memberships | membership and IMBOP Onboard state | communicates approved onboarding events |
| Publication | publication authority and status | communicates publication-related events |
| Pricing | plans, thresholds and commercial state | communicates pricing/billing events |
| Administration | authorized administrative actions | records and delivers admin-originated communications |
| Communications | communication lifecycle | orchestrates, delivers and audits |

## Core event model

Every event eligible for communication should have:

- event type
- source domain
- source record/reference
- institution context where applicable
- actor where applicable
- event timestamp
- idempotency key where needed

Not every event must produce an external message. The orchestrator determines whether the event creates an in-app, email or future-channel communication.

## Communication record model

The implementation should support, at minimum:

- communication id
- institution id where applicable
- recipient identity/reference
- recipient type
- source record/reference
- communication type
- subject
- rendered body or template reference
- channel
- triggering event
- created by
- scheduled time
- sent time
- delivery status
- failure reason
- retry count
- read/open metadata where supported

The final database schema should be introduced through a reviewed Supabase migration when implementation begins.

## Initial communication catalogue

### Institution lifecycle

- Application Received
- Application Under Review
- Application Returned
- Application Approved
- Application Rejected
- Institution Activated

### Member lifecycle

- Member Application Received
- Member Approved
- Member Rejected
- Member Onboarded

### Commercial lifecycle

- 50-Onboard Milestone
- Pricing Plan Changed
- Transition Payment Notice
- Payment Reminder

### Platform

- Platform Notice
- Service/maintenance notice where approved

## Pricing communication

The first commercial threshold is deliberately explicit:

**First 50 IMBOP Onboards: FREE**

When an institution moves beyond 50:

> Congratulations — your Institution is growing.

The transition communication explains that the institution has moved beyond the free starter allowance, that the transition month carries the approved discounted minimum, and that subsequent pricing follows the institution's actual number of IMBOP Onboards.

The institution is the customer. Individual institution members are not separately billed for the institutional IMBOP plan.

## Delivery model

Phase 1:

**In-App + Email**

Future:

**SMS + WhatsApp + other approved channels**

All channels use the same communication record and audit model.

## Reliability

Delivery must support:

- idempotency
- retry state
- failure reason
- delivery status
- safe reprocessing
- audit history

A failed email must not erase the underlying communication record.

## Security

Communications is not an authorization bypass.

Recipient selection must be constrained by server-side authorization and tenant rules. Administrative sends must require the appropriate platform or institution permissions.

No public endpoint should expose private communication history.

## Repository placement

Application routes remain under:

`src/app/`

Reusable presentation remains under:

`src/components/`

Communication domain logic belongs under:

`src/features/communications/`

Cross-cutting adapters remain under:

`src/lib/` when they are genuinely shared beyond communications.

Database evolution remains under:

`supabase/migrations/`

Security and end-to-end validation remain under:

`supabase/tests/` and `tests/`

## Implementation rule

Build the smallest real vertical slice first:

**event → communication record → in-app delivery → audit**

Then add email delivery.

Do not build SMS, WhatsApp, scheduling, broadcast campaigns or elaborate template tooling before the core communication contract is proven.
