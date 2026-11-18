# IMBOP Repository Structure

## Purpose

The repository is the engineering source of truth for IMBOP. Its structure separates routing, reusable UI, domain capabilities, infrastructure, database evolution, tests and documentation.

## Boundary model

`src/app/` is the Next.js App Router surface. It defines URLs and page composition.

`src/components/` contains reusable presentation components.

`src/features/` contains domain capabilities and business logic. Feature modules are introduced deliberately as capabilities mature.

`src/lib/` contains cross-cutting infrastructure and shared adapters.

`supabase/migrations/` is the authoritative database evolution history.

`supabase/functions/` contains server-side/Edge Functions.

`supabase/tests/` contains database and security validation.

`tests/e2e/` contains end-to-end application tests.

`tests/security/` contains application/security regression tests.

`docs/` records architecture, product decisions, security and delivery discipline.

## Current route domains

- Public: home, discovery, plans, apply, contact, privacy, terms
- Institution: institution space and institution administration
- Member: member access and application journey
- SE platform administration: controlled platform administration
- Workspace: authenticated role routing

## Engineering rule

Do not reorganise code for appearance alone. Move code when the new boundary improves ownership, testability, security review, reuse or future development.

Every structural move must be followed by import/build verification and route regression testing.
