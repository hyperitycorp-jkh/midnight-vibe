#!/bin/bash
# Stop. This hook IS the autonomous loop — driven by the state value, not a slash command.
#
# Its limit is known and respected: a Stop hook cannot undo or edit a reply that already
# exists. All it can do is refuse to let the turn end, and even that has a ceiling. At the
# ceiling (LOOP_CAP) it releases itself and says so — it will not burn tokens in silence.
set -u
LOOP_CAP=25
MAX_MEMORY_FILES=12

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[ -z "$cwd" ] && cwd="."
mv_off "$cwd" && exit 0
command -v jq >/dev/null 2>&1 || exit 0   # Stop fails open — never trap someone in a turn that can't end

prd="$(mv_prd "$cwd")"
state=$(fm "$prd" state); [ -z "$state" ] && exit 0

loop=$(fm "$prd" loop); loop=${loop:-0}
bump_loop() {
  local n=$(( loop + 1 )) tmp
  tmp=$(mktemp) || return 0
  if grep -q '^loop:' "$prd"; then
    awk -v n="$n" 'NR==1&&$0=="---"{inb=1;print;next} inb&&$0=="---"{inb=0;print;next} inb&&/^loop:/{print "loop: " n;next} {print}' "$prd" > "$tmp"
  else
    awk -v n="$n" 'NR==1&&$0=="---"{print;print "loop: " n;next} {print}' "$prd" > "$tmp"
  fi
  mv "$tmp" "$prd" 2>/dev/null
}

if [ "$loop" -ge "$LOOP_CAP" ]; then
  printf '{"systemMessage":%s}\n' "$(printf '[midnight] Hit the loop ceiling of %s, releasing the gate (state=%s). The scope may have been mis-measured — read .midnight/prd.md and judge for yourself. If the harness got this wrong rather than the plan, /midnight-vibe:report sends the fix back to it.' "$LOOP_CAP" "$state" | jq -Rs .)"
  exit 0
fi

case "$state" in
  intake|interview|prd|none) exit 0 ;;   # the only places the turn may go back to the user

  planned)
    exit 0 ;;   # 0.8.0: no approval gate — set state: running once the plan is written

  running)
    left=$(awk '/^## Tasks[[:space:]]*$/{f=1;next} /^## /{f=0} f && /^[[:space:]]*-[[:space:]]*\[[[:space:]]\]/' "$prd" 2>/dev/null)
    if [ -n "$left" ]; then
      bump_loop
      block_stop "[midnight] There are tasks left ($(( loop + 1 ))/$LOOP_CAP).

$left

Keep going — build first, test and review once at the end. If only the user can decide something, ask them."
    fi
    bump_loop
    block_stop "[midnight] Every task is done. Test once, then one review — set state to review and send it to Agent(subagent_type: midnight-vibe:advisor, run_in_background: false) with 'MODE: review'." ;;

  review)
    tree=$("$MV_ROOT/bin/tree-hash" "$cwd")
    # 0.8.0: one review per feature — a "fix" verdict is fixed directly, no second round.
    if advisor_results "$(printf '%s' "$input" | jq -r '.transcript_path // empty')" | grep -qE "REVIEWED (ok|fix)"; then
      exit 0
    fi
    bump_loop
    if advisor_ran_in_background "$(printf '%s' "$input" | jq -r '.transcript_path // empty')"; then
      block_stop "[midnight] No review evidence. ${BACKGROUND_HINT}"
    fi
    block_stop "[midnight] No review evidence. Send it to Agent(subagent_type: midnight-vibe:advisor, run_in_background: false) with 'MODE: review' and get 'REVIEWED ok tree#${tree}'.

On rejection (REVIEWED fix:), fix those items and resubmit — the tree hash changes with the code, so an old pass is void on its own." ;;

  done)
    mem="$HOME/.claude/projects/$(printf '%s' "$cwd" | sed 's|/|-|g')/memory"
    n=$(ls "$mem" 2>/dev/null | wc -l | tr -d ' ')
    if [ "${n:-0}" -gt "$MAX_MEMORY_FILES" ]; then
      bump_loop
      block_stop "[midnight] Clean up memory before finishing — $mem holds ${n} files (budget ${MAX_MEMORY_FILES}).

Delete what stopped being true, merge files covering the same subject, and bring MEMORY.md back in line."
    fi
    exit 0 ;;
esac
exit 0
