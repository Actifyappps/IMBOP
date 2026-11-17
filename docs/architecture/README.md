# IMBOP Architecture

This directory contains the authoritative architecture notes for the IMBOP application.

## Layers

1. **Public experience** — discovery and application entry.
2. **Application layer** — authenticated portals and workflows.
3. **Business/domain layer** — institutions, memberships, businesses and opportunities.
4. **Data/security layer** — Supabase PostgreSQL, RLS, storage and audit.
5. **Delivery layer** — GitHub, Vercel and Cloudflare.

## Tenant boundary

The institutional tenant boundary is enforced in PostgreSQL. UI filtering is not a security control.

Primary tenant key:

`institution_id`

Cross-institution access must be explicitly authorised and tested.
