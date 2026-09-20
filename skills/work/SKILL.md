---
name: work
description: The interview procedure and how to write the one-page PRD. Follow this while state is interview or prd.
---

# Before you start

Large edits are blocked until a PRD is agreed. Don't work around the block — follow this order.

## 1. Read what's already decided

Read `${CLAUDE_PLUGIN_ROOT}/conventions/` and the project's `CLAUDE.md` first. The working folder has
no `conventions/` — it lives inside the plugin. **Never ask what's written there.** Re-asking someone's
long-standing practice is the second worst thing after starting half-informed.

If this is a new app, check `${CLAUDE_PLUGIN_ROOT}/kits/` for a starting point (`/midnight-vibe:new`).
If one fits, start there and don't re-decide the structure.

## 2. Write `.claude/prd.md`

Copy `templates/prd.md`. Put **only what genuinely must be asked** under `## Open questions` —
five or fewer, each with a default. A question without a default isn't a question, it's a hand-off.

Ask about: hard-to-reverse choices, business and data decisions, tastes no convention covers.
Don't ask about: anything the code answers, anything a convention already settles, anything with an obvious default.

## 3. Show it and get a reply

Set `state: prd` and stop. This is one of the two places the turn goes back to the user.
Move the answers into `## Decisions` and empty `## Open questions`. Anything unanswered takes its
default — write that down as the decision.

## 4. Write the plan and get it approved

Put files, order and verification under `## Plan`. Set `state: planned` and send it to `advisor`
with `MODE: approve`. On rejection, fix and resubmit — this never goes to the user.

## 5. After that, don't ask

`state: running`. Work through `## Tasks` one at a time. When stuck, ask `advisor`.
If a premise turns out to be wrong, set `state` back to `planned`, fix the plan and get it re-approved.
**The second and last place the turn returns to the user is the final report.**

## 6. Finishing

Send it to `advisor` with `MODE: review`. Once it passes, move only facts that will still be true
next session into memory (never the work in flight — the hooks block that), and delete `.claude/prd.md`.
If a new practice hardened along the way, add a line to `conventions/`.
