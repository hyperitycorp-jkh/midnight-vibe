---
description: The harness got it wrong — send the fix back to it
---

Something about midnight-vibe misfired: a gate blocked work it shouldn't have, a message was wrong or
unclear, or the loop ceiling released. Carry that back to the harness instead of working around it.

1. **Gather the evidence.** The exact block message, the `state` and frontmatter of `.claude/prd.md`,
   what the person was trying to do, and the output of `/midnight-vibe:doctor`. Reduce it to the
   smallest case that still misfires — a bad report is one that cannot be reproduced.
2. **Decide which one this is.**
   - The fix is clear and small (a wrong condition, a confusing message, a missing case) → **a pull
     request**, with a test in `hooks/tests/` that fails before the change and passes after. A gate
     change without a test is not a fix.
   - The cause isn't clear, or the fix is a design decision → **an issue** with the reproduction.
3. **Check what access you have**, then take the shorter path:
   ```bash
   gh repo view hyperitycorp-jkh/midnight-vibe --json viewerPermission -q .viewerPermission
   ```
   `ADMIN` or `WRITE` → branch off `main` in a clone and open the PR directly.
   Anything else → `gh repo fork --clone`, push to the fork, PR from there.
4. **Show the person the diff and the PR body before anything is sent**, and wait for a yes. It goes
   out under their GitHub account and it is public. Never include keys, tokens, absolute home paths,
   or code from their project — reduce the repro to the harness files.
5. Mention what was done and leave the link.

Don't do this for a gate that worked as designed and merely got in the way — that's `/midnight-vibe:off`.
Report what is *wrong*, not what is strict.
