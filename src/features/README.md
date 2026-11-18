# IMBOP Feature Architecture

Domain capabilities live here. Route files in `src/app/` are the presentation and routing layer; reusable domain logic belongs in feature modules.

Active capability boundary:
- `communications/` — event-driven notifications, templates, delivery and communication audit

Planned capability boundaries, introduced when real domain logic warrants isolation:
- `institutions/` — institution identity, lifecycle and public spaces
- `memberships/` — institution membership and IMBOP Onboards
- `applications/` — institution/member applications and review workflows
- `publication/` — publication authority and lifecycle
- `discovery/` — public institution discovery
- `pricing/` — plans, thresholds and institutional commercial state
- `administration/` — SE and institution administration
- `reporting/` — institutional and platform reporting

Create a feature module when a capability has enough domain logic to justify isolation. Do not create empty abstractions merely for symmetry.
