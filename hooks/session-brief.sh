#!/bin/bash
# SessionStart(startup|resume|compact). Restores the phase into context.
# The compact matcher is the point — the conversation is gone but the state is in a file.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[ -z "$cwd" ] && cwd="."
mv_off "$cwd" && exit 0
prd="$(mv_prd "$cwd")"
out=""
if [ -f "$prd" ]; then
  state=$(fm "$prd" state)
  left=$(awk '/^## Tasks[[:space:]]*$/{f=1;next} /^## /{f=0} f && /^[[:space:]]*-[[:space:]]*\[[[:space:]]\]/' "$prd" 2>/dev/null | wc -l | tr -d ' ')
  out="midnight: work is in flight here via .midnight/prd.md — state=${state}, ${left} task(s) left. Read that file first and continue under that phase's rules."
fi
mem="$HOME/.claude/projects/$(printf '%s' "$cwd" | sed 's|/|-|g')/memory"
if [ -d "$mem" ]; then
  n=$(ls "$mem" 2>/dev/null | wc -l | tr -d ' ')
  stale=$(find "$mem" -name '*.md' -mtime +90 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -gt 12 ]; then
    out="${out}
midnight: ${n} memory files (budget 12), ${stale} untouched for 90+ days. Clean up before this work finishes."
  fi
fi
[ -z "$out" ] && exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$(printf '%s' "$out" | jq -Rs .)"
