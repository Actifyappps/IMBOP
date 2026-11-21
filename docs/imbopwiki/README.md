# IMBOPwiki

## In-App Knowledge, Collaboration & Communications Layer

**Product:** IMBOP — Institutional Members Business & Opportunities Platform  
**Owner:** Saintsway Equity (SE)  
**Development & Hosting Partner:** Actify Inc.  
**Repository:** Actifyappps/IMBOP  
**Branch:** `feature/imbopwiki-foundation`

---

## 1. Purpose

IMBOPwiki is a first-class, in-app knowledge, collaboration and communication layer for the IMBOP institutional economic network.

It is designed for institutions, authorised members and businesses to:

- discover useful knowledge
- share research and intelligence
- collaborate around economic issues
- discuss opportunities
- preserve institutional memory
- communicate with communities
- turn knowledge into enquiries, introductions and economic action

> **IMBOPwiki is the shared knowledge, collaboration and institutional-memory layer of the IMBOP economic network.**

---

## 2. What IMBOPwiki Is Not

IMBOPwiki is not:

- a document dump
- a generic social network
- an unrestricted discussion board
- a replacement for WhatsApp
- an automatic publication channel
- a standalone public wiki disconnected from IMBOP's economic objects

Its distinctive role is governed knowledge and collaboration **inside an institutional economic network**.

---

## 3. The IMBOPwiki Model

### Core IMBOP

**Institution → Authorised Members → Businesses → Opportunities**

### IMBOPwiki adds

**Knowledge → Communities → Discussion → Collaboration → Institutional Memory**

### Combined loop

**KNOW → DISCUSS → DISCOVER → ENQUIRE → CONNECT → ACT**

IMBOPwiki should remain connected to existing IMBOP objects rather than becoming a separate information silo.

---

## 4. Primary Content Types

### KNOWLEDGE

- Articles
- Research
- Reports
- Analysis
- Guides
- Case Studies
- Market Intelligence
- Regulatory Updates

### OPPORTUNITIES

- Export Opportunities
- Trade Opportunities
- Tenders
- Funding Calls
- Partnerships
- Procurement Opportunities
- Market Opportunities

### COLLABORATION

- Questions & Answers
- Discussions
- Polls
- Working Groups
- Collaborative Projects

### NETWORK

- Communities
- Events
- Announcements
- Institutional Notices
- Resources

---

## 5. Communities

Communities are first-class IMBOPwiki objects.

Potential examples:

- Agriculture
- Manufacturing
- Retail
- Exporters
- Cooperative Leaders
- Women Entrepreneurs
- Youth Enterprise
- Finance & Capital
- Technology
- Procurement
- Value Chains
- County Networks
- Import / Export
- Institution-specific communities
- Private working groups

Each community should have explicit:

- owner
- purpose
- audience / eligibility
- visibility
- membership rules
- moderation responsibility
- editorial responsibility where applicable
- lifecycle state

---

## 6. Access Philosophy

> **Open to discover; authenticated to participate.**

Possible visibility/access layers:

1. **PUBLIC** — explicitly published knowledge, opportunities and selected events
2. **AUTHENTICATED** — eligible authenticated participants
3. **INSTITUTION** — authorised members of a specific institution
4. **COMMUNITY / ROLE** — restricted by community or role
5. **PRIVATE WORKING GROUP** — invitation-based

Authentication must not silently grant editorial, moderation or community privileges.

Institutional tenancy and RLS remain the security boundary.

---

## 7. Governance & Publication

IMBOPwiki extends IMBOP's existing publication-governance philosophy.

Suggested content lifecycle:

**DRAFT → SUBMIT → REVIEW → APPROVE → PUBLISH → REVIEW / UPDATE → ARCHIVE**

Where applicable:

**RETURN FOR CORRECTION / REJECT / UNPUBLISH**

Principles:

- creating content does not publish it
- editing does not automatically publish it
- publication is an explicit governance action
- contributors are attributable
- material edits are auditable
- useful knowledge should remain maintainable
- restricted content must remain restricted

---

## 8. IMBOPwiki + WhatsApp

WhatsApp is a **distribution, notification and informal coordination channel**.

IMBOPwiki is the **knowledge, collaboration and institutional-memory layer**.

> **Conversation can happen elsewhere; valuable knowledge should accumulate in IMBOP.**

Example:

**IMBOPwiki**

Coffee Exporters Community  
→ new EU requirement  
→ discussion  
→ research  
→ resource  
→ affected businesses  
→ opportunity / action

**WhatsApp**

An authorised, opt-in notification points eligible members back to the relevant IMBOP content.

Restricted content must not be exposed through an external channel merely because a notification or link exists.

---

## 9. Communications Architecture

Separate the **IMBOP record** from the **distribution channel**.

Potential channels:

- In-app
- WhatsApp
- Email
- SMS
- Push notifications
- Future approved integrations

The IMBOP record remains authoritative.

Future capability:

> **Notify Community**

An authorised institution or platform role may select appropriate channels for a published item.

Notifications should point users back to the governed IMBOP record whenever possible.

---

## 10. Economic Integration

IMBOPwiki must connect to IMBOP's existing economic graph.

Examples:

### Opportunity

**Publish Export Opportunity → Members Interested → Business Offers → Enquiries → Introductions**

### Research

**Market Report → Discussion → Relevant Businesses → Offers / Needs → Opportunity**

### Regulatory update

**Regulatory Update → Discussion → Resource → Affected Businesses → Action**

### Question

**Member Question → Expert / Community Response → Reusable Knowledge**

This is the key distinction from a traditional wiki:

> **IMBOPwiki sits on top of an institutional economic network.**

---

## 11. Knowledge vs Conversation

The product should deliberately distinguish:

**Conversation**  
Short-lived interaction, questions, comments, informal coordination.

**Knowledge**  
Reviewed, attributable, reusable information that can remain useful after the original conversation ends.

A valuable discussion should be capable of becoming structured knowledge.

This is the central answer to the WhatsApp problem:

> **WhatsApp is excellent at conversation. IMBOPwiki should make useful knowledge accumulate.**

---

## 12. Integration Ladder

IMBOP is not limited to links or widgets.

External integration can mature through stages:

1. **LINK** — external profile/channel link
2. **WIDGET / EMBED** — approved external experience
3. **API INTEGRATION** — controlled data/action exchange
4. **NATIVE IMBOP ACTION** — action performed inside IMBOP
5. **DEEP WORKFLOW INTEGRATION** — coordinated end-to-end workflow

The same principle applies to WhatsApp, LinkedIn and future channels.

External platforms remain external systems; IMBOP remains the institutional source of governed records and workflows.

---

## 13. Governance Roles

The permission model should distinguish at least:

- Account identity
- Institutional membership
- Community membership
- Contributor
- Author / content owner
- Reviewer
- Publisher / approver
- Moderator
- Platform administrator

Membership alone must not silently elevate editorial or moderation privileges.

---

## 14. Data Concepts

Initial conceptual objects:

- wiki_spaces
- communities
- community_memberships
- knowledge_items
- discussions
- questions
- answers
- resources
- events
- polls
- projects
- comments
- reactions
- submissions
- review records
- publication records
- versions / revisions
- notifications
- communication deliveries
- moderation records
- audit events

Every institutional object requiring tenancy should carry the appropriate:

`institution_id`

Where cross-institution or public content is allowed, that authority must be explicit rather than inferred.

---

## 15. Security Principles

The existing IMBOP security philosophy continues unchanged:

> **The database is the security boundary.**

IMBOPwiki must not rely on UI filtering to enforce:

- institution separation
- community access
- publication authority
- moderation authority
- private working-group access
- content visibility
- external-channel eligibility

Required security evidence should include both:

**PERMITTED ACCESS**

and

**DENIED ACCESS**

across institutions, communities and roles.

---

## 16. Initial Product Shape

A future IMBOPwiki experience could expose:

**IMBOPwiki**

- Home
- Discover
- Communities
- Knowledge
- Opportunities
- Discussions
- Events
- Resources
- Notifications
- My Contributions
- My Communities

Institution administration may additionally manage:

- Institution Wiki
- Institution Communities
- Review Queue
- Publications
- Announcements
- Community Communications
- Moderation
- Institutional Knowledge

SE platform administration retains platform-level governance.

---

## 17. MVP Direction

The first implementation should prove the smallest complete governed loop, not build every social feature.

### MVP candidate

1. authenticated participation
2. public discovery of published items
3. community creation / membership
4. knowledge item creation
5. draft / submit / review / publish
6. comments / discussion
7. search / discovery
8. institutional tenancy
9. audit trail
10. in-app notifications
11. controlled WhatsApp notification/link integration
12. links from knowledge/opportunities into existing IMBOP economic records

Do not begin with a giant social feature set.

---

## 18. Sibling Learning: YetuCareWiki

YetuCareWiki is a reference sibling for IMBOPwiki.

The lessons to glean include:

- first-class in-app knowledge/community layer
- public discovery separated from authenticated participation
- communities as first-class objects
- governed contribution
- moderation
- durable, attributable knowledge
- WhatsApp as a complementary channel

IMBOPwiki should **learn from the architecture and experience, not copy YetuCare blindly**.

IMBOP's domain is institutional economic knowledge, business opportunity and member collaboration.

---

## 19. Repository Direction

Initial branch:

`feature/imbopwiki-foundation`

Recommended progression:

```
docs/
└── imbopwiki/
    ├── README.md
    ├── PRODUCT.md
    ├── INFORMATION-ARCHITECTURE.md
    ├── GOVERNANCE.md
    ├── SECURITY.md
    ├── COMMUNICATIONS.md
    ├── DATA-MODEL.md
    ├── INTEGRATIONS.md
    ├── MVP.md
    └── DECISIONS.md
```

Implementation should not begin until the product boundary, governance, tenancy and core information model are sufficiently settled.

---

## 20. Source of Truth

For IMBOPwiki:

- **Notion** — approved product and operating specification
- **GitHub** — reviewed implementation source and technical documentation
- **Supabase** — runtime data and database security
- **Vercel** — build/deployment/serving
- **Browser** — runtime evidence

No layer silently replaces another.

---

## 21. Working Principle

When considering an IMBOPwiki feature, ask:

> **Does this strengthen IMBOP as a governed institutional economic network?**

If yes, design it carefully.

If it merely recreates an existing social application without adding institutional value, question why it belongs.

---

## 22. Strategic Thesis

IMBOP's institutions already have:

**people + businesses + relationships + knowledge + opportunities**

IMBOPwiki adds the layer that allows that collective intelligence to become:

**discoverable + discussable + governed + reusable + actionable**

The ambition is not to create another social network.

It is to create:

> **A governed knowledge and collaboration commons for institutional economic networks.**
