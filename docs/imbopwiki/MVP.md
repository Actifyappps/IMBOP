# IMBOPwiki — MVP Definition
**Status:** Frozen for engineering planning

## Objective
Prove one complete governed loop:
**CREATE → DRAFT → SUBMIT → REVIEW → PUBLISH → DISCOVER → DISCUSS → ACT**

## Included
- existing Auth and institutional memberships
- community membership and scope-aware RLS
- six MVP content types
- current vs published versioning
- global/institution/private communities
- governed submit/review/publish/return/reject/unpublish/archive
- first-class discussions and moderation
- authorized discovery/search
- typed links to existing IMBOP economic records
- existing in-app Communications
- attribution, audit and version history

## Outside MVP
Consumer social feed, AI matchmaking, native apps, blockchain, microservices, payments/billing, second identity system, second notification/delivery system, automatic publication, unrestricted public editing, per-institution databases.

## Acceptance gate
1. authorized public read
2. denied unpublished read
3. denied cross-institution read
4. denied private-community read without membership
5. access removed after membership removal
6. author draft
7. submit
8. reviewer return/reject with reason
9. publisher publish
10. working version does not replace published version until approved
11. public sees only published version
12. notification cannot bypass target authorization
13. moderator cannot escalate privilege
14. links cannot grant target access
15. archive/unpublish removes ordinary discovery