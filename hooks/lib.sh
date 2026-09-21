#!/bin/bash
# Shared by the midnight-vibe hooks. The phase lives only in the frontmatter of
# `.claude/prd.md` — never inferred from conversation, which vanishes at compaction.

MV_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# A switch that sits in front of the hooks. A broken harness must never stop someone working.
mv_off() {
  [ "${CLAUDE_HARNESS_OFF:-}" = "1" ] && return 0
  [ -e "${1:-.}/.claude/harness.off" ] && return 0
  return 1
}

mv_prd() { printf '%s/.claude/prd.md' "${1:-.}"; }

# Read one frontmatter line. Only the first `---` block counts.
fm() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 0
  awk -v k="$key" '
    NR==1 && $0=="---" {inb=1; next}
    inb && $0=="---" {exit}
    inb && $0 ~ "^"k":" {sub("^"k":[[:space:]]*",""); sub(/[[:space:]]*#.*$/,""); sub(/[[:space:]]*$/,""); print; exit}
  ' "$file"
}

# Is the body of a `## <heading>` section empty (bullets or whitespace alone count as empty).
section_empty() {
  local file="$1" head="$2" body
  [ -f "$file" ] || return 0
  body=$(awk -v h="## $head" '$0==h{f=1;next} /^## /{f=0} f' "$file" | tr -d '[:space:]-')
  [ -z "$body" ]
}

# Collect **only the tool_result bodies of the advisor subagent** from the transcript.
# Assistant text is never read — a model can write an approval token into its own reply,
# but it cannot fabricate a tool_result. Every forgery guarantee rests on this one fact.
advisor_results() {
  local transcript="$1" ids id_lines result_lines
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 0

  # The transcript is JSONL — one object per line — so grep can narrow it to the
  # handful of lines worth parsing. Scan the whole file: a byte window silently
  # drops the approval once a session outgrows it, and the gate then stays shut
  # with no way to reopen but re-running the advisor. Measured: a 10MB session
  # greps in milliseconds, while jq over the same bytes takes seconds.
  id_lines=$(grep -F '"subagent_type"' "$transcript" 2>/dev/null | grep -F 'advisor')
  [ -z "$id_lines" ] && return 0

  ids=$(printf '%s\n' "$id_lines" | jq -R -r '
      fromjson? // empty | select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and (.name=="Agent" or .name=="Task"))
      | select((.input.subagent_type // "") | (. == "advisor" or endswith(":advisor"))) | .id' 2>/dev/null)
  [ -z "$ids" ] && return 0

  # Only lines carrying one of those ids can hold an advisor result.
  result_lines=$(grep -F -f <(printf '%s\n' "$ids") "$transcript" 2>/dev/null \
    | grep -F '"tool_result"')
  [ -z "$result_lines" ] && return 0

  printf '%s\n' "$result_lines" | jq -R -r --argjson ids "$(printf '%s\n' "$ids" | jq -R . | jq -s .)" '
      fromjson? // empty | select(.type=="user") | .message.content[]?
      | select(.type=="tool_result") | select(.tool_use_id as $i | $ids | index($i))
      | (.content | if type=="string" then . else (map(.text? // "") | join("\n")) end)' 2>/dev/null
}

# Never pass silently while the gate isn't actually running.
require_jq() {
  command -v jq >/dev/null 2>&1 && return 0
  printf '[midnight] jq is missing, so the gate cannot run. Refusing rather than passing — please install jq.\n' >&2
  exit 2
}

deny_json() {  # The documented shape for denying a tool call from PreToolUse
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

block_stop() {  # From Stop: "do not end the turn"
  printf '{"decision":"block","reason":%s}\n' "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

# Hash of what the user agreed to — identifies the version the user saw.
# Sections the procedure itself rewrites after the reply are left out: answers move out of
# Open questions into Decisions, then Plan and Tasks get written. Hashing those made every
# PRD fail `seen` the moment the documented flow was followed. Open questions stays covered
# by its own emptiness check, and Plan by the advisor's approval hash.
body_hash() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk 'NR==1 && $0=="---"{inb=1;next} inb && $0=="---"{inb=0;next} inb{next}
       /^## /{skip = ($0 ~ /^## (Open questions|Decisions|Plan|Tasks)[[:space:]]*$/)}
       !skip' "$file" \
    | sed 's/[[:space:]]*$//' | shasum -a 256 2>/dev/null | cut -c1-8
}

# Files touched and lines changed in THIS request. Counting per session would block the
# next typo fix just because the previous request was large — the window starts at the
# last user instruction.
request_size() {
  local transcript="$1" pending_path="$2" pending_lines="$3" lines boundary touched files count
  lines=""
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    if [ "$(wc -c < "$transcript" 2>/dev/null | tr -d ' ')" -gt 400000 ]; then
      lines=$(tail -c 400000 "$transcript" 2>/dev/null | tail -n +2)
    else
      lines=$(cat "$transcript" 2>/dev/null)
    fi
  fi
  # The hook's own block message is not a boundary — if it were, the counter would reset
  # after every block and the next edit would sail through (the gate opening itself).
  boundary=$(printf '%s\n' "$lines" | jq -R -r '
      fromjson? // empty
      | if .type=="user" then
          ((.message.content | if type=="string" then . else (map(select(.type=="text")|.text)|join(" ")) end)
           | if test("\\[midnight") then "-" else "USER" end)
        else "-" end' 2>/dev/null | grep -n 'USER' | tail -1 | cut -d: -f1)
  [ -n "$boundary" ] && lines=$(printf '%s\n' "$lines" | tail -n +"$boundary")
  touched=$(printf '%s\n' "$lines" | jq -R -r '
      fromjson? // empty | select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use")
      | select(.name=="Edit" or .name=="Write" or .name=="MultiEdit" or .name=="NotebookEdit")
      | .input.file_path // empty' 2>/dev/null)
  files=$(printf '%s\n%s\n' "$touched" "$pending_path" | grep -v '^$' | sort -u | wc -l | tr -d ' ')
  count=$(printf '%s\n' "$lines" | jq -R -r '
      fromjson? // empty | select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use")
      | select(.name=="Edit" or .name=="Write" or .name=="MultiEdit" or .name=="NotebookEdit")
      | (.input.new_string // .input.content // ([.input.edits[]?.new_string]|join("\n")) // "")' 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${files:-1}" "$(( ${count:-0} + ${pending_lines:-0} ))"
}

# The Agent tool runs subagents in the background by default. Then its tool_result is only
# "Async agent launched successfully … agentId", and the verdict arrives later as a notification
# — never as a tool_result. A gate that reads tool_results would then stay shut forever, so this
# says exactly that instead of letting it look like the advisor never approved.
advisor_ran_in_background() {
  local transcript="$1"
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 1
  grep -F 'Async agent launched' "$transcript" 2>/dev/null | grep -qF 'tool_result' || return 1
  grep -F '"subagent_type"' "$transcript" 2>/dev/null | grep -qE '"subagent_type": ?"([^"]*:)?advisor"'
}
BACKGROUND_HINT="The advisor was launched in the background, so its verdict arrives as a notification and never as a tool_result — which is the only place the gate looks. Call Agent(subagent_type: midnight-vibe:advisor) again with run_in_background: false."
