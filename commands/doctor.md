---
description: Check whether midnight-vibe is actually running (attach this output when opening an issue)
---

Check these in order and report as a table. Fix what you can; for what you can't, say what needs doing.

1. `jq --version`, `git --version`, `shasum -a 256 </dev/null` — without them the gates fail closed.
2. If `.claude/prd.md` exists: `state`, `seen`, `approved`, `loop`, and how many `## Tasks` remain.
3. Whether `bin/prd-hash`, `bin/tree-hash` and `bin/body-hash` are executable and produce values.
4. Run `python3 hooks/tests/gates.test.py` and report how many cases pass.
5. File count in this project's memory directory, and how many are untouched for 90+ days.
6. Whether the model the `advisor` agent needs is actually available on this account — without it, two gates never open.
7. A live check that the hooks are really wired: attempt a write larger than the auto-pass size in a
   scratch directory with no PRD and confirm the tool call is denied.
