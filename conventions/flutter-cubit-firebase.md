---
name: flutter-cubit-firebase
applies: Flutter apps (including anything started from kits/flutter-cubit-firebase)
---

# Flutter — cubit · Firebase

**Never ask about any of this in the interview.** If a plan breaks these, fix the plan before approval.
Same content as the kit's `CODE_RULES.md` — it sits next to the code and here, where the interview reads it.

## Structure

```
lib/
  models/        data models
  repositories/  Firestore CRUD only — no business logic
  services/      external APIs (Auth, Gemini, Storage)
  cubits/        all business logic and state
  pages/         screens
  widgets/       reusable widgets
  configs/       settings, constants, utilities
```

## State

- **cubit only.** No `setState`. Keeping cubit strictly is what makes state bugs stop happening — that's measured, not theoretical.
- State extends `Equatable`; status values are enums.
- A `page` composes widgets and branches on state. When the same shape appears twice, that's when it becomes a widget.
- **Loading is an overlay in a `Stack`.** Don't clear the screen down to a spinner.
- Avoid callbacks wherever possible.

## Data

- **One repository per collection**, CRUD only. Combining collections or changing state belongs in a cubit.
- Parameters and return values are **model objects** — `fromJson`, `toJson`, `copyWith`, `Equatable`.
- Enums instead of hardcoded strings.
- **Use streams.** Take a flow rather than a one-shot read.
- Use aggregation queries where they apply.

## Style

- Log with `Log.d()` / `Log.e()`. Keep try-catch fine-grained.
- `withAlpha()` instead of `withOpacity()`. Null-check instead of `!`.
- **Don't commit code that still has warnings.**
- Flat design.
