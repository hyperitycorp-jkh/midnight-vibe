---
name: next-firebase
applies: Next.js (App Router) web (including anything started from kits/next-firebase)
---

# Next.js — App Router · Firebase

**Never ask about any of this in the interview.**

## Structure

```
src/
  app/         routes only — screen logic doesn't pile up here
  modules/     one folder per feature: its screens, state and calls
  widgets/     UI shared across features
  services/    the outside world (firebase/*, external APIs)
  stores/      global state (zustand)
  lib/         pure utilities, validation, logging
  config/      constants
  types/       shared types
```

## Rules

- **All Firebase config comes from env vars.** Never hardcode keys. `NEXT_PUBLIC_` belongs only on values
  meant for the browser — put it on an Admin credential and the whole account is open.
- Client keys being public is fine. What must actually be in place is App Check, security rules and API key restrictions.
- Custom tokens and admin work happen **server-side only** (route handlers).
- Validate external redirects against a whitelist.
- Initialize with `getApps().length ? getApp() : initializeApp(...)` to survive hot reload.
