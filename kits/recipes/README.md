# Recipes — code you copy, not code you depend on

Integrations that are a pain to wire, kept as **one working file**. A copy, not a package.

## The rule here

- **They create no dependency.** Nothing imports a recipe — you copy it when you need it.
  So when one goes stale, **no app breaks** and there is no upgrade to chase.
- Each recipe states **what date it reflects** and links the official docs at the top.
  Read that date before using it.
- Stale recipes are not deleted. The date is the warning.
- They are not version-pinned or run in CI. That would make them maintenance, which is the thing this repo avoids.

| Recipe | What | As of |
|---|---|---|
| `kakao-login/` | Kakao OAuth callback → Firebase custom token (Next.js route handler) | 2026-09 |
