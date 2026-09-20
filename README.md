<h1 align="center">midnight-vibe</h1>

<p align="center">
  <b>It can't start without interviewing you. It can't finish without evidence.<br>
  In between, it doesn't ask.</b>
</p>

<p align="center">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-black">
  <img alt="tests" src="https://img.shields.io/badge/tests-39%20passing-brightgreen">
  <img alt="plugin" src="https://img.shields.io/badge/claude%20code-plugin-8b5cf6">
  <a href="README.ko.md"><img alt="Korean" src="https://img.shields.io/badge/lang-한국어-lightgrey"></a>
</p>

---

A workbench for vibe coding — **gates, conventions and kits** in one repo.
Gates are hooks that actually deny the tool call. Here is one, doing its job:

```console
$ claude
> add the whole auth flow

⏺ Write(src/auth/session.ts)
  ⎿  [midnight] No PRD yet (state=none; 1 file, 64 lines — auto-pass is 2 files and 40 lines).

     Create .claude/prd.md and go in this order.
      1) Put what must be asked under ## Open questions — five or fewer, each with a default
      2) Move the answers into ## Decisions and empty ## Open questions → state: planned
      3) Write ## Plan and get it approved by the advisor (MODE: approve) → state: running
     After that it runs to the end without asking.
```

The phase driving that lives in one file, not in the conversation:

```mermaid
flowchart LR
    I(interview) --> P(prd) --> N(planned) --> R(running) --> V(review) --> D(done)
    R -. "premise was wrong" .-> N
    classDef s fill:#1e1b4b,stroke:#8b5cf6,color:#fff,rx:6
    class I,P,N,R,V,D s
```

| Phase | Advances when | Blocked by |
|---|---|---|
| `interview` → `prd` | a PRD is written and shown | edits over 2 files / 40 lines |
| `prd` → `planned` | you replied and `## Open questions` is empty | the hash of the PRD you saw |
| `planned` → `running` | `advisor` returns `APPROVED plan#<hash>` | the plan's own hash |
| `running` → `review` | every `## Tasks` box is checked | Stop refuses while any remain |
| `review` → `done` | `advisor` returns `REVIEWED ok tree#<hash>` | the working-tree hash |

There are exactly **two** places where the turn comes back to you: when the PRD is shown,
and the final report. In between, `AskUserQuestion` is denied and `Stop` is blocked,
so a user turn never happens.

## Why this exists

The same four things happen every time you hand work to an agent.

1. **It starts with too little context.** It writes code instead of asking what it should have asked.
2. **Then it interrupts you mid-flight** with problems it should have solved itself.
3. **Files multiply.** PRD, TASKS, MEMORY, ARCHITECTURE… more things to maintain, all going stale.
4. **Memory only grows.** On the machine this was built for, one project's memory held **144 files**,
   and another had 8 `prd_*` and 7 `todo_*` files untouched for half a year. Stale memory is worse
   than none — the agent reads it and is confidently wrong.

(1) and (2) look contradictory. They aren't — **the order is just inverted.**
Ask everything before starting; once it's agreed, never ask again.
That boundary is a single PRD, and this repo enforces it with hooks.

The popular answer to (3) — a `docs/` folder holding PRD, ARCHITECTURE, RULES, DESIGN, TASKS and MEMORY —
is not used here. It has no official basis (it's a repackaging of Cline's 2025 "Memory Bank"),
it occupies context permanently, and nobody owns keeping it true.
Here there is **one `.claude/prd.md` while work is in flight**, and it deletes itself when done.

## What's different

| | Common approach | midnight-vibe |
|---|---|---|
| Rules | Written in a doc, model expected to follow | Hooks actually deny the tool call |
| State | Held in conversation — gone after compaction | Written to file frontmatter — survives it |
| Approval | Model says "approved" and that's that | Only a token inside a subagent `tool_result` counts (a model can't forge one) |
| Done | Model says "it's done" and that's that | Review evidence must match the working-tree hash |
| Files | A `docs/` set that lives forever | One file in flight, deleted at the end |
| Loop | Turned on with a slash command | Driven by the `state` value — nothing to turn on |
| Limits | Usually unstated | [Written down](#gates-and-their-limits), including what hooks cannot stop |

## Install

```bash
/plugin marketplace add hyperitycorp-jkh/midnight-vibe
/plugin install midnight-vibe
```

Two lines because there are two steps. The first tells *your own* Claude Code that this git URL
carries a plugin catalog; the second turns one of them on. Nothing is submitted anywhere and this
repo isn't listed in any central registry — `marketplace add` only writes to your machine, and the
only public thing is the GitHub repo itself.

A plugin is a bundle of hooks, agents, skills and slash commands. Installing it wires them into
every session, so there's nothing to symlink by hand and nothing to run per project.

Needs `jq` and `git`. Without them the gates refuse rather than pass silently.
Run `/midnight-vibe:doctor` to confirm it's actually wired in.

## How to use it

### 1. Start a new app

```
/midnight-vibe:new flutter-cubit-firebase ~/Dev/my-app
```

The kit is copied to that path. **You don't build apps inside this repo** — the repo is installed
as a plugin, and each app lives in its own folder outside it. Then open a session there and just say it:
"let's build a marketplace app."

Don't re-decide the structure. The kit's `CODE_RULES.md` and `conventions/` already hold the answers,
and **what's written there is never asked again.**

### 2. Build one feature

Say what you want in one line. Here's what happens next:

| What you see | What you do |
|---|---|
| `.claude/prd.md` opens with ≤5 questions under `## Open questions`, each with a default | Answer. Or just say "use the defaults" |
| A plan is written and `advisor` approves it | **Nothing.** If rejected, it fixes and resubmits on its own |
| It runs to the end — it won't ask, even when stuck | Wait. Interrupt any time by just talking |
| `advisor` reviews → final report | Read it. `.claude/prd.md` deletes itself |

If you get more than 5 questions, or questions without defaults, that's a bug. Please open an issue.

### 3. Small edits stay small

Making someone write a PRD to fix a typo turns the harness into an obstacle.
**Two files and 40 lines or fewer and the gates are invisible** — it just gets fixed and it just ends.
The thresholds are `MAX_FILES` and `MAX_LINES` in `hooks/gate-edit.sh`.

### 4. When it blocks you

The block message says **what evidence is missing** — "seen doesn't match" means show the revised PRD
again; "no APPROVED" means `advisor` was never called. Read that one line instead of working around it.

If it's genuinely in your way, turn it off (below).

## Repository layout

```
midnight-vibe/
├─ hooks/              the gates — the only things that actually enforce
│  ├─ gate-edit.sh       PreToolUse: big edits before a PRD, unapproved execution, questions mid-run, memory bloat
│  ├─ gate-stop.sh       Stop: can't finish with tasks left or no review evidence (this IS the loop)
│  ├─ stamp-prompt.sh    UserPromptSubmit: stamps the hash of the PRD you actually saw
│  ├─ session-brief.sh   SessionStart: restores the phase after compaction or resume
│  └─ tests/             26 gate cases + 13 full-lifecycle cases
├─ bin/                prd-hash · tree-hash · body-hash — what approval and review are bound to
├─ agents/advisor.md   the senior reviewer holding both gates (approve · review)
├─ skills/work/        the interview procedure and how to write the PRD
├─ output-styles/      ask while the phase allows it, never after
├─ commands/           /midnight-vibe:new · :doctor · :off
├─ conventions/        what must never be asked again — where the harness grows
├─ kits/               starting points for new apps, plus copy-paste recipes
└─ templates/prd.md    the only file that exists while work is in flight
```

## Why it can't be forged

Anyone can write `state: running`. So the state isn't trusted — **the evidence for that state**
is re-checked on every action.

- Approval and review only count when the token appears **inside an `advisor` subagent's `tool_result`**.
  A model can write `APPROVED` in its own reply; it cannot fabricate a `tool_result`.
- Approval is bound to the hash of the `## Plan` section. Edit the plan after approval and it's void.
- Review is bound to the working-tree hash. Touch the code after passing and it's void.
- `seen:` (the hash of the PRD you saw) is stamped only by the `UserPromptSubmit` hook —
  a user message is the one event a model cannot manufacture.

## Gates and their limits

| Gate | What the hook stops | What it **can't** |
|---|---|---|
| PRD agreed | Big edits before a PRD (default: >2 files / >40 lines) | Question quality; Bash heredoc workarounds (pattern heuristics) |
| Plan approved | Editing in the run phase without approval evidence | The advisor's judgment; a thin plan written to be easy to approve |
| Review passed | Finishing with tasks left, or with no evidence | Summarizing the review honestly |
| No questions leak | `AskUserQuestion` during the run phase | Question marks in prose — harmless, since the turn can't end |
| Memory | Creating `prd_`/`todo_`-style files, new files over budget | What's already piled up — it only forces cleanup at `done` |

**A Stop hook cannot undo or edit a reply that has already been produced.** All it can do is refuse to
let the turn end, and even that has a ceiling. midnight-vibe releases its own gate at the ceiling
(default 25) and says so — it will not silently burn tokens forever.
Not hiding this limit is the posture of this repo.

## Kits

Copy one, start, refine while you use it, and let the refinements come back to the kit.

| Kit | What |
|---|---|
| `kits/flutter-cubit-firebase` | Flutter + cubit + Firebase. One repository per collection, CRUD only; all logic in cubits |
| `kits/next-firebase` | Next.js (App Router) + Firebase. Config entirely from env; App Check and Admin SDK included |
| `kits/recipes/` | The parts that are a pain to wire — Kakao login, fastlane release and store screenshots — as **copy-paste files** |

Kits carry **no real Firebase config**. Flutter ships only `firebase_options.dart.template` with the
real file gitignored — a new app runs `flutterfire configure` for its own. The web kit is all env vars.

Recipes have one rule: **nothing ever imports them.** They're a file you copy when you need it,
so when Kakao changes its API and the recipe goes stale, **no app breaks and there's no version to chase.**
Each one carries a date and a link to the official docs at the top — the date is the warning.
Stale recipes are not deleted.

## What grows

`conventions/` holds long-standing practices, one file each. The interview reads these first,
and **what's written there is never asked again.** When a new practice hardens, add a line.
That's where the harness grows.

## What this deliberately isn't

No `docs/` six-file set (PRD/ARCHITECTURE/RULES/DESIGN/TASKS/MEMORY), no `plans/` directory,
no global rules file, no ralph-loop dependency. One file while running, deleted at the end.
The autonomous loop is the Stop hook itself, so there's nothing to switch on —
it's triggered by a `state` value, not a slash command.

## Verify

```bash
python3 hooks/tests/gates.test.py      # 26 gate cases — both violations and false blocks
python3 hooks/tests/lifecycle.test.py  # 13 cases across one full interview→done cycle
```

The lifecycle test measures one thing: **the turn comes back to you exactly twice.**

Not done yet: **one live session** with the plugin actually installed. The tests above invoke the hooks
directly, so the path where Claude Code registers and calls them is verified by `/midnight-vibe:doctor`.

## Updating

```bash
claude plugin marketplace add hyperitycorp-jkh/midnight-vibe   # once
claude plugin install midnight-vibe@midnight-vibe
```

**Hooks registered when a session started do not swap on reinstall.** A new version installs fine and
`claude plugin list` shows it, but the running session keeps calling the old hook scripts until you
start a fresh session. If you just updated and the behaviour looks unchanged, that's why.

## Turning it off

```bash
export CLAUDE_HARNESS_OFF=1   # this once
touch .claude/harness.off     # for this project
```

A switch that sits in front of the hooks. If the harness is in your way, turning it off is the right call.

## License

MIT.
