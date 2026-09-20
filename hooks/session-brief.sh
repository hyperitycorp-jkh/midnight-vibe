#!/bin/bash
# SessionStart(startup|resume|compact). 국면을 컨텍스트에 되살린다.
# compact 매처가 중요하다 — 압축으로 대화가 날아가도 state 는 파일에 있으므로 복구된다.
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
  left=$(awk '/^## 할 일[[:space:]]*$/{f=1;next} /^## /{f=0} f && /^[[:space:]]*-[[:space:]]*\[[[:space:]]\]/' "$prd" 2>/dev/null | wc -l | tr -d ' ')
  out="midnight: 이 프로젝트는 .claude/prd.md 로 진행 중입니다 — state=${state}, 남은 할 일 ${left}개. 그 파일을 먼저 읽고 그 국면 규칙대로 이어가세요."
fi
mem="$HOME/.claude/projects/$(printf '%s' "$cwd" | sed 's|/|-|g')/memory"
if [ -d "$mem" ]; then
  n=$(ls "$mem" 2>/dev/null | wc -l | tr -d ' ')
  stale=$(find "$mem" -name '*.md' -mtime +90 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -gt 12 ]; then
    out="${out}
midnight: 메모리 ${n}개(예산 12), 90일 이상 손 안 댄 것 ${stale}개. 이번 일이 끝나기 전에 정리해야 합니다."
  fi
fi
[ -z "$out" ] && exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$(printf '%s' "$out" | jq -Rs .)"
