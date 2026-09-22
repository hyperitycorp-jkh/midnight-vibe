---
description: Check whether midnight-vibe is actually running (attach this output when opening an issue)
---

Check these in order and report as a table. Fix what you can; for what you can't, say what needs doing.

1. `jq --version`, `git --version`, `shasum -a 256 </dev/null` — without them the gates fail closed.
2. If `.midnight/prd.md` exists: `state`, `seen`, `approved`, `loop`, and how many `## Tasks` remain.
3. Whether `bin/prd-hash`, `bin/tree-hash` and `bin/body-hash` are executable and produce values.
4. Run `python3 hooks/tests/gates.test.py` and report how many cases pass.
5. File count in this project's memory directory, and how many are untouched for 90+ days.
6. Whether the model the `advisor` agent needs is available on this account. Read the `model:` line of
   `${CLAUDE_PLUGIN_ROOT}/agents/advisor.md` and try one throwaway call with
   `Agent(subagent_type: "midnight-vibe:advisor", run_in_background: false)`. If it cannot run, say so
   plainly — **both gates never open without it** — and name the one line to change, and to what.
7. A live check that the hooks are really wired: attempt a write larger than the auto-pass size in a
   scratch directory with no PRD and confirm the tool call is denied.
8. Whether the PRD still lives at `.claude/prd.md` (projects started before 0.4). If so, move it to
   `.midnight/prd.md`. Claude Code protects `.claude/` and asks for approval on **every** write there —
   in accept-edits mode, in bypass mode, whatever allow rule is added — so a PRD inside it turns each
   task tick into a prompt. No permission rule fixes that; only the location does. Same for the old
   `.claude/harness.off` switch → `.midnight/off`.
