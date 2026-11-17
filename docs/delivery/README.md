# IMBOP Delivery

## Source of truth

GitHub is the authoritative source for application code and reviewed configuration.

## Delivery path

**GitHub → Build/Test → Vercel → Production**

Supabase remains the authoritative application data/security backend.

## Working rule

Never repair production by silently creating a divergent implementation outside the repository.

Every material deployment must be traceable to repository source.
