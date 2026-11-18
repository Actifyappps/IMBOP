# IMBOP

## Institutional Members Business & Opportunities Platform

**Owner:** Saintsway Equity (SE)  
**Development & Hosting Partner:** Actify Inc.  
**Repository:** Actifyappps/IMBOP  
**Primary branch:** `main`

IMBOP is **institutional economic network infrastructure** that connects an institution, its authorised members, their businesses and structured business opportunities.

### Core model

**Institution → Authorised Members → Businesses → Opportunities**

### Core journey

**Institution → Membership & Authorisation → Business Profile → Offers & Needs → Discovery → Enquiry → Introduction → Relationship → Institutional Reporting**

### Public progression

**Know → Discover → Enquire → Connect → Benefit**

---

## Product boundaries

IMBOP is not a generic directory, website builder, conventional checkout marketplace, social network, accounting system, or investment/loan platform.

Its institutional moat is **governance**: institutions control who is authorised and what member content becomes public, while SE controls institutional admission to the platform.

### Publication principle

> **Application ≠ Publication.**

Anyone may apply. Application creates a reviewable record; it does not itself make the applicant or its content public.

For institution members, the authorised institution controls publication of member content. For institutions, SE IMBOP controls publication/admission.

### Canonical application and publication lifecycle

**DRAFT → SUBMITTED → PENDING REVIEW → PUBLISHED**

Correction path:

**RETURN FOR CORRECTION → RESUBMITTED → PENDING REVIEW**

Decision paths:

**REJECT → REJECTED**

Separate authorised removal:

**PUBLISHED → UNPUBLISHED / REMOVED**

**Published** and **publicly discoverable** are related but distinct controls. A record must satisfy the applicable institution, publication, status and visibility rules before it appears in public discovery.

---

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

### Security boundary

IMBOP is a shared multi-tenant system.

The **database is the security boundary**. Tenant-owned records are governed by an institutional tenant key such as `institution_id`, with PostgreSQL RLS enforcing access.

A browser-supplied `institution_id` is **never** proof of authority.

Authorization must be derived from authenticated identity, membership, role and database policy—not from UI filtering.

Security tests must demonstrate both permitted and denied access across at least two institutions, including attempts to manipulate tenant identifiers from the browser.

---

## Source-of-truth hierarchy

Different systems have different authority:

| Layer | Authority |
|---|---|
| Notion | Product, operating and approved specification |
| GitHub | Application source code and reviewed repository configuration |
| Supabase | Application data, database schema and security enforcement |
| Vercel | Build, deployment and production serving |
| Browser | User-facing runtime evidence |

**No layer silently replaces another.**

In particular:
- Vercel is not the source of application code.
- Supabase dashboard state is not a substitute for reviewed repository migrations/configuration.
- A browser result is evidence of behaviour, not proof of underlying authorization.
- Production-only fixes must not be allowed to become undocumented source drift.

---

## Repository rules

- GitHub is the source of truth for application code.
- Every material production change must be traceable to a repository commit.
- Do not make production-only code changes absent from GitHub.
- Verify file contents after every material write.
- Keep secrets out of Git.
- Keep migrations and security rules reviewable.
- Keep test evidence close to the change it validates.
- Prefer simple, testable architecture over unnecessary services.
- Never bypass RLS merely to make a UI work.
- Never treat successful UI rendering as proof of authorization.

---

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
│       └── communications/
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

---

## Delivery discipline

Every material change follows:

**Diagnose → Isolate → Fix → Test → Regression-check → Verify source → Deploy → Verify production**

A successful build is not sufficient. A change is accepted only after the relevant runtime behaviour and security boundary have been checked.

### Minimum regression expectations

Depending on the change, verify:
- affected routes load successfully
- relevant database/RPC contracts still work
- tenant isolation remains intact
- role boundaries remain intact
- publication rules remain enforced
- public discovery reflects only eligible records
- runtime errors are checked
- the final deployed version maps to the intended Git commit

---

## Current delivery gates

1. **Gate 1 — Core lifecycle:** platform/institution administration and institution lifecycle.
2. **Gate 2 — Tenant security:** two-institution RLS and role-boundary testing.
3. **Gate 3 — Public application & publication:** apply → review → publish → discover → enquire → introduce.
4. **Gate 4 — Legal & privacy:** final approved public trust/legal layer.
5. **Gate 5 — Production domain:** custom production domain after technical acceptance.

Gate status is evidence-based. A gate is not considered complete merely because the relevant UI exists.

---

## Current platform direction

**v1.1 — Adoption & Institutional Value**

The platform now has an explicit **Communications Infrastructure** domain boundary under `src/features/communications/`. Its canonical model is **EVENT → COMMUNICATION → DELIVERY → AUDIT**, beginning with in-app and email channels. Communications does not own application, authorization, publication or pricing decisions; it communicates approved events from those domains.

Priority additions include:
- member activation and moderated updates
- institution activity dashboard
- CSV bulk member import
- moderation/reporting
- mobile-first and low-bandwidth operation
- export/deletion controls
- in-app notifications and preferences
- payment record-keeping only (subscription status, invoices, receipts)

Payment processing and rich social embeds are deferred unless separately approved.

---

## Working principle

IMBOP should be built as a controlled institutional system, not a collection of disconnected screens.

When something fails, we do not patch symptoms blindly:

**Diagnose → Isolate the fault → Fix the correct layer → Test → Regression-check → Verify source → Deploy → Verify**

**Status:** Active build  
**Owner:** Saintsway Equity  
**Developer / Hosting Partner:** Actify Inc.
