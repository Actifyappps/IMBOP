# IMBOP Communications Infrastructure

## Purpose

The communications feature is the single domain capability responsible for recording, orchestrating and auditing important IMBOP communications.

It is not an email-only feature and it is not a collection of unrelated notification screens.

The canonical flow is:

**EVENT → COMMUNICATION → DELIVERY → AUDIT**

## Communication domains

The infrastructure supports:

- **System Notifications** — lifecycle-driven notices.
- **Application Communications** — institution and member application outcomes and required actions.
- **Institution Communications** — controlled institution-to-member/applicant communication.
- **Member Communications** — onboarding, review and important institutional notices.
- **SE Admin Communications** — authorized targeted and platform-wide communications.
- **Pricing & Billing Communications** — plan changes, transition notices, reminders and billing-related notices.

## Initial channels

Phase 1:

**In-App + Email**

Future channels may include:

**SMS + WhatsApp + other approved channels**

Channels are delivery mechanisms, not separate communication systems.

## Core concepts

### Communication event

A meaningful platform event that may require communication.

Examples:

- institution application submitted
- application returned
- application approved
- institution activated
- member application approved
- 50 IMBOP Onboard milestone
- pricing plan changed
- payment reminder
- platform notice

### Communication record

The auditable record of what IMBOP intended to communicate, to whom, through which channel, and why.

### Template

An approved reusable message definition with controlled variables such as:

- `{{institution_name}}`
- `{{imbop_onboards}}`
- `{{plan_name}}`
- `{{monthly_fee}}`
- `{{review_notes}}`
- `{{action_url}}`

### Delivery

The channel-specific attempt to deliver a communication.

Delivery must retain status and failure information and must not silently disappear.

## Governance

Two origins are deliberately distinguished:

**System-generated** — produced from approved platform events.

**Admin-generated** — deliberately sent by an authorized SE or Institution administrator.

Both are recorded and auditable.

Admins must not be able to send untracked communications.

## Current implemented vertical slice

The first production-path slice is now seated:

**Approved publication event → communication record → in-app delivery → read/audit state**

When an Institution publishes a member application that has a linked business owner account, IMBOP creates an auditable system communication and an in-app delivery for that authenticated business owner. The recipient can view the message in the authenticated **Notifications** area and mark it as read.

The database enforces recipient isolation with RLS; anonymous users cannot read the communication tables or execute the inbox/read RPCs.

Email remains the next delivery channel. The architecture is intentionally ready for it without coupling the current in-app slice to an email provider.

## Future module boundaries

Add code beneath this feature only when the corresponding capability has real implementation logic:

`events/` — event definitions and triggers

`templates/` — approved template definitions and rendering

`orchestration/` — event-to-communication rules

`delivery/` — channel adapters, retries and delivery status

`history/` — communication history and audit queries

`preferences/` — recipient/channel preferences

`admin/` — authorized communication-centre operations

Do not create these directories merely as placeholders. Introduce them when implementation requires the boundary.

## Non-goals

This feature does not own:

- application review authority
- institution/member authorization
- publication authority
- pricing policy
- payment processing
- tenant authorization

Those remain owned by their respective domains. Communications observes approved events from those domains and records/delivers the resulting communication.

## Security rule

Recipient eligibility and authorization must be derived from authenticated identity, institutional relationship and database policy. A browser-supplied recipient or institution identifier is never sufficient authority.

Sensitive communication data must not be exposed through public discovery APIs.
