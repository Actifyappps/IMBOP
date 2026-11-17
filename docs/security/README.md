# IMBOP Security

## Non-negotiables

- PostgreSQL RLS is mandatory for tenant-owned data.
- Browser-supplied tenant identifiers never establish authority.
- Institution roles and platform roles are distinct.
- Public access is limited to intentionally published records.
- Sensitive operations must be auditable.
- Secrets never belong in the repository.

## Required regression coverage

At minimum, security tests must prove:

- Institution A can access permitted Institution A records.
- Institution A cannot access Institution B records.
- Manipulating a browser-supplied `institution_id` does not bypass RLS.
- Members cannot perform institution-admin actions.
- Institutions cannot perform SE platform-admin actions.
