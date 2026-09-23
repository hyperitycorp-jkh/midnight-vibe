---
name: finish-means-landed
applies: any task that ends in a commit, a PR, an issue, a branch or a worktree
---

# Finished means landed, not fixed

**Never ask about this in the interview.** It is what "done" means.

## The gap it closes

A fix that lives in an unmerged PR is not a fix anyone has. The reasoning "the code is correct, the
work is done" stops one step short of the point: nobody gets it until it lands, and the issue that
brought it stays open, collecting duplicate reports from people hitting a bug that is already solved.

The same applies to everything the work left lying around. A branch nobody will merge, a worktree
nobody will open, a scratch file, a TODO written mid-task and never read again — each one costs the
next person a decision about whether it still matters.

## What has to be true before you call it done

- **The change is on the branch it belongs on.** Merged, or explicitly handed over for review with
  the reason stated. "It's in a PR" is a status, not a finish.
- **The issue is closed**, and closed by the thing that closed it — link the commit or PR, don't just
  mark it done.
- **The branch and the worktree are gone** if they were only there for this work.
- **Nothing temporary is left in the tree.** Scratch files, commented-out code kept "just in case",
  debug logging, a stale `.off` switch.
- **Anything still open is named in the final report** — what is left, why, and what has to happen.
  An unfinished thing that is stated is a handover; an unfinished thing that is silent is a trap.

## When it genuinely cannot land

Say so in the same breath, with the reason and what unblocks it: review that isn't yours to give,
a release window, a decision only the owner can make. Then leave the branch and the PR in a state
that makes the next step obvious — described, pushed, and linked from the issue.

## Smell list

An open PR whose work is described as finished · an issue with a fix merged weeks ago · branches
named for tasks that already shipped · a worktree nobody can say the purpose of · "I'll clean that
up later" appearing in a final report.
