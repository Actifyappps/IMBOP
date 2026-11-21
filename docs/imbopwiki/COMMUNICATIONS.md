# IMBOPwiki — Communications Integration
**Status:** Frozen for MVP engineering

## Rule
No second communications system.

**WIKI EVENT → COMMUNICATION → DELIVERY → AUDIT**

Reuse communication_records, communication_deliveries, templates/versioning, in-app inbox/read behaviour, email queue/dispatcher, provider evidence, idempotency, retries and audit.

## Wiki events
WIKI_CONTENT_SUBMITTED, WIKI_CONTENT_RETURNED, WIKI_CONTENT_REJECTED, WIKI_CONTENT_PUBLISHED, WIKI_CONTENT_UNPUBLISHED, WIKI_CONTENT_UPDATED, WIKI_COMMUNITY_INVITED, WIKI_COMMUNITY_ROLE_CHANGED, WIKI_DISCUSSION_MENTIONED, WIKI_MODERATION_ACTION.

Only approved events generate communications.

## Notification rule
A notification is a pointer to an IMBOP record, not authorization. Opening it re-checks access.

## Channels
MVP: In-App.
Email is reused through the existing infrastructure once its production sending-domain blocker is cleared.
Future: WhatsApp, SMS, Push and approved APIs.

External dispatch must re-check publication and visibility at dispatch time.

## Sensitive content
Private working-group content must never appear in notification previews to ineligible recipients. Prefer minimal previews when access is uncertain.