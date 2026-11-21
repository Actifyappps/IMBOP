# IMBOPwiki — Schema Challenge

## Status
**Challenge completed. No database migration is authorized by this document.**

This document deliberately tries to break the proposed IMBOPwiki schema before implementation.

## 1. Challenge Verdict

**SURVIVED WITH REQUIRED CORRECTIONS.**

The core model is sound, but the challenge exposed several places where the first blueprint could create ambiguity or accidental privilege:

1. a published content record must be separated from its latest working version;
2. wiki spaces must not become an extra authorization layer;
3. institutional membership must never imply access to a cross-institution community;
4. community membership is participation, not institutional authority;
5. content links must inherit the target object's own authorization;
6. notifications must never become an alternate access path;
7. membership removal must immediately affect private discussion/content access;
8. publication vocabulary should reuse IMBOP's existing vocabulary;
9. working groups can be represented as governed communities in MVP rather than creating another membership universe.

These are design corrections, not reasons to abandon the model.

## 2. One User, Multiple Institutions

A user may belong to Institutions A and B. Authorization must evaluate the target institution scope, not merely auth.uid(). Each institutional relationship is independent.

**PASS — explicit institution-scope predicates required in every RLS policy.**

## 3. Cross-Institution Community

A community such as Agricultural Exporters may contain members from Institutions A, B and C.

Institution membership alone does not grant community access. A cross-institution community is its own authorization context.

Access comes from active community membership, explicit public publication, or explicit platform authority.

**PASS.**

## 4. Private Working Group

A private working group may discuss a sensitive procurement opportunity.

Represent the working group as a governed private community in MVP. Require active membership/role. Knowing a UUID never bypasses RLS.

Do not create a second working-group membership universe unless later requirements prove it necessary.

**PASS.**

## 5. Public Content Becomes Private

If an article changes from public to institution-only, public discovery and public reads must stop based on current authorization. Search is a derived index, never an authority.

**PASS.**

## 6. Published Content Is Edited

This exposed the most important versioning correction.

The content record must distinguish:

- current_version_id = latest working version;
- published_version_id = version currently authorized for publication.

A new draft cannot silently replace the public version. The new version must pass the normal review/publication process before published_version_id changes.

**PASS after correction.**

## 7. RETURN / REJECT

Reuse IMBOP's existing publication vocabulary wherever possible:

DRAFT → SUBMITTED → PENDING_REVIEW → PUBLISHED

with controlled RETURNED, REJECTED and UNPUBLISHED states.

RETURN and REJECT retain attributable review evidence/reason where required by the existing governance contract.

**PASS.**

## 8. Cross-Tenant Content Links

A public article may link to a private business or opportunity.

A wiki link is a relationship, not a permission grant. The target object's own authorization always wins. A public article may contain a link whose target is unavailable to the viewer.

Target types must be an explicit allow-list.

**PASS.**

## 9. Discussion Access After Membership Removal

If a user leaves a private community, an old discussion URL must not preserve access.

Current community membership is checked at access time. Another independent authorization path must be present before access is allowed.

**PASS.**

## 10. Notification Leakage

Notifications are not authorization records.

A notification read must revalidate access to the referenced object. Notification creation must target eligible recipients. Notification bodies should contain minimal sensitive information.

If an existing IMBOP in-app notification mechanism satisfies the need, reuse it.

**PASS.**

## 11. Direct-ID / IDOR

Every exposed wiki table must use RLS. Knowing a UUID never bypasses scope.

TO authenticated is authentication, not authorization. SELECT, UPDATE and DELETE policies must independently enforce the correct scope.

**PASS.**

## 12. Moderation

Discussion moderation must be attributable and auditable.

Prefer ACTIVE → HIDDEN → REMOVED states over silent destructive deletion of governed discussion evidence.

Removed entries must disappear from ordinary participant queries.

**PASS.**

## 13. Deletion / Archiving

Governed published material should use controlled archive/unpublish semantics rather than casual hard deletion.

If draft deletion is eventually allowed, it must not leave orphaned versions, topics, discussions, links or notifications.

**PASS with retention policy still to be finalized.**

## 14. WhatsApp / API Future Integration

External channels must consume authorized published records through a governed integration layer. IMBOPwiki remains the source of truth.

Future exports must re-check publication and visibility at time of export. Existing communication/idempotency/audit infrastructure should be reused.

**PASS.**

## 15. Community Role Escalation

A community moderator may govern community participation but cannot grant themselves institution administration, platform administration or publication authority outside their granted scope.

**PASS.**

## 16. Scope Confusion

The first blueprint risked allowing space, institution, community and visibility fields to become competing authorization authorities.

Correction: wiki spaces are presentation/governance context only. They cannot independently grant access.

Authorization derives from publication/visibility, institution membership where institution-scoped, community membership where community-scoped, private-group membership, or platform authority.

**PASS after correction.**

## 17. Creator Leaves Institution

Creator identity and authorization are separate.

Losing institutional membership must not rewrite ownership or expose content. Editing rights are recalculated from current permissions.

**PASS.**

## 18. Stale Community Membership

Database authorization is authoritative. Cached membership may improve performance only where invalidation cannot weaken security.

Sensitive access checks must use current authorization state.

**PASS.**

## 19. Version History Leakage

Public access to an article does not imply access to its private draft history.

Public readers see only the authorized published version. Version history requires appropriate editing/review authority.

**PASS after explicit version-level authorization.**

## 20. Orphaned References

If a business, opportunity or community is archived or deleted, wiki references must degrade safely.

The wiki must not manufacture replacement records or retain unauthorized private details. Reference resolution checks current lifecycle and authorization.

**PASS.**

## 21. Schema Corrections Now Locked

A. **Two version pointers** — distinguish latest working version from published version.

B. **Spaces are not authorization** — retain only for organization/governance presentation if useful.

C. **Working groups are communities in MVP** — no separate membership universe initially.

D. **Publication vocabulary follows IMBOP** — avoid incompatible wiki-only lifecycle states.

E. **Community membership is independent** — institution membership does not automatically equal cross-institution community membership.

F. **Links do not grant access** — target authorization always wins.

G. **Notifications do not grant access** — notification visibility never creates object visibility.

H. **Published version is stable** — new drafts cannot silently replace public content.

I. **Version history is privileged** — public readers see the authorized published version only.

J. **RLS remains the final boundary** — interface behavior is never the security boundary.

## 22. Revised Risk Register

| Risk | Result | Treatment |
|---|---|---|
| Multi-institution user | Survives | Explicit institution scope |
| Cross-institution community | Survives | Independent community membership |
| Private working group | Survives | Private governed community |
| Public → private | Survives | Read-time authorization |
| Published edit | Caught | Separate current/published version |
| RETURN/REJECT | Survives | Reuse IMBOP states |
| Cross-tenant links | Survives | Target authorization |
| Membership removal | Survives | Re-evaluate at access |
| Notification leakage | Survives | Notifications never grant access |
| Direct-ID attack | Survives | RLS on every exposed table |
| Moderation | Survives | Attributable state transitions |
| Deletion/archiving | Survives | Controlled lifecycle |
| Future integrations | Survives | Source-of-truth + revalidation |
| Role escalation | Survives | Scope-bound permissions |
| Scope confusion | Caught | Space cannot grant access |
| Creator departure | Survives | Separate identity/authorization |
| Stale membership | Survives | DB authority |
| Version leakage | Caught | Version-level authorization |
| Orphaned references | Survives | Safe target resolution |

## 23. Final Challenge Verdict

**The schema survives the challenge after the corrections above.**

The next stage is:

**FREEZE THE PRODUCT + INFORMATION ARCHITECTURE → RECONCILE THE FINAL DATA MODEL → THEN WRITE A MIGRATION.**

No production schema has been changed by this challenge.
