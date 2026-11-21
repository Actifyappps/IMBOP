# IMBOPwiki — Migration Design Gate

**Status:** Design only — no database migration authorized.

## Migration sequence

### 1. Preconditions
- Confirm current production schema snapshot.
- Confirm reused helper functions and permission names.
- Confirm existing communications inbox/read model.
- Confirm existing media/storage policies.
- Confirm no billing dependency.

### 2. Additive schema
Create only wiki-specific tables: wiki_spaces, wiki_communities, wiki_community_memberships, wiki_topics, wiki_content, wiki_content_versions, wiki_content_topics, wiki_discussions, wiki_discussion_entries, wiki_content_links, wiki_content_reviews.

Do not create a second notification/delivery system unless a verified gap remains.

### 3. Constraints
Enforce state/visibility combinations, scoped slugs, version uniqueness, valid current/published version references, publication metadata, parent/context coherence, explicit link target types and role/state validity.

### 4. RLS
Enable RLS on every wiki table before granting exposed access. Implement policies from RLS-TEST-MATRIX.md.

### 5. Governance functions
Implement narrow server-side state transitions for submit, publish, return, reject, unpublish, archive, community activation/pause/archive and moderation. Preserve review evidence.

### 6. Communications
Emit approved wiki events into the existing Communications Infrastructure. No second queue or provider adapter.

### 7. Verification
Before release: constraints tests; RLS permitted/denied tests; publication/version tests; membership-removal tests; cross-object link tests; notification side-door tests; advisors; migration diff inspection; confirmation that no unrelated tables changed.

### 8. Production rule
No IMBOPwiki production migration is authorized by this document. Production implementation begins only after migration SQL and test fixtures are checked against the frozen model.
