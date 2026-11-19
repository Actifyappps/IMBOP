# IMBOP Repository Structure

## Purpose

The repository is the engineering source of truth for IMBOP. Its structure separates route surfaces, reusable UI, domain capabilities, shared infrastructure, Supabase backend assets, tests and documentation.

## Platform architecture at a glance

IMBOP is one shared, multi-tenant institutional economic network platform.

The major capability domains are:

- **Institution & Membership** — institutional identity, lifecycle, authorisation and IMBOP Onboards.
- **Applications & Publication** — application intake, review, approval, draft, submission and publication governance.
- **Economic Network** — businesses, profiles, offers, needs, opportunities, discovery, enquiries and introductions.
- **Communications** — event-driven in-app/email communications and delivery audit.
- **Administration & Reporting** — SE platform administration, institution administration and institutional reporting.
- **Billing & Payments** — pricing, billing accounts, invoices, payment intents, payments, allocations, receipts, settlement, reconciliation, refunds and billing audit.
- **Security & Infrastructure** — PostgreSQL/RLS, storage, Edge Functions, authentication and shared adapters.

## Boundary model

`src/app/` is the Next.js App Router surface. It defines URLs and page composition.

`src/components/` contains reusable presentation components.

`src/features/` contains domain capabilities and business logic. Feature modules are introduced deliberately as capabilities mature.

`src/lib/` contains cross-cutting infrastructure and shared adapters.

`supabase/migrations/` is the authoritative database evolution history.

`supabase/functions/` contains server-side/Edge Functions, including controlled provider adapters.

`supabase/tests/` contains database and security validation.

`tests/e2e/` contains end-to-end application tests.

`tests/security/` contains application/security regression tests.

`docs/` records architecture, product decisions, security, commercial domains and delivery discipline.

## Current route domains

- Public: home, discovery, plans, application, contact, privacy, terms
- Institution: institution space and institution administration
- Member: member access and workspace
- SE platform administration: controlled platform administration
- Billing: institution billing and payment experience
- Workspace: authenticated role routing

## Commercial domain

Billing is a first-class platform capability, even where its implementation is distributed across route surfaces, feature modules, database migrations and Edge Functions.

Its canonical flow is:

**PRICING → BILLING ACCOUNT → INVOICE → PAYMENT INTENT → PAYMENT → ALLOCATION → RECEIPT → RECONCILIATION → REFUND → AUDIT**

The institution is the IMBOP customer. The commercial unit is **IMBOP Onboards**.

Provider integrations remain adapters around the IMBOP ledger. The database remains authoritative for financial state.

## Engineering rule

Do not reorganise code for appearance alone. Move code when the new boundary improves ownership, testability, security review, reuse or future development.

Every structural move must be followed by import/build verification and route regression testing.

Financial changes additionally require database, authorization, idempotency, reconciliation and audit verification.
