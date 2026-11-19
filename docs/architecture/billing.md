# IMBOP Billing System Blueprint

## Purpose

The IMBOP billing system turns the approved commercial model into an auditable institutional billing layer.

The customer is the **Institution**.

Individual institution members are not billed for ordinary IMBOP participation.

The commercial unit is the institution's number of **IMBOP Onboards**.

## Commercial rule

**0–50 IMBOP Onboards: FREE**

Beyond 50, the institution moves to the applicable numbers-based plan.

The first transition month may use the approved discounted minimum of **KES 5,000**.

## Billing architecture

The billing domain is separated into:

1. **Pricing Plans** — what SE says a plan costs.
2. **Institution Billing Account** — the institution's current commercial state.
3. **Invoices** — what is owed for a defined billing period.
4. **Invoice Lines** — why the invoice total exists.
5. **Payments** — money received/recorded.
6. **Payment Allocations** — which invoice a payment settles.
7. **Billing Events** — immutable operational history.
8. **Communications** — notifications about billing events.

Canonical flow:

**ONBOARD COUNT → PLAN RESOLUTION → INVOICE → PAYMENT → ALLOCATION → RECONCILIATION → COMMUNICATION → AUDIT**

## Important separation

Pricing is not billing.

- Pricing defines the commercial rules.
- Billing calculates and records obligations.
- Payments record settlement.
- Communications tells people what happened.

No billing screen should silently change pricing policy.

## Invoice lifecycle

**DRAFT → ISSUED → PARTIALLY PAID → PAID**

Exception states:

- **OVERDUE**
- **VOID**
- **WAIVED**

Free/founding invoices may be recorded as **WAIVED** rather than pretending that a KES 0 invoice was paid.

## Payment model

The first billing foundation is **provider-neutral**.

It supports recording payments through:

- manual
- bank transfer
- M-Pesa
- card
- other

But this branch does **not** connect a payment gateway or initiate customer charges.

That should be a separate, deliberate integration after the accounting model is proven.

## Security model

Institution billing data is institution-scoped.

Institution administrators may read their institution's billing information.

SE platform administrators control:

- invoice creation
- payment recording
- overdue state
- billing administration

Direct customer-side writes to financial records are not allowed.

Platform financial operations are exposed through tightly scoped RPCs that verify platform permission.

## Billing records

### billing_invoices

Stores:

- institution
- invoice number
- plan snapshot
- billing period
- due date
- IMBOP Onboard snapshot
- subtotal
- adjustments
- total
- status
- notes
- issuer

### billing_invoice_lines

Stores the commercial explanation of each amount:

- plan charge
- transition charge
- adjustment
- credit
- other

### billing_payments

Stores:

- institution
- provider
- provider reference
- payment method
- amount
- currency
- payment status
- received time
- recorder
- idempotency key
- notes
- metadata

### billing_payment_allocations

Allows one payment to be allocated against one or more invoices.

This is important because a real institution may pay:

- one invoice
- several invoices together
- part of an invoice
- an amount that requires reconciliation.

### billing_events

Provides an auditable billing history.

Examples:

- INVOICE_ISSUED
- INVOICE_WAIVED
- PAYMENT_CONFIRMED

The event model is intended to grow as billing operations mature.

## Current platform RPC boundary

The foundation introduces controlled operations for:

- institution billing summary
- platform invoice creation
- platform payment recording
- overdue invoice marking
- platform billing-account reporting

These operations are intentionally not exposed as unrestricted table writes.

## Future billing phases

### Phase 1 — Foundation

- pricing plan source
- billing accounts
- invoices
- invoice lines
- payment records
- allocations
- billing events
- institution billing visibility
- SE billing administration

### Phase 2 — Billing operations

- invoice generation schedule
- automatic plan/Onboard evaluation
- billing-period management
- reminders
- grace periods
- statement view
- receipts
- reconciliation workflow
- credit notes/adjustments
- billing exports

### Phase 3 — Payment integration

Only after the internal billing model is stable:

- M-Pesa integration
- bank/payment-provider integration
- payment callbacks/webhooks
- idempotent payment confirmation
- automated reconciliation
- customer payment experience

No payment provider should become the source of truth for the commercial state. IMBOP's billing ledger remains authoritative for the application's billing state.

## Design principle

> **Money movement and billing state are related, but they are not the same thing.**

A payment provider can tell IMBOP that money moved.

IMBOP must still determine:

- which institution paid
- which invoice was intended
- how much was allocated
- whether the invoice is settled
- whether there is an overpayment
- whether there is an outstanding balance
- what communication should be issued
- what audit event should be recorded

## Acceptance principle

Before connecting real payment rails, the billing domain should be able to answer:

> **Who owes what, for which period, under which plan, what has been received, what has been allocated, what remains outstanding, and who changed the record?**
