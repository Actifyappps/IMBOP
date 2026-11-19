# ADR-0001 — IMBOP Repository Structure

**Status:** Accepted  
**Date:** 2026-11-18

## Decision

IMBOP will use a layered Next.js repository with explicit separation between route surfaces, shared UI, domain features, shared infrastructure, Supabase backend assets, tests and documentation.

The existing application remains under `src/app/`. Shared components move from the route tree to `src/components/`, and the shared Supabase client moves to `src/lib/`.

## Why

The product has grown beyond a single-page prototype. IMBOP now contains public discovery, institution spaces, institution administration, SE administration, publication controls, commercial pricing, communications and an integrated billing subsystem.

Keeping shared components and infrastructure inside `src/app/` couples reusable code to route location and makes future domain growth harder to reason about.

## Consequences

### Positive
- Clearer ownership boundaries
- Cleaner imports
- Easier feature extraction
- Better test placement
- Safer Communications, Pricing and Billing development
- Repository structure matches the Actify delivery discipline

### Constraints
- Route files must remain thin enough to preserve separation.
- Feature directories are created when there is real domain logic to place there, not as empty ceremony.
- Supabase migrations remain append-only except for deliberate history repair.
- Structural changes require build and route regression checks.

## Non-goals

This ADR does not convert IMBOP into a monorepo, microservice architecture or separate application packages. It does not change runtime architecture, tenancy model, RLS, publication authority or commercial rules. Billing remains a first-class domain while provider execution stays behind controlled adapters and the IMBOP ledger remains authoritative.
