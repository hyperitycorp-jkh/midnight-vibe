#!/bin/bash
# UserPromptSubmit. state: prd 일 때만, 사용자가 방금 본 PRD 본문의 hash 를 seen: 에 찍는다.
#
# 이 한 줄이 "사용자가 합의했다"의 유일한 증거다 — 사용자 메시지는 모델이 만들어 낼 수
# 없는 유일한 사건이기 때문이다. 프롬프트 내용은 읽지 않는다(읽으면 그 순간 게이트가
# 모델이 쓴 문장에 걸리게 된다).
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
