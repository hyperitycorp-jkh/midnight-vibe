#!/bin/bash
# PreToolUse. Denies what doesn't belong in the current phase.
#
#  - a large edit before a PRD exists  → denied (starting without the interview)
#  - execution without approval evidence → denied (the plan gate)
#  - a question to the user mid-run     → denied (autonomy)
#  - memory growing without bound       → denied
#
# Making a forged state useless is the whole job of this hook: anyone can write
# `state: running`, so every edit in that state re-checks **the evidence for it**.
set -u
MAX_FILES=2
MAX_LINES=40
MAX_MEMORY_FILES=12
MAX_RULES_LINES=150

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[ -z "$cwd" ] && cwd="."
mv_off "$cwd" && exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
prd="$(mv_prd "$cwd")"
state=$(fm "$prd" state); [ -z "$state" ] && state="none"

# ── No questions leak ─────────────────────────────────────────────
# Once the PRD stands, no question reaches the user. The only exits left are the
# advisor and stepping the phase back.
if [ "$tool" = "AskUserQuestion" ]; then
  case "$state" in
    planned|running|review)
      require_jq
      deny_json "[midnight] No questions to the user in the '$state' phase.

If it's inside what the PRD already settled, decide it yourself. If you genuinely can't, ask the
advisor subagent. If the premise itself turned out wrong, set state in .claude/prd.md back to
'planned' (fix the plan) or 'prd' (re-agree) and write why under ## Decisions." ;;
  esac
  exit 0
fi

# ── What is being written ─────────────────────────────────────────
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
pending=0
if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  # Bail out fast when it doesn't look like a write — this runs on every Bash call.
  case "$cmd" in
    *">"*|*"tee "*|*"sed -i"*|*"cp "*|*"mv "*|*"install "*|*"python3 -"*|*"npx "*) ;;
    *) exit 0 ;;
  esac
  file_path="(bash)"
else
  pending=$(printf '%s' "$input" | jq -r '.tool_input | (.new_string // .content // ([.edits[]?.new_string]|join("\n")) // "")' 2>/dev/null | wc -l | tr -d ' ')
fi

require_jq

# ── Memory bloat ──────────────────────────────────────────────────
# Observed on the machine this was built for: 144 files in one project's memory,
# and 8 prd_* plus 7 todo_* files untouched for half a year in another.
case "$file_path" in
  */.claude/projects/*/memory/*)
    base=$(basename "$file_path")
    case "$base" in
      prd_*|todo_*|task_*|plan_*|log_*)
        deny_json "[midnight] Work in flight doesn't belong in memory — '$base'.

The PRD, the tasks and the running notes live in .claude/prd.md and disappear when the work is done.
Memory is for facts that will still be true in the next session." ;;
    esac
    dir=$(dirname "$file_path")
    if [ ! -e "$file_path" ] && [ "$(ls "$dir" 2>/dev/null | wc -l | tr -d ' ')" -ge "$MAX_MEMORY_FILES" ]; then
      deny_json "[midnight] This project's memory is over budget (${MAX_MEMORY_FILES} files) — $dir

Don't add another file. Merge into the one that already holds this fact, or delete what stopped being true."
    fi
    exit 0 ;;
esac

# The PRD itself is always writable. Blocking intake makes it impossible to start.
case "$file_path" in */.claude/prd.md|.claude/prd.md) exit 0 ;; esac

# ── Conventions: frozen while work is in flight, budgeted otherwise ──
# The plan was approved against these rules. Editing the rule to make the work pass is the same
# cheat as editing the plan after approval — and unlike judging compliance, this one is a file
# check, so the hook can actually decide it.
case "$file_path" in
  */CLAUDE.md|CLAUDE.md)
    case "$state" in
      planned|running|review)
        deny_json "[midnight] CLAUDE.md is frozen in the '$state' phase.

The plan was approved against these conventions. If one of them is wrong, set state back to planned
and write why under ## Decisions — don't edit the rule so the work passes." ;;
    esac
    # Over budget, only writes that GROW the file are denied — merging and deleting stay possible.
    # (An empty jq result still counts as one line, so a "wrote nothing" check would never fire.)
    grew=0
    if [ -f "$file_path" ] && [ "$(wc -l < "$file_path" | tr -d ' ')" -ge "$MAX_RULES_LINES" ]; then
      if [ "$tool" = "Write" ]; then
        [ "$(( ${pending:-1} - 1 ))" -gt "$(wc -l < "$file_path" | tr -d ' ')" ] && grew=1
      else
        was=$(printf '%s' "$input" | jq -r '.tool_input | (.old_string // ([.edits[]?.old_string]|join("\n")) // "")' 2>/dev/null | wc -l | tr -d ' ')
        [ "${pending:-0}" -gt "${was:-0}" ] && grew=1
      fi
    fi
    if [ "$grew" = "1" ]; then
      deny_json "[midnight] CLAUDE.md is over budget (${MAX_RULES_LINES} lines).

Don't add another line. Merge it into the rule that already says this, or delete what stopped being true."
    fi ;;
esac

# ── Per-phase decision ────────────────────────────────────────────
if [ "$state" = "running" ]; then
  plan=$("$MV_ROOT/bin/prd-hash" "$prd")
  approved=$(fm "$prd" approved)
  seen=$(fm "$prd" seen)
  body=$(body_hash "$prd")
  missing=""
  section_empty "$prd" "Open questions" || missing="${missing}· ## Open questions still has unanswered items.
"
  [ -n "$plan" ] || missing="${missing}· ## Plan is empty.
"
  [ "$seen" = "$body" ] || missing="${missing}· The PRD the user saw (seen=${seen:-none}) differs from the current one (${body}) — show the revised PRD and get a reply.
"
  if [ -n "$plan" ] && [ "$approved" != "$plan" ]; then
    missing="${missing}· The approved plan (approved=${approved:-none}) differs from the current one (${plan}) — the plan changed, so get it approved again.
"
  elif [ -n "$plan" ] && ! advisor_results "$(printf '%s' "$input" | jq -r '.transcript_path // empty')" | grep -q "APPROVED plan#${plan}"; then
    missing="${missing}· This session's transcript has no 'APPROVED plan#${plan}' from the advisor — approval counts only from the advisor subagent's result, never from a sentence in a reply.
"
  fi
  [ -z "$missing" ] && exit 0
  deny_json "[midnight] Not enough evidence for the 'running' phase.

$missing
Send the plan to Agent(subagent_type: advisor) with 'MODE: approve', then continue."
fi

# Before the PRD: small work just happens. Making someone write a PRD to fix a typo
# turns the harness into an obstacle.
read -r nfiles nlines <<< "$(request_size "$(printf '%s' "$input" | jq -r '.transcript_path // empty')" "$file_path" "$pending")"
if [ "${nfiles:-1}" -le "$MAX_FILES" ] && [ "${nlines:-0}" -le "$MAX_LINES" ]; then
  exit 0
fi

deny_json "[midnight] No PRD yet (state=$state; ${nfiles} file(s), ${nlines} lines — auto-pass is ${MAX_FILES} files and ${MAX_LINES} lines).

Create .claude/prd.md and go in this order.
 1) Put what must be asked under ## Open questions — five or fewer, each with a default → set state: prd and show it to the user
 2) Move the answers into ## Decisions and empty ## Open questions → state: planned
 3) Write ## Plan and get it approved by the advisor (MODE: approve) → state: running
After that it runs to the end without asking."
