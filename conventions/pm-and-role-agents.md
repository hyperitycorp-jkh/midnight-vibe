---
name: pm-and-role-agents
applies: long product work where one person owns the vision and wants results, not narration
---

# The main session is the PM; the work runs in the background

**Never ask about this in the interview.** It is how the whole job is run.

Learned on one project over two days: the owner was asked to pick episode titles ("ask me the standard,
not how to make it"); "eight heads tall, always" was forgotten twice because it lived in a chat message;
a console click-path was handed over; a 1,300-image batch was queued before anyone saw twelve of them;
a compaction dropped half the running threads.

1. **Talk like a PM.** Short, in their language, decisions first; a status line when a turn runs long;
   relay an agent's conclusion, never its transcript.
2. **They set standards; the PM decides the rest.** Bring only a new criterion, money, a legal/content
   line, or a direction the rules don't cover. Details: decide by the rules plus a critic, report in a line.
3. **Role agents in the background** (writer, critic, planner, architect, designer, QA, BM): a role file,
   a self-contained prompt (rules to read, files it may not touch, what to hand back), a report file.
   Four at once by default (raise `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` to ~8 when the owner wants speed —
   same total work, more per hour), never two on the same files; the PM keeps working meanwhile.
4. **Gates in a fresh context.** A critic who didn't write it judges a draft before it's applied; anything
   that can lose or leak user data gets a reviewer before it ships. Small blockers: fix on the spot.
5. **Show it while it's being made.** Long jobs run with a waiter that wakes the PM every N items; they see
   a checked contact sheet each time. A repeating flaw → stop, A/B 2–3 variants, show, restart.
6. **A standard said twice becomes a default in code** — constants plus a test that fails when it's lost,
   and the project's rules file updated the same turn. Memory is not a mechanism.
7. **One PRD with checkboxes** for the phase: goal, their criteria, phases, where to resume. Read it first
   after a compaction; tick as work lands.
8. **Money is stated before it's spent**; small pre-approved envelopes only (see `batch-cost-estimate`).
9. **Infra is the PM's job** (see `cli-over-clicking`): back up, narrowest change, harmless check. Deploy
   from a clean worktree, API before the site, then smoke-test live.
10. **Corrections become memory the same turn** — what, why, how to apply; supersede the stale note.
11. **Some roles hold a standing duty, not just a task.** A role can own living documents and run on
    triggers — every content batch, before a release, weekly — and report what to fix, while others do the
    fixing. Example: a showrunner who keeps a many-character story one world (calendars, who knows what,
    rumour paths, who reaches out first) so the whole thing stays smooth as it grows.
12. **Parallel work runs isolated.** Each background agent gets its own git worktree and branch; the PM
    merges after the checks. Two sessions in one working tree is how work gets lost — give each its own.
13. **Daily work on `dev`, releases on `main`.** Deploy only from release tags; CI runs a quick job on `dev`
    and the full suite on PRs into `main`, inside the free minutes.
14. **Paid test runs are the PM's own**, one command at a time, the amount said first. Harnesses refuse the
    paid mode unless it is named, and prove the fake mode spends nothing.
15. **When several products share code, engines hold mechanisms and apps hold words.** Tests fail on an app
    import or an app word inside an engine; a second consumer (another app, a world-less app) is a fixture
    from day one; take a baseline first, then move byte-for-byte and change in a separate, listed step.
16. **When the owner reverses a decision, log it** — date, what it was, what it is now, why, who decided —
    so designs don't flip silently and the next agent reads the current truth.
17. **Each role carries its own knowledge.** A short principles section per role — including the neighbours'
    essentials it must speak to (the planner knows the BM's economy rules and the engine/app boundary; the
    architect knows the content lines; the writer knows the heat ladder and the legal line) — plus pointers
    to where the details live. Agents read the details only when the task needs them, or ask the PM:
    context on demand, not everything up front.
