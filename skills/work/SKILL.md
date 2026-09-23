---
name: work
description: The interview procedure and how to write the one-page PRD. Follow this while state is interview or prd.
---

# Before you start

**The PRD is written in English; the conversation happens in the person's language.** The file is a
work artifact that the hooks and the advisor read, and English costs fewer tokens. What you say to
the person — the questions, what you heard, the final report — is in their language. Don't make them
read English out of the file: ask in the conversation, in their words.

Section headings stay exactly as the template spells them (`## Open questions`, `## Plan`, `## Tasks`).
The hooks match on those.


Large edits are blocked until a PRD is agreed. Don't work around the block — follow this order.

## 0. When they say "I'll tell you several things"

Don't start on the first one. Set `state: intake` in `.midnight/prd.md` and **listen**.

- Each item goes under `## Intake` as one numbered line **the moment it's said** — not held in the
  conversation, where the next compaction loses it.
- Reply in one line: that you've got it, and — only if it's genuinely unclear — what it means. No fixes,
  no plans, no "I'll handle that". Nothing but the PRD can change in this phase; the hook denies the rest.
- When they say they're done, **group what belongs together** (two complaints about the same screen are
  one item; a smaller one that a bigger one absorbs goes away), then write the PRD from the grouped list
  and set `state: prd`. From here it is the normal path: show it, get the reply, plan, approval, run.

## 1. Read what's already decided

Read the project's `CLAUDE.md` first, then `${CLAUDE_PLUGIN_ROOT}/conventions/`.
**Never ask what's written in either.** Re-asking someone's long-standing practice is the second
worst thing after starting half-informed.

They are not equal. The project's `CLAUDE.md` is that project's own rules and **wins**; the plugin's
conventions are the harness author's defaults, and each one carries an `applies:` line — ignore the
ones that don't match this project rather than dragging a stranger's design system into it.

If this is a new app, check `${CLAUDE_PLUGIN_ROOT}/kits/` for a starting point (`/midnight-vibe:new`).
If one fits, start there and don't re-decide the structure.

## 2. Write `.midnight/prd.md`

Copy `templates/prd.md`. Put **only what genuinely must be asked** under `## Open questions` —
five or fewer, each with a default. A question without a default isn't a question, it's a hand-off.

Ask about: hard-to-reverse choices, business and data decisions, tastes no convention covers.
Don't ask about: anything the code answers, anything a convention already settles, anything with an obvious default.

## 3. Show it and get a reply

Set `state: prd` and stop. This is one of the two places the turn goes back to the user.
Move the answers into `## Decisions` and empty `## Open questions`. Anything unanswered takes its
default — write that down as the decision.

## How to call the advisor

`Agent(subagent_type: "midnight-vibe:advisor", run_in_background: false)` — both parts matter.
The plugin exposes the agent under its namespaced name; the short `advisor` doesn't exist. And the
Agent tool runs in the background by default, in which case its tool_result is only "launched" and
the verdict arrives later as a notification — the gate reads tool_results only, so it would never open.

## 4. Write the plan and get it approved

Put files, order and verification under `## Plan`. Set `state: planned` and send it to `advisor`
with `MODE: approve`. On rejection, fix and resubmit — this never goes to the user.

## 5. After that, don't ask

`state: running`. Work through `## Tasks` one at a time. When stuck, ask `advisor`.
If a premise turns out to be wrong, set `state` back to `planned`, fix the plan and get it re-approved.
**The second and last place the turn returns to the user is the final report.**

## 6. Finishing

Send it to `advisor` with `MODE: review`. Once it passes, move only facts that will still be true
next session into memory (never the work in flight — the hooks block that), and delete `.midnight/prd.md`.
If a new practice hardened along the way, add one line under `## Conventions` in **this project's
`CLAUDE.md`** — never inside the plugin directory, which is a version-scoped cache that the next
install orphans. If the same line turns up in a second project, it has earned its way into the
harness: open a PR against `conventions/` there.
