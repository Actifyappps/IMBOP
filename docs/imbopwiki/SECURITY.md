# IMBOPwiki — Security

## 1. Security Boundary
The database and authorization layer are the security boundary.

UI hiding is not authorization. API route protection alone is not sufficient.

IMBOPwiki must use the existing IMBOP multi-tenant security model and Supabase/Postgres Row Level Security (RLS).

## 2. Tenant Isolation
Institution-scoped records must carry appropriate institutional context. Authorization must prevent a user from reading or mutating another institution's restricted content merely by changing an ID, route, query parameter or request payload.

Security tests must include both **ALLOW** and **DENY** cases.

## 3. Access Dimensions
Access may depend on authentication, institution membership, membership status, community membership, role, content visibility, publication state, ownership/contributor relationship and platform permissions.

## 4. Visibility Classes
- PUBLIC
- AUTHENTICATED
- INSTITUTION
- COMMUNITY
- PRIVATE WORKING GROUP

Visibility never overrides a stronger authorization rule.

## 5. Publication vs Authorization
Publication controls discoverability. Authorization controls access and mutation. Both are required.

## 6. Direct Access
Sensitive records remain protected through direct route/API/database access. Test UI, route, API/RPC, database query, search, related content and notification payloads.

## 7. Active Membership
Authenticated participation requiring membership should require an active membership state. Pending, suspended, removed or unrelated users are not authorized participants.

## 8. Role Separation
Roles are scoped: platform administrator, institution administrator, contributor, editor/reviewer, community manager, moderator and ordinary participant. One role must not silently grant unrelated authority.

## 9. Auditability
Security-sensitive actions should establish who, what, when, scope, prior state and resulting state.

## 10. Search and Caching
Search indexes and public caches must respect visibility. Private records must not leak through search snippets, related-content lists, cached pages, public metadata or notification previews.

## 11. External Channels
WhatsApp, email, SMS and other channels are distribution mechanisms, not the authorization boundary. Sensitive actions return users to authenticated IMBOP workflows.

## 12. Security Testing
Before production certification test authenticated allow, unauthenticated deny, wrong-institution deny, wrong-community deny, wrong-role deny, inactive-membership deny, direct-ID deny, unpublished-content deny, public-published allow and mutation permission checks.

## 13. Principle
**RLS and server-side authorization decide. The interface explains.**
