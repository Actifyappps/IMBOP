# IMBOPwiki — MVP

## 1. Objective
Deliver a useful, governed knowledge and collaboration layer inside IMBOP without turning the first release into a full social network.

## 2. MVP Must Have
### Knowledge
Create/edit, structured types, draft/save, submit, review, approve, publish, return/reject with reasons where applicable, archive/unpublish, attribution, timestamps and basic version history.

### Communities
Create/manage governed communities, membership/access, community roles and community content listing.

### Discussion
Discussion attached to content/community context, authenticated participation, replies and basic moderation controls.

### Discovery
Public published discovery, authenticated discovery, topic/category navigation, authorization-aware search and related content.

### IMBOP Integration
Links to economic objects, institution/member context, in-app notifications and reuse of existing audit/communications infrastructure.

### Security
RLS, institutional isolation, active-membership checks, role checks, direct-access tests and publication-state enforcement.

## 3. Not in MVP
Unless separately justified:
- AI matchmaking;
- algorithmic social feed;
- native mobile apps;
- blockchain;
- full real-time chat replacement;
- complex reactions/gamification;
- sophisticated recommendation engine;
- custom payment system;
- broad external social-media API integrations;
- separate databases per institution;
- microservices.

## 4. First Useful Release
A member can sign in, enter IMBOPwiki, discover a community, read published knowledge, participate in an authorized discussion, create/submit knowledge where permitted, receive notifications and move from knowledge to a relevant IMBOP business or opportunity.

An institution administrator can govern its community, review content, approve/return/reject, publish approved content, manage appropriate membership/roles and retain institutional knowledge.

## 5. Certification Mindset
MVP still requires production discipline: authenticated E2E, publication governance, tenant isolation, direct/API authorization, mobile/desktop checks, communication verification, fixture cleanup and audit evidence.

## 6. Build Sequence
1. schema design;
2. RLS and authorization;
3. server actions/RPCs;
4. content lifecycle;
5. community/membership;
6. discussion;
7. discovery/search;
8. notifications;
9. UI polish;
10. E2E certification.

## 7. MVP Rule
Build the smallest durable foundation that can support many institutional networks without creating a rewrite trap.
