#!/bin/bash
# Stop. 이 훅이 곧 자율 루프다 — 슬래시 명령으로 켜는 게 아니라 state 값으로 돈다.
#
# 한계를 알고 쓴다: Stop 훅은 이미 나온 응답을 되돌리거나 고치지 못한다. 할 수 있는 건
# "끝내지 못하게 하는 것"뿐이고, 연속 차단에도 상한이 있다. 그래서 상한(LOOP_CAP)에
# 닿으면 스스로 풀고 사용자에게 알린다 — 조용히 무한히 태우지 않는다.
set -u
LOOP_CAP=25
MAX_MEMORY_FILES=12

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[ -z "$cwd" ] && cwd="."
mv_off "$cwd" && exit 0
command -v jq >/dev/null 2>&1 || exit 0   # Stop 은 fail-open — 끝내지 못하는 상태로 가두지 않는다

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
  printf '{"systemMessage":%s}\n' "$(printf '[midnight] 루프 상한 %s 회에 닿아 게이트를 풉니다 (state=%s). 범위를 잘못 쟀을 수 있습니다 — .claude/prd.md 를 보고 직접 판단하세요.' "$LOOP_CAP" "$state" | jq -Rs .)"
  exit 0
fi

case "$state" in
  interview|prd|none) exit 0 ;;   # 사용자에게 올라가도 되는 유일한 자리

  planned)
    bump_loop
    block_stop "[midnight] 계획 승인을 아직 안 받았습니다. 여기서 멈추지 말고 Agent(subagent_type: advisor)에 'MODE: approve' 로 ## 계획 을 올리세요. 승인이 나오면 state 를 running 으로 바꾸고 계속합니다. 반려면 계획을 고쳐 다시 올리세요 — 사용자에게 올리지 않습니다." ;;

  running)
    left=$(awk '/^## 할 일[[:space:]]*$/{f=1;next} /^## /{f=0} f && /^[[:space:]]*-[[:space:]]*\[[[:space:]]\]/' "$prd" 2>/dev/null)
    if [ -n "$left" ]; then
      bump_loop
      block_stop "[midnight] 아직 남은 할 일이 있습니다 ($(( loop + 1 ))/$LOOP_CAP).

$left

계속하세요. 막히면 advisor 에 물으세요 — 사용자에게 묻지 않습니다. 전제가 틀렸다면 state 를 planned 로 되돌리고 계획을 고쳐 재승인받으세요."
    fi
    bump_loop
    block_stop "[midnight] 할 일이 전부 끝났습니다. 검수로 가세요 — state 를 review 로 바꾸고 Agent(subagent_type: advisor)에 'MODE: review' 로 올리세요." ;;

  review)
    tree=$("$MV_ROOT/bin/tree-hash" "$cwd")
    if advisor_results "$(printf '%s' "$input" | jq -r '.transcript_path // empty')" | grep -q "REVIEWED ok tree#${tree}"; then
      bump_loop
      block_stop "[midnight] 검수를 통과했습니다(tree#${tree}). 마무리하세요 — 메모리에 남길 사실이 있으면 옮기고, .claude/prd.md 를 지운 뒤 완료 보고를 쓰세요."
    fi
    bump_loop
    block_stop "[midnight] 검수 증거가 없습니다. Agent(subagent_type: advisor)에 'MODE: review' 로 올리고 'REVIEWED ok tree#${tree}' 를 받으세요.

반려(REVIEWED fix:)면 그 항목을 고치고 다시 올리세요 — 코드가 바뀌면 tree 해시도 바뀌므로 옛 통과는 자동으로 무효입니다." ;;

  done)
    mem="$HOME/.claude/projects/$(printf '%s' "$cwd" | sed 's|/|-|g')/memory"
    n=$(ls "$mem" 2>/dev/null | wc -l | tr -d ' ')
    if [ "${n:-0}" -gt "$MAX_MEMORY_FILES" ]; then
      bump_loop
      block_stop "[midnight] 끝내기 전에 메모리를 정리하세요 — $mem 에 ${n}개(예산 ${MAX_MEMORY_FILES}개).

더는 참이 아닌 것을 지우고, 같은 주제는 한 파일로 합치고, MEMORY.md 인덱스를 맞추세요."
    fi
    exit 0 ;;
esac
exit 0
