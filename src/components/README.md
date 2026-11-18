# Shared UI Components

Reusable presentation components belong here.

Rules:
- Keep route-specific composition in `src/app/`.
- Keep domain/business logic out of generic UI components.
- Components should be reusable across public, institution and SE-admin surfaces where appropriate.
- Domain-specific components may live under `src/features/<domain>/components/` when reuse is limited to one capability.
