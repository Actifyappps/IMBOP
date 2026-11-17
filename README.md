# IMBOP

## Institutional Members Business & Opportunities Platform

**Owner:** Saintsway Equity (SE)  
**Development & Hosting Partner:** Actify Inc.  
**Repository:** Actifyappps/IMBOP  
**Primary branch:** main

IMBOP is institutional economic network infrastructure that connects an institution, its authorised members, their businesses and structured business opportunities.

### Core model

**Institution → Authorised Members → Businesses → Opportunities**

### Core journey

**Institution → Membership & Authorisation → Business Profile → Offers & Needs → Discovery → Enquiry → Introduction → Relationship → Institutional Reporting**

### Public progression

**Know → Discover → Enquire → Connect → Benefit**

## Product boundaries

IMBOP is not a generic directory, website builder, conventional checkout marketplace, social network, accounting system, or investment/loan platform.

Its institutional moat is governance: institutions control who is authorised and what institutional content becomes public.

### Publication principle

> **Application ≠ Publication**

Anyone may apply. Only the authorised institution may publish.

Canonical publication lifecycle:

**DRAFT → SUBMITTED → PENDING REVIEW → PUBLISHED**

Correction path:

**RETURN FOR CORRECTION → RESUBMITTED → PENDING REVIEW**

Decision paths:

**REJECT → REJECTED**

Separate authorised removal:

**PUBLISHED → UNPUBLISHED / REMOVED**

## Technical baseline

- Next.js / TypeScript
- Tailwind CSS / shadcn/ui
- Supabase PostgreSQL
- Supabase Auth
- PostgreSQL Row Level Security (RLS)
- Supabase Storage
- Vercel
- Cloudflare
- GitHub
- Playwright
- Supabase CLI / pgTAP

### Security rule

IMBOP is a shared multi-tenant system.

The database is the security boundary. Every tenant-owned record is governed by an institutional tenant key such as `institution_id`, with PostgreSQL RLS enforcing access.

A browser-supplied `institution_id` is **never** proof of authority.

Tests must demonstrate both permitted and denied access across at least two institutions.

## Repository rules

- GitHub is the source of truth.
- Do not treat Vercel as the source of application code.
- Do not make production-only code changes that are absent from GitHub.
- Verify file contents after every material write.
- Keep secrets out of Git.
- Keep migrations and security rules reviewable.
- Prefer simple, testable architecture over unnecessary services.

## Planned structure

```
/
├── README.md
├── docs/
│   ├── architecture/
│   ├── product/
│   ├── security/
│   ├── delivery/
│   └── decisions/
├── src/
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── features/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── tests/
├── tests/
│   ├── e2e/
│   └── security/
└── public/
```

The structure is intentional: product behaviour, application code, database/security, tests and delivery evidence remain separable.

## Current delivery gates

1. **Gate 1 — Core lifecycle:** platform/institution administration and institution lifecycle.
2. **Gate 2 — Tenant security:** two-institution RLS and role-boundary testing.
3. **Gate 3 — Public application & publication:** apply → review → publish → discover → enquire → introduce.
4. **Gate 4 — Legal & privacy:** final approved public trust/legal layer.
5. **Gate 5 — Production domain:** custom production domain after technical acceptance.

## v1.1 direction

v1.1 is **Adoption & Institutional Value**.

Priority additions include:
- member activation and moderated updates
- institution activity dashboard
- CSV bulk member import
- moderation/reporting
- mobile-first and low-bandwidth operation
- export/deletion controls
- in-app notifications and preferences
- payment record-keeping only (subscription status, invoices, receipts)

Payment processing and rich social embeds are deferred.

## Development discipline

Every material change follows:

**Diagnose → Isolate → Fix → Test → Regression-check → Verify source → Deploy**

AI-assisted development must never bypass the repository, database authorization boundary, tests, or auditability.

---

**Status:** Active build  
**Owner:** Saintsway Equity  
**Developer / Hosting Partner:** Actify Inc.
