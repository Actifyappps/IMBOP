# IMBOP Architecture

This directory contains the authoritative architecture notes for the IMBOP application.

## Layers

1. **Public experience** — discovery and institutional application entry.
2. **Application layer** — authenticated member, institution and SE workflows.
3. **Business/domain layer** — institutions, memberships, businesses, opportunities, communications, administration and billing.
4. **Data/security layer** — Supabase PostgreSQL, RLS, storage, controlled RPCs and audit.
5. **Provider/integration layer** — payment and communication adapters that do not replace IMBOP's domain authority.
6. **Delivery layer** — GitHub source and migrations, controlled database deployment, Vercel build/deployment and production verification.

## Core domain model

**Institution → Authorised Members → Businesses → Opportunities**

The economic loop is:

**AUTHORISE → ONBOARD → PROFILE → BUSINESS → OFFER / NEED / OPPORTUNITY → REVIEW → PUBLISH → DISCOVER → ENQUIRE → INTRODUCE → REPORT**

## Billing domain

Billing is a first-class commercial domain:

**PRICE → BILL → PAY → RECONCILE → REFUND → REPORT**

The institution is the customer and IMBOP Onboards are the commercial unit.

The internal ledger owns invoice, payment, allocation, receipt, reconciliation and refund state. External providers execute payment rails; they do not become the platform's source of truth.

## Tenant boundary

The institutional tenant boundary is enforced in PostgreSQL. UI filtering is not a security control.

Primary tenant key:

`institution_id`

Cross-institution access must be explicitly authorised and tested.

## Source-of-truth boundaries

- **GitHub** — reviewed application source and database migration definitions.
- **Supabase** — runtime application data and database/security enforcement.
- **Vercel** — application build, deployment and serving.
- **Browser** — user-facing evidence, never the authority for authorization.

No production-only change should silently become undocumented source drift.
