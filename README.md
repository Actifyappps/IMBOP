# IMBOP

## Institutional Members Business & Opportunities Platform

**Institutional Economic Network Infrastructure**

**Owner:** Saintsway Equity (SE)  
**Development & Hosting Partner:** Actify Inc.  
**Repository:** Actifyappps/IMBOP  
**Primary branch:** `main`

IMBOP is an institutional economic network platform designed to help trusted institutions organise their authorised members, member businesses, offers, needs and opportunities into a governed digital economic space.

It is built around one simple model:

> **Institution → Authorised Members → Businesses → Opportunities**

And one central institutional proposition:

> **Give an institution a governed economic space for the people and businesses it already knows and trusts.**

---

# 1. What IMBOP Is

IMBOP stands for **Institutional Members Business & Opportunities Platform**.

Its broader category is:

> **Institutional Economic Network Infrastructure**

IMBOP is intended to become infrastructure that institutions can use to:

- establish their institutional presence on IMBOP
- authorise and onboard members
- maintain member and business profiles
- structure member businesses
- publish **I OFFER** opportunities
- publish **I NEED** requirements
- publish institutional or member **OPPORTUNITIES**
- allow authorised discovery
- capture enquiries
- facilitate introductions
- maintain institutional communications
- provide institutional reporting
- preserve governance and publication control

IMBOP is therefore not simply a website, directory or marketplace.

It is an **institution-governed economic operating space**.

---

# 2. The Problem IMBOP Exists to Solve

Institutions such as cooperatives, SACCOs, chamas, associations, business networks and other organised member groups often already possess:

- trusted people
- businesses
- skills
- products
- services
- assets
- needs
- relationships
- local knowledge
- economic opportunities

But this economic information is frequently fragmented across:

- WhatsApp groups
- spreadsheets
- paper records
- personal contacts
- social media
- disconnected websites
- informal referrals
- conversations that disappear after the moment

IMBOP is designed to provide a structured institutional layer above that fragmentation.

A useful working analogy is:

> **If WhatsApp is the town square, IMBOP is the institution's economic operating space.**

IMBOP's job is to help ensure that an economic opportunity does not disappear inside a conversation.

---

# 3. Core Value Proposition

### For Institutions

IMBOP gives an institution:

**A governed digital economic space for its authorised members.**

The institution can manage:

- who belongs
- who is authorised
- which member profiles are published
- which businesses are represented
- which offers and needs are published
- what institutional content is visible
- institutional communications
- institutional activity and reporting

### For Members

Members can progressively build an economic presence through:

**Profile → Business → Offer / Need / Opportunity → Discover → Enquire → Connect**

Members do not need to become users of a generic public marketplace first.

They enter through an institution that already knows and authorises them.

### For SE

SE provides the institutional infrastructure, platform governance, admission layer, commercial model and long-term operating framework.

---

# 4. The IMBOP Economic Network Model

## Core model

**Institution → Authorised Members → Businesses → Opportunities**

## Expanded network

**Institution**  
↓  
**Membership & Authorisation**  
↓  
**Member Profile**  
↓  
**Business / Enterprise**  
↓  
**I OFFER / I NEED / OPPORTUNITY**  
↓  
**Institutional Review**  
↓  
**Publication**  
↓  
**Discovery**  
↓  
**Enquiry**  
↓  
**Introduction**  
↓  
**Relationship**  
↓  
**Institutional Reporting**

## Public progression

**KNOW → DISCOVER → ENQUIRE → CONNECT → BENEFIT**

The platform is designed to turn an institution's existing trust network into structured economic visibility and activity without removing institutional control.

---

# 5. What IMBOP Is Not

IMBOP is deliberately **not**:

- a generic public directory
- a website builder
- a conventional e-commerce checkout marketplace
- a social media platform
- a generic social network
- an accounting system
- a banking platform
- an investment platform
- a loan platform
- a crowdfunding platform
- a replacement for an institution's existing governance
- a replacement for WhatsApp or other communication channels

IMBOP may integrate with or complement other systems over time, but its core responsibility is:

> **Institutional economic network infrastructure.**

---

# 6. The Governance Moat

The defining feature of IMBOP is not merely technology.

It is **institutional governance**.

The platform separates:

1. application
2. authorisation
3. preparation
4. review
5. publication
6. discovery
7. enquiry
8. relationship

This creates an important rule:

> **Application ≠ Publication.**

Anyone may apply.

That does not mean anyone is automatically published.

For institutions:

> **SE IMBOP decides whether an institution is admitted and published to the public IMBOP directory.**

For members:

> **The institution decides whether an authorised member and that member's content should be published.**

This distinction is foundational to the product.

---

# 7. Publication Authority

## Institution publication

The institution applies to IMBOP.

The application becomes a reviewable record.

SE reviews the institution through the appropriate platform process.

Only an institution approved and activated by SE becomes part of the public IMBOP institutional directory.

## Member publication

A person may apply to join an institution's IMBOP space.

The institution reviews and authorises the member.

The institution controls publication of the member's relevant profile, business and economic content.

## Content publication

Economic content follows:

**CREATE → SAVE DRAFT → SUBMIT → INSTITUTION REVIEW → PUBLISH**

Publication is an explicit governance action.

Editing does not automatically publish.

---

# 8. Canonical Lifecycle

The general content lifecycle is:

**DRAFT → SUBMITTED → PENDING REVIEW → PUBLISHED**

Correction:

**RETURNED → SUBMITTED → PENDING REVIEW**

Decision:

**REJECTED**

Removal:

**PUBLISHED → UNPUBLISHED**

The system preserves the distinction between:

- record existence
- authorisation
- publication state
- visibility
- verification state
- public discovery

A record is not public merely because it exists in the database.

---

# 9. Institutional Architecture

IMBOP is designed as one SE-owned platform with shared infrastructure and controlled institutional spaces.

It is **not** a collection of separately hosted institutional websites.

The conceptual architecture is:

**SE IMBOP Platform**  
↓  
**Institutional Network / Institution**  
↓  
**Institution Admin**  
↓  
**Authorised Members**  
↓  
**Member Businesses & Content**

Each institution receives its own controlled IMBOP space while remaining part of the wider IMBOP infrastructure.

An institution may have:

- its institutional identity
- institutional administrators
- authorised members
- businesses
- profiles
- offers
- needs
- opportunities
- announcements
- communications
- activity information
- plan information

The public can discover participating institutions, but institutional content remains governed by the applicable visibility and publication rules.

---

# 10. Institutional Separation

IMBOP is a shared multi-tenant system.

The institutional tenant key is primarily:

`institution_id`

Institutional separation is enforced at the **database/security layer**, not merely by hiding records in the user interface.

The browser is never trusted to determine institutional authority.

A browser-supplied `institution_id` is not proof of permission.

Access must be derived from:

- authenticated identity
- institutional membership
- role
- platform permissions
- database policies
- publication state
- visibility rules

PostgreSQL Row Level Security (RLS) is therefore a core part of the architecture.

---

# 11. Security Philosophy

> **The database is the security boundary.**

IMBOP must never rely on UI filtering as the primary security mechanism.

The platform must protect against:

- cross-institution data access
- tenant-ID manipulation
- unauthorised publication
- unauthorised administration
- inappropriate content visibility
- unauthorised media access
- privilege escalation
- unauthorised communication dispatch

Security tests should demonstrate both:

**PERMITTED ACCESS**

and

**DENIED ACCESS**

across multiple institutions and roles.

---

# 12. IMBOP User Surfaces

The platform is organised around three principal user surfaces.

## A. SE Platform Administration

SE controls the platform layer.

Primary areas:

**SE PLATFORM ADMINISTRATION**

- Institution Applications
- Institution Readiness
- Institution Lifecycle
- SE Admin Communications
- IMBOP Pricing & Plans

The SE administrator works from the question:

> **What needs SE's attention?**

The platform administration hierarchy is:

**Admin → Function → Record → Action**

---

## B. Institution Administration

The institution works from:

**INSTITUTION ADMIN**  
**[Institution Name]**

Command Centre:

**WHAT NEEDS MY INSTITUTION'S ATTENTION?**

Primary navigation:

- OVERVIEW
- MEMBERS
- APPLICATIONS
- IMBOP SPACE
- COMMUNICATIONS
- PLAN

Institution administration includes:

- member application review
- member approval
- member activation
- member publication
- business/content review
- institutional announcements
- institutional communications
- plan visibility
- onboarding progress
- institutional activity

---

## C. Member & Business Workspace

Members progressively manage:

- their member profile
- business / enterprise
- business profile
- I OFFER
- I NEED
- OPPORTUNITIES
- photos/media
- drafts
- submissions
- published content
- enquiries

The member's working progression is:

**PROFILE → BUSINESS → OFFER / NEED / OPPORTUNITY → DISCOVER → ENQUIRE**

---

# 13. Institutional Application

The institution application is intentionally separated from institutional readiness.

## Initial application

### ABOUT YOUR INSTITUTION

- Institution Name — required
- Brand Name — optional
- Logo — optional
- Institution Type — required
- Current Membership Estimate — required
- Website — optional

### WHERE YOU ARE

- HQ County — required
- HQ Location — required

### YOUR AUTHORISED CONTACT

- Contact Name — required
- Contact Role / Position — required
- Contact Email — required
- Contact Phone — required

### ABOUT THE INSTITUTION

- About the Institution — required
- Authorisation — required

The initial application is deliberately lightweight.

The following belong later in **Institution Readiness** rather than the first application:

- constitution
- registration certificate
- incorporation certificate
- registration number / authority
- governance documents
- financial documents
- other formal readiness evidence

This separation reduces application friction while preserving later institutional diligence.

---

# 14. Institution Readiness

Institution application and institutional readiness are separate concepts.

The intended progression is:

**APPLY → REVIEW → READINESS → APPROVE → ACTIVATE → OPERATE**

Readiness may include appropriate evidence concerning:

- legal identity
- registration
- governance
- authorised officers
- institutional structure
- membership
- operating status
- other information required by SE

The exact readiness requirements may evolve according to institution type and SE policy.

---

# 15. Institution Public Discovery

SE IMBOP public discovery is an **institutional directory**.

It is deliberately not a giant public directory of every individual member.

The model is:

**SE IMBOP Public Discover**  
↓  
**Institution**  
↓  
**Institution's IMBOP Space**  
↓  
**Members / Businesses / Offers / Needs / Opportunities**

The public discovery layer can show:

1. institution name
2. IMBOP Onboards
3. link to the institution's IMBOP space

## Terminology

People remain members of their institution.

They should not be casually described as "IMBOP Members".

The platform uses:

> **IMBOP ONBOARDS**

for the number of people onboarded into an institution's IMBOP space.

---

# 16. Public Institution Space

Each participating institution can have a public-facing IMBOP space subject to publication and visibility rules.

The space is designed to surface an institution's approved economic network.

Core public categories include:

- Businesses
- Offers
- Needs
- Opportunities

Only eligible, approved and published content should appear publicly.

The public space therefore communicates:

> **This institution has an organised economic network here.**

---

# 17. Business & Enterprise Layer

A member can have a business or enterprise associated with their institutional membership.

A business can then have a business profile.

The progression is:

**MEMBER → BUSINESS → BUSINESS PROFILE**

Business profile information may include:

- business name
- description
- sector
- value chain
- location
- business information
- public profile content
- images
- other approved information

Business profiles are subject to institutional publication governance.

---

# 18. Economic Content Model

IMBOP uses three primary economic content forms.

## I OFFER

A member or business can state:

> **I OFFER**

Possible information includes:

- Offer Title
- Short Summary
- Detailed Description
- Category
- Sector / Value Chain
- What exactly is being offered?
- Quantity / Capacity
- Location / Service Area
- Price / Pricing Basis — optional
- Availability
- Contact / Enquiry Preference
- Main Photo
- Additional Photos
- Supporting document — optional

---

## I NEED

A member or business can state:

> **I NEED**

Possible information includes:

- Need Title
- Short Summary
- Detailed Description
- Category
- Sector / Value Chain
- What exactly is needed?
- Quantity / Requirement
- Preferred Location
- Budget / Expected Value — optional
- Required By / Timing
- Contact / Enquiry Preference
- Main Photo where useful
- Additional Photos / Reference Images
- Supporting document

---

## OPPORTUNITY

An opportunity can include:

- Opportunity Title
- Short Summary
- Detailed Description
- Opportunity Type
- Sector / Value Chain
- Location
- Who is it for?
- What is being proposed?
- Opportunity Size / Scale
- Timeline
- Commercial / Participation Terms
- Contact / Enquiry Preference
- Main Photo
- Additional Photos
- Supporting documents

---

# 19. Media Strategy

Photos are part of the economic discovery experience.

The preferred progression is:

**APPLY → APPROVE → COMPLETE PROFILE → PUBLISH → DISCOVER**

Recommended media:

### Member

- Profile photo — recommended

### Business

- Business / enterprise photo — recommended
- Logo — optional
- Additional photos — optional

### Institution

- Institution logo — optional
- Institution hero imagery — optional

### Economic content

- Offer photo — optional
- Need photo/reference image — optional
- Opportunity photo — optional
- Supporting document — optional

Media is governed by ownership, institutional tenancy, visibility and publication rules.

Public media should only become publicly accessible when the associated content is appropriately published.

---

# 20. Discovery & Enquiry

IMBOP is not intended to stop at displaying information.

The economic loop is:

**DISCOVER → KNOW → ENQUIRE → CONNECT → BENEFIT**

Public or institutional discovery can lead to an explicit enquiry.

An enquiry is recorded against the relevant target:

- Business
- Offer
- Need
- Opportunity

The target must satisfy the applicable publication and visibility rules.

The enquiry then becomes an institutional economic event rather than a message that simply disappears into a chat.

---

# 21. Introduction & Relationship

IMBOP is not designed to replace the relationship.

It is designed to help create and structure the path toward the relationship.

The intended sequence is:

**DISCOVER → ENQUIRE → INTRODUCTION → RELATIONSHIP**

The actual commercial or social relationship can then continue through whatever channel the parties appropriately choose.

IMBOP's responsibility is to make the opportunity discoverable, governed and traceable up to the appropriate handoff.

---

# 22. Communications Infrastructure

IMBOP has a dedicated communications domain.

Canonical model:

> **EVENT → COMMUNICATION → DELIVERY → AUDIT**

Communication channels begin with:

- in-app
- email

Future channels may include:

- SMS
- WhatsApp
- other approved channels

Not every event should automatically generate an email.

The principle is:

> **Every important IMBOP event should be capable of generating a recorded communication, but not every event should automatically generate an email.**

Communication categories include:

- System Notifications
- SE Admin Communications
- Institution Communications
- Applicant Communications
- Member Communications
- Pricing & Billing Communications

Important events include:

- institution application received
- institution application returned
- institution application approved
- institution activated
- member application received
- member approved
- member rejected
- 50-Onboard milestone
- pricing plan changed
- transition payment notice
- payment reminder
- platform notice

Communications are not the authority for the event. They communicate an event that belongs to another domain.

---

# 23. Authentication

IMBOP authentication is intended to support:

- email/password login
- password reset
- secure session handling
- role-aware access
- institution-aware workspaces

The platform must preserve the distinction between:

- unauthenticated public discovery
- authenticated member activity
- institution administration
- SE platform administration

---

# 24. Member Activation

An approved member should ultimately be bridged from an application record into a real authenticated account and institutional membership.

The intended progression is:

**APPLICATION → APPROVE & PUBLISH → INVITE / ACTIVATE → MEMBERSHIP → MEMBER WORKSPACE**

Where appropriate, existing accounts may be linked rather than creating duplicates.

Member activation must preserve institutional tenancy and role boundaries.

---

# 25. Pricing & Commercial Model

The institution is the IMBOP customer.

Individual members are not directly billed for ordinary institutional IMBOP participation.

The foundational commercial model is based on the number of **IMBOP Onboards**.

## Founding threshold

> **The first 50 IMBOP Onboards are FREE.**

The intended public plan structure is:

| IMBOP Onboards | Monthly Plan |
|---|---:|
| 0–50 | FREE |
| 51–100 | KES 7,500 |
| 101–500 | KES 15,000 |
| 501–1,000 | KES 25,000 |
| 1,001–5,000 | KES 50,000 |
| 5,001–10,000 | KES 75,000 |
| 10,001–25,000 | KES 100,000 |
| 25,001–50,000 | KES 150,000 |
| 50,001+ | NEGOTIATED |

Higher-range institutional arrangements may be negotiated.

### Transition principle

When an institution crosses the founding threshold, the transition can be communicated as:

> **Congratulations — your Institution is growing. Your Institution has moved beyond the first 50 IMBOP Onboards. For this transition month, simply pay the discounted minimum of KES 5,000. From next month, your IMBOP plan will follow your Institution's actual number of IMBOP Onboards.**

The **KES 5,000 transition amount is the total discounted invoice for that transition month**. It is not added to the normal plan fee.

Pricing is intended to sell an **institutional outcome**, not a list of software features.

---

# 26. Founding Institution Programme

The platform is designed to support a founding institution adoption model.

A founding institution can establish its IMBOP space and onboard an initial cohort.

The working founding model includes:

> **Up to 50 IMBOP Onboards free during the pilot/founding stage.**

The purpose is to prove institutional value before the institution reaches paid scale.

The commercial model can evolve as real institutional adoption data accumulates.

---

# 27. Billing & Payments

Billing is an integrated IMBOP platform domain. It is not a separate product.

The commercial chain is:

> **PRICING → BILLING ACCOUNT → INVOICE → PAYMENT INTENT → PAYMENT → ALLOCATION → RECEIPT → RECONCILIATION → REFUND → AUDIT**

## Billing customer

The **Institution** is the IMBOP customer.

Individual institution members are not directly billed for ordinary IMBOP participation.

The commercial unit is the number of **IMBOP Onboards**.

## Billing foundation

The platform supports:

- institution billing accounts
- plan and pricing resolution
- invoice creation
- invoice lines
- full and partial payments
- payment allocations
- payment intents
- payment receipts
- payment status tracking
- overdue invoice handling
- settlement accounts
- bank-transfer payment references
- bank statement imports
- bank statement reconciliation
- payment refunds
- billing events and audit history
- institution-facing billing dashboard
- SE administration billing controls

## Payment architecture

IMBOP uses a **provider-neutral internal ledger**.

The internal ledger remains authoritative for:

- what the institution owes
- what has been received
- what has been allocated
- what remains outstanding
- what has been refunded
- what has been reconciled

External payment providers are adapters around that ledger.

The platform therefore does not treat a provider callback, checkout screen or browser response as the financial source of truth.

## M-PESA

M-PESA is supported through a controlled server-side payment-provider adapter.

The payment flow supports:

**PAYMENT INTENT → STK PUSH → CALLBACK / STATUS QUERY → PROVIDER VALIDATION → LEDGER FINALISATION → RECEIPT**

Provider credentials remain outside the repository.

Live payment activation is configuration-controlled and must not be assumed merely because the adapter exists.

## Bank transfer

Bank transfer is supported through controlled payment references and settlement reconciliation.

The institution receives a payment reference.

A settlement entry can then be matched against:

- payment reference
- amount
- institution
- invoice

Successful reconciliation creates the corresponding internal payment and allocation while preserving an audit trail.

## Refunds

Refunds are treated as controlled financial events.

The system records:

- original payment
- refund amount
- refund status
- provider/reference information
- reason
- requesting authority
- confirmation
- resulting invoice status

A refund must not silently alter the ledger.

## Financial security rules

The billing layer enforces, at database level where appropriate:

- institution tenancy
- authenticated role boundaries
- confirmed-payment requirements
- payment/invoice institution matching
- positive allocation amounts
- invoice over-allocation protection
- duplicate provider-reference protection
- payment-intent amount limits
- payable-invoice checks
- refund bounds
- service-only financial mutations
- auditable financial events

No direct anonymous or ordinary authenticated client write should bypass the controlled billing operations.

## Regulatory boundary

IMBOP is an institutional economic network platform, not a bank or payment processor.

Payment execution remains dependent on appropriately authorised external payment providers and financial institutions.

IMBOP owns the commercial ledger, billing workflow, reconciliation and audit layer required for its platform operation.

Detailed implementation decisions are documented in:

docs/architecture/billing.md

---

# 56. Institutional Reporting

IMBOP should ultimately help institutions understand their economic network.

Institutional reporting may include:

- member onboarding
- active members
- businesses
- published profiles
- offers
- needs
- opportunities
- enquiries
- introductions
- activity
- communications
- growth toward pricing thresholds

Reporting should remain subordinate to the institution's actual governance and data permissions.

---

# 28. Auditability

Important actions should be traceable.

Examples include:

- application submission
- application review
- approval
- rejection
- institution activation
- member approval
- member activation
- content submission
- publication
- return
- rejection
- unpublication
- enquiry
- communication
- administrative action

The platform should preserve sufficient audit information to answer:

**Who did what, to which record, when, and under what authority?**

---

# 29. Data & Tenant Model

Core conceptual entities include:

- institutions
- institution networks
- users
- memberships
- roles
- businesses
- business profiles
- offers
- needs
- opportunities
- enquiries
- introductions
- verification
- visibility
- media
- communications
- audit events
- pricing plans
- billing accounts
- billing invoices
- invoice lines
- payment intents
- payments
- payment allocations
- receipts
- settlement accounts
- bank statement imports and entries
- payment refunds
- billing events / audit records

The principal tenant boundary is:

`institution_id`

Multiple institutional memberships are supported conceptually.

However:

> **Membership in one institution does not automatically grant access to another institution's data.**

---

# 30. Technical Architecture

The current baseline is:

- Next.js
- TypeScript
- Tailwind CSS
- shadcn/ui
- Supabase PostgreSQL
- Supabase Auth
- PostgreSQL RLS
- Supabase Storage
- Vercel
- Cloudflare
- GitHub
- Playwright
- Supabase CLI / pgTAP

The application is intended to be:

- mobile-first
- responsive
- usable on Android
- usable on iPhone
- usable on tablets
- usable on desktop
- progressively enhanced for low-bandwidth environments

A PWA can be introduced as appropriate.

Native mobile applications are not required for the MVP.

---

# 31. Architectural Principles

IMBOP should favour:

- one coherent platform
- shared multi-tenant infrastructure
- database-enforced tenancy
- explicit publication governance
- simple services
- clear domain boundaries
- auditable actions
- secure media
- controlled communications
- progressive enhancement

Avoid unnecessary:

- microservices
- Kubernetes
- blockchain
- AI matchmaking as a core dependency
- separate databases per institution
- native apps during MVP
- custom payments unless justified
- feature complexity that does not strengthen the institutional economic model

---

# 32. Storage & Media Security

The main IMBOP media layer is private by default.

Media is associated with:

- institution
- owner
- entity type
- entity
- media type
- storage path
- visibility
- publication state

Visibility levels include:

- PRIVATE
- INSTITUTION
- PUBLIC

Public visibility must be earned through the appropriate publication process.

Application-stage institution logos are handled separately through a constrained private application-upload flow.

Anonymous public uploads are not the default model.

---

# 33. Application vs Publication

This principle should remain visible throughout the product.

### Application

Creates a record for consideration.

### Approval

Confirms institutional/platform authorisation.

### Preparation

Allows the authorised party to complete the record.

### Submission

Requests review.

### Publication

Makes the approved content eligible for its intended audience.

### Discovery

Allows users to find published content.

### Enquiry

Creates an explicit economic signal.

This separation is one of IMBOP's strongest governance features.

---

# 34. Public vs Institutional vs Private Visibility

The platform should distinguish:

### PRIVATE

Only authorised owners/roles can access.

### INSTITUTION

Visible within the relevant institution subject to permissions.

### PUBLIC

Eligible for public discovery, subject to publication and other controls.

Visibility is not a substitute for authorisation.

A record may be public-facing only after the relevant governance requirements have been satisfied.

---

# 35. IMBOP Public Front

The public front should communicate the product simply.

Core message:

> **IMBOP**  
> **Institutional Members Business & Opportunities Platform**  
> **Institutional Economic Network Infrastructure**

Supporting proposition:

> Connecting members and their businesses, offers and needs.

The institutional invitation is:

> **ARE YOU A MEMBER OF AN INSTITUTION?**

Cooperative, SACCO, Chama, Business Network, Group...

The intended call is:

> **ASK YOUR INSTITUTION TO APPLY TO IMBOP** if it hasn't yet, and create a **MEMBERS-ONLY SPACE** for member profiles, businesses, offers, needs and updates.

The public progression remains:

> **EXPLORE. KNOW. DISCOVER. ENQUIRE. CONNECT.**

---

# 36. Public Institution Directory

The public directory should answer:

**Which institutions participate in IMBOP?**

It should not attempt to expose every member as the first public navigation layer.

Core controls include:

- institution search
- alphabetical filtering
- A–Z navigation
- IMBOP Onboard range filtering
- participating institution count
- institution profile links

The directory is therefore a **network-of-institutions discovery layer**.

---

# 37. Content Governance

Economic content follows a controlled handoff.

### Member

**CREATE → SAVE DRAFT → SUBMIT**

### Institution

**MOVE TO REVIEW → PUBLISH / RETURN / REJECT**

### Public

**DISCOVER → KNOW → ENQUIRE**

This ensures that the institution remains the governance layer between member-created content and public visibility.

---

# 38. Communications Governance

Communications should not silently change business state.

For example:

- an application is approved by an application workflow
- communication tells the applicant that it was approved
- publication is controlled by publication authority
- communication records that event

This keeps domain ownership clean.

---

# 39. Platform Administration Governance

SE platform administration should remain separated from institution administration.

### SE

Controls:

- platform admission
- institution lifecycle
- platform permissions
- pricing
- platform communications
- platform-level configuration
- platform-level governance

### Institution

Controls:

- member authorisation
- member publication
- member content review
- institution communications
- institution economic space

### Member

Controls, subject to institution rules:

- own profile
- own business information
- own offers
- own needs
- own opportunities
- own media
- submissions

---

# 40. Source-of-Truth Hierarchy

Different systems have different authority.

| Layer | Authority |
|---|---|
| **Notion** | Product, operating and approved specification |
| **GitHub** | Application source code and reviewed repository configuration |
| **Supabase** | Application data, database schema and security enforcement |
| **Vercel** | Build, deployment and production serving |
| **Browser** | User-facing runtime evidence |

No layer silently replaces another.

In particular:

- Vercel is not the source of application code.
- Supabase dashboard state is not a substitute for reviewed migrations/configuration.
- Browser behaviour is evidence, not proof of underlying authorization.
- Production-only fixes must not become undocumented source drift.

---

# 41. Repository Rules

GitHub is the source of truth for application code.

Every material production change should be traceable to a repository commit.

Rules:

- keep secrets out of Git
- keep migrations reviewable
- keep security policies reviewable
- verify file contents after material writes
- do not make undocumented production-only code changes
- keep test evidence close to the relevant change
- do not bypass RLS to make a UI work
- do not treat successful rendering as proof of authorization
- prefer simple architecture over unnecessary services

---

# 42. Delivery & Engineering Discipline

Every material change follows:

> **Diagnose → Isolate → Fix → Test → Regression-check → Verify Source → Deploy → Verify Production**

A successful build alone is not sufficient.

A change is accepted only after the relevant:

- code
- database
- security
- runtime
- publication
- tenant
- communications
- production

behaviour has been checked.

---

# 43. Testing Philosophy

Tests should cover both functionality and authority.

Minimum expectations, depending on the change:

- route loads
- form validation
- RPC contract
- database constraints
- RLS
- tenant isolation
- role boundaries
- publication lifecycle
- visibility rules
- media permissions
- enquiry permissions
- communications
- runtime errors
- production deployment

Security tests should include deliberate denied-access attempts.

---

# 44. Current Delivery Gates

The working platform gates are:

### Gate 1 — Core Lifecycle

Platform administration, institution administration and institution lifecycle.

### Gate 2 — Tenant Security

Two-institution RLS and role-boundary testing.

### Gate 3 — Public Application & Publication

**Apply → Review → Publish → Discover → Enquire → Introduce**

### Gate 4 — Legal & Privacy

Final approved public trust, legal and privacy layer.

### Gate 5 — Production Domain

Custom production domain after technical acceptance.

A gate is evidence-based.

A UI existing does not by itself mean the gate is complete.

---

# 45. Communications Infrastructure

The communications domain is explicitly separated under:

`src/features/communications/`

Canonical model:

> **EVENT → COMMUNICATION → DELIVERY → AUDIT**

The communications domain does not own:

- application decisions
- authorization
- publication decisions
- pricing decisions

It communicates approved events from those domains.

---

# 46. Future Product Direction

IMBOP is intended to grow toward a broader institutional economic infrastructure layer.

Potential future capabilities include:

- richer institutional dashboards
- member activity intelligence
- CSV member import
- stronger moderation/reporting
- improved low-bandwidth workflows
- export/deletion controls
- notification preferences
- broader communication channels
- institutional analytics
- structured introductions
- relationship tracking
- stronger verification
- institutional economic reporting
- appropriate integrations

These are directions, not assumptions that every feature belongs in the MVP.

---

# 47. Deliberate Non-Goals

Unless separately approved, IMBOP should not become:

- a super-app
- a generic social network
- an uncontrolled marketplace
- a banking application
- a lending platform
- an investment platform
- a payment processor
- a blockchain product
- an AI matchmaking product
- an accounting replacement
- a website-builder platform

Feature decisions should always be tested against the central question:

> **Does this strengthen IMBOP as institutional economic network infrastructure?**

---

# 48. Product Design Philosophy

The product should feel:

**TRUSTED**  
**STRUCTURED**  
**MODERN**  
**INSTITUTIONAL**  
**ACCESSIBLE**  
**ECONOMICALLY ACTIVE**

The interface should favour:

- clear hierarchy
- few words where possible
- strong actions
- obvious governance states
- clean white workspaces
- strong blue structure
- purposeful green actions
- restrained gold accents
- mobile-first interaction
- low cognitive load

The product should not feel like a complicated enterprise system simply because it has strong governance underneath.

---

# 49. SE Brand System

IMBOP is a child product of Saintsway Equity.

## Parent

**SAINTSWAY EQUITY**

*The Operating Infrastructure for Trusted MSME & Cooperative Ownership*

## Product

**IMBOP**

*Institutional Economic Network Infrastructure*

Preferred digital treatment:

> **SE Logo Mark + IMBOP**

### Brand colours

| Role | Colour | Hex |
|---|---|---|
| Primary / Trust Blue | Deep / Royal Blue | `#123B7A` |
| Growth / Action Green | Growth Green | `#2E8B57` |
| Premium Accent Gold | Bright Royal Gold | `#D4AF37` |
| Workspace White | White | `#FFFFFF` |
| Text / Structure | Deep Charcoal | `#1F2937` |
| Soft Surface | Light Neutral | `#F5F7FA` |

Colour principle:

> **Blue leads. Green drives action and growth. Gold accents. White gives the platform room to breathe.**

Logo rules:

- SE logo mark is the primary compact digital mark.
- Full SAINTSWAY EQUITY lockup is used for formal institutional contexts.
- Favicon/app icon uses the SE logo mark.
- Never stretch, distort, independently redraw or arbitrarily recolour the SE master mark.
- IMBOP remains clearly identifiable while staying within the SE brand family.

UI components should use central design tokens rather than arbitrary colours.

---

# 50. Suggested Information Architecture

A coherent future repository/documentation structure is:

```
/
├── README.md
├── docs/
│   ├── architecture/
│   ├── product/
│   ├── security/
│   ├── governance/
│   ├── communications/
│   ├── media/
│   ├── pricing/
│   ├── billing/
│   ├── delivery/
│   └── decisions/
├── src/
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── features/
│       ├── administration/
│       └── communications/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   │   └── provider adapters/
│   └── tests/
├── tests/
│   ├── e2e/
│   ├── security/
│   └── integration/
└── public/
```

The structure is intended to keep product behaviour, application code, database/security, tests and delivery evidence understandable to future contributors.

---

# 51. Developer Onboarding Principle

A developer joining IMBOP should be able to understand from this repository:

1. What IMBOP is.
2. Why it exists.
3. Who owns it.
4. Who develops and hosts it.
5. Who the users are.
6. What institutions control.
7. What SE controls.
8. How members enter.
9. How businesses are represented.
10. How offers, needs and opportunities work.
11. How publication works.
12. How public discovery works.
13. How enquiries work.
14. How communications work.
15. How pricing works.
16. How media works.
17. How tenancy works.
18. How security works.
19. What the technical stack is.
20. What is deliberately out of scope.
21. How changes must be tested.
22. Where source-of-truth authority resides.
23. What the current delivery gates are.
24. Where the product is intended to go.

The README is therefore both a **product blueprint** and a **technical orientation document**.

Detailed implementation decisions should live in the appropriate `docs/` files as the repository grows.

---

# 52. The IMBOP Product Loop

The entire platform can be understood as one controlled loop:

**INSTITUTION**  
↓  
**AUTHORISE**  
↓  
**ONBOARD**  
↓  
**PROFILE**  
↓  
**BUSINESS**  
↓  
**OFFER / NEED / OPPORTUNITY**  
↓  
**REVIEW**  
↓  
**PUBLISH**  
↓  
**DISCOVER**  
↓  
**ENQUIRE**  
↓  
**INTRODUCE**  
↓  
**RELATE**  
↓  
**REPORT**  
↓  
**GROW**

This is the economic operating loop IMBOP is being built to support.

---

# 53. The Strategic Thesis

IMBOP is built on a simple thesis:

> Institutions already have trust, people, businesses, information and relationships.

The missing layer is often not another social network.

The missing layer is:

> **structured institutional economic infrastructure.**

IMBOP is intended to provide that layer.

It converts:

**TRUST → STRUCTURE → VISIBILITY → DISCOVERY → ENQUIRY → CONNECTION → ECONOMIC ACTIVITY**

while keeping the institution in the governance loop.

---

# 54. Current Status

**Status:** Integrated platform / controlled production system  
**Owner:** Saintsway Equity  
**Developer / Hosting Partner:** Actify Inc.  
**Primary repository:** `Actifyappps/IMBOP`  
**Primary branch:** `main`

The core institutional lifecycle, publication governance, communications infrastructure and billing foundation are maintained as one controlled platform.

The billing foundation is designed for controlled rollout. Payment-provider credentials, live provider activation and production financial operations remain configuration- and evidence-dependent.

---

# 55. Final Working Principle

IMBOP should never become a collection of disconnected screens.

It should remain:

> **One institutional economic network infrastructure platform.**

When something fails, do not patch the visible symptom blindly.

Use:

> **Diagnose → Isolate the Fault → Fix the Correct Layer → Test → Regression-check → Verify Source → Deploy → Verify Production**

And when considering a new feature, ask:

> **Does this make IMBOP a better governed institutional economic network infrastructure?**

If yes, design it carefully.

If no, question why it belongs.

---

## Saintsway Equity

**SAINTSWAY EQUITY**  
*The Operating Infrastructure for Trusted MSME & Cooperative Ownership*

**IMBOP**  
*Institutional Economic Network Infrastructure*

**Institution → Authorised Members → Businesses → Opportunities**

**Know → Discover → Enquire → Connect → Benefit**

---

# 59. Integrated Billing Foundation

The IMBOP billing layer is part of the main platform architecture.

The repository contains the reviewed database migrations, controlled RPCs, provider adapter, institution-facing billing experience, administration controls, reconciliation foundation, refund foundation and structural validation tests required to operate the billing domain.

The intended operational model is:

**GitHub source & migrations → controlled database deployment → Vercel application build/deployment → verified runtime**

GitHub stores the reviewed source and migration definitions. **Supabase is the runtime data store. Vercel builds and serves the application.**

The billing system must remain subject to the same institutional governance principles as the rest of IMBOP:

> **No browser action, provider response or UI state is allowed to become an authority that the database and controlled platform operations should own.**

Before enabling live financial operations, the relevant migrations, authenticated flows, payment-provider sandbox flows, reconciliation paths, refund paths, security controls and production evidence must be verified.

---

## Saintsway Equity

**SAINTSWAY EQUITY**  
*The Operating Infrastructure for Trusted MSME & Cooperative Ownership*

**IMBOP**  
*Institutional Economic Network Infrastructure*

**Institution → Authorised Members → Businesses → Opportunities**

**Know → Discover → Enquire → Connect → Benefit**

**Price → Bill → Pay → Reconcile → Report**


## Documentation alignment

The repository structure described here is the target conceptual structure of the integrated platform. Physical feature directories are introduced only when real domain logic warrants them; billing is already a first-class platform domain even where its implementation spans route surfaces, database migrations, RPCs, Edge Functions and shared administration UI.

**GitHub → controlled Supabase database deployment → Vercel build/deployment → verified production runtime.**

GitHub stores reviewed source and migration definitions. Supabase remains the runtime data store. Vercel builds and serves the application.
