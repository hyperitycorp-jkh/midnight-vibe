---
description: Start a new app from a kit — /midnight-vibe:new <kit> <path>
argument-hint: "flutter-cubit-firebase|next-firebase  ~/Dev/my-app"
---

Start a new app. Arguments: the kit name and the path to create. If either is missing, ask —
you're still in the interview phase.

1. Show what's in `${CLAUDE_PLUGIN_ROOT}/kits/` and confirm the chosen kit exists.
2. `cp -R "${CLAUDE_PLUGIN_ROOT}/kits/<kit>/" <path>` — if the target already exists, stop rather than overwrite.
3. Run `git init` in the target and follow the kit's `START.md` if it has one. For Flutter, say that
   `flutterfire configure` generates `lib/firebase_options.dart`; for web, that `.env.example` must be
   copied to `.env.local` and filled in.
4. Mention in one line that continuing work there means opening a session in that folder.
5. **Don't build anything yet.** Ask what the app is and stand up `.claude/prd.md` first.

A kit is a starting point, not an answer. If the new app had to change the structure, leave one line on
whether that was a good call — when it repeats, it belongs back in the kit.
