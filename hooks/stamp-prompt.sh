#!/bin/bash
# UserPromptSubmit. Only while state is `prd`: stamp `seen:` with the hash of the PRD
# the user just saw.
#
# That one line is the only evidence that the user agreed — a user message is the one
# event a model cannot manufacture. The prompt's content is never read; reading it would
# put the gate back at the mercy of text a model can write.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[ -z "$cwd" ] && cwd="."
mv_off "$cwd" && exit 0
prd="$(mv_prd "$cwd")"
[ -f "$prd" ] || exit 0
[ "$(fm "$prd" state)" = "prd" ] || exit 0
h=$(body_hash "$prd"); [ -n "$h" ] || exit 0
tmp=$(mktemp) || exit 0
if grep -q '^seen:' "$prd"; then
  awk -v h="$h" 'NR==1&&$0=="---"{inb=1;print;next} inb&&$0=="---"{inb=0;print;next} inb&&/^seen:/{print "seen: " h;next} {print}' "$prd" > "$tmp"
else
  awk -v h="$h" 'NR==1&&$0=="---"{print;print "seen: " h;next} {print}' "$prd" > "$tmp"
fi
mv "$tmp" "$prd" 2>/dev/null
exit 0
