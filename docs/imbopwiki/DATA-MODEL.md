# IMBOPwiki — Conceptual Data Model

## 1. Design Principle
The data model extends IMBOP rather than creating a disconnected parallel platform.

## 2. Core Objects
### Wiki Content
A durable knowledge record: id, institution context, community context, author/member/user reference, content type, title, summary, body, visibility, lifecycle status, publication metadata and timestamps.

### Community
A governed group around a subject, institution, network or working purpose: identity, context, description, visibility, membership rules, status and governance owner.

### Topic
A reusable subject classification.

### Community Membership
Connects a user/member to a community with role and status.

### Content Version
Preserves meaningful revisions.

### Discussion
A structured conversation associated with content, community or another IMBOP object.

### Discussion Entry
An individual contribution to a discussion.

### Content Review
A governance decision/review event.

### Content Link
Connects knowledge to another wiki object or an IMBOP economic object.

### Notification
An in-app communication pointing a participant to a relevant record.

## 3. Relationship to Existing IMBOP Objects
Wiki content should reference, where authorized:
- institutions;
- institution networks;
- users;
- memberships;
- businesses;
- business profiles;
- products/services;
- offers;
- needs;
- opportunities;
- enquiries;
- introductions.

This lets knowledge point to relevant economic records without duplicating them.

## 4. Institutional Context
Institution-scoped records carry an institution identifier or derive it through an explicit secure relationship. Community-scoped records have clear community ownership/scope. Cross-institution communities require explicit policy.

## 5. Lifecycle Fields
A governed record must distinguish draft, submission, review, publication and archive states. Do not collapse these into a single boolean.

## 6. Visibility
Use controlled values such as public, authenticated, institution, community and private rather than arbitrary free text.

## 7. Versioning
A version preserves content identity, version number, author, durable content snapshot and created time, plus reason/context where required.

## 8. Governance Events
Retain reviewer, action, reason/notes where applicable, prior state, resulting state and timestamp.

## 9. Audit
Governance and security-sensitive changes feed the existing IMBOP audit approach rather than creating a second audit universe.

## 10. Notifications and Communications
Notification records reference the underlying event/object rather than duplicating complete content. External delivery records remain part of the existing communications architecture.

## 11. Search Model
Search is derived from authorized records and must not become an independent source of truth that bypasses RLS or publication state.

## 12. Implementation Rule
This document is conceptual. No database migration should be written until product boundaries, information architecture, governance, security and MVP scope are sufficiently stable.
