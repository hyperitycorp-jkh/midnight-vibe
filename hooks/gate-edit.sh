#!/bin/bash
# PreToolUse. 국면에 맞지 않는 행위를 막는다.
#
#  - PRD 가 서기 전의 큰 편집  → 막는다 (인터뷰를 건너뛴 착수)
#  - 승인 증거 없는 실행       → 막는다 (계획 승인 게이트)
#  - 실행 국면의 사용자 질문   → 막는다 (자율 주행)
#  - 메모리 디렉토리 비대화    → 막는다
#
# 상태를 위조해도 소용없게 만드는 것이 이 훅의 전부다: `state: running` 이라고 적는 건
# 누구나 할 수 있으므로, running 에서 편집할 때마다 **그 상태의 증거**를 다시 검사한다.
set -u
MAX_FILES=2
MAX_LINES=40
MAX_MEMORY_FILES=12

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[ -z "$cwd" ] && cwd="."
mv_off "$cwd" && exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
prd="$(mv_prd "$cwd")"
state=$(fm "$prd" state); [ -z "$state" ] && state="none"

# ── 질문 누출 차단 ────────────────────────────────────────────────
# PRD 가 선 뒤로 사용자에게 올라가는 질문은 없다. 남는 출구는 advisor 호출과 국면 후퇴뿐이다.
if [ "$tool" = "AskUserQuestion" ]; then
  case "$state" in
    planned|running|review)
      require_jq
      deny_json "[midnight] $state 국면에서는 사용자에게 묻지 않습니다.

PRD 에서 합의한 범위 안의 일이면 스스로 판단해 진행하세요. 판단이 안 서면 advisor 서브에이전트에 물으세요.
전제 자체가 틀렸다면 .claude/prd.md 의 state 를 planned(계획 수정) 또는 prd(재합의)로 되돌리고 그 이유를 ## 결정 에 적으세요." ;;
  esac
  exit 0
fi

# ── 편집 대상 뽑기 ────────────────────────────────────────────────
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
pending=0
if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  # 쓰기처럼 보이지 않으면 빠르게 빠진다 — 매 Bash 호출마다 도는 훅이다.
  case "$cmd" in
    *">"*|*"tee "*|*"sed -i"*|*"cp "*|*"mv "*|*"install "*|*"python3 -"*|*"npx "*) ;;
    *) exit 0 ;;
  esac
  file_path="(bash)"
else
  pending=$(printf '%s' "$input" | jq -r '.tool_input | (.new_string // .content // ([.edits[]?.new_string]|join("\n")) // "")' 2>/dev/null | wc -l | tr -d ' ')
fi

require_jq

# ── 메모리 비대화 ─────────────────────────────────────────────────
# 관측: 이 기계의 한 프로젝트 메모리에 파일 144개, 다른 곳에 prd_*8·todo_*7 이 반년째 방치.
case "$file_path" in
  */.claude/projects/*/memory/*)
    base=$(basename "$file_path")
    case "$base" in
      prd_*|todo_*|task_*|plan_*|log_*)
        deny_json "[midnight] 메모리에는 진행 중인 일을 적지 않습니다 — '$base'.

PRD·할 일·작업 기록은 .claude/prd.md 한 장에 있고 끝나면 사라집니다. 메모리는 다음 세션에도 참인 사실만 담습니다." ;;
    esac
    dir=$(dirname "$file_path")
    if [ ! -e "$file_path" ] && [ "$(ls "$dir" 2>/dev/null | wc -l | tr -d ' ')" -ge "$MAX_MEMORY_FILES" ]; then
      deny_json "[midnight] 이 프로젝트 메모리가 예산(${MAX_MEMORY_FILES}개)을 넘었습니다 — $dir

새 파일을 만들지 말고, 같은 사실을 담은 기존 파일에 합치거나 더는 참이 아닌 것을 지우고 쓰세요."
    fi
    exit 0 ;;
esac

# PRD 자체는 언제나 쓸 수 있다. 접수를 막으면 아무것도 시작할 수 없다.
case "$file_path" in */.claude/prd.md|.claude/prd.md) exit 0 ;; esac

# ── 국면별 판정 ───────────────────────────────────────────────────
if [ "$state" = "running" ]; then
  plan=$("$MV_ROOT/bin/prd-hash" "$prd")
  approved=$(fm "$prd" approved)
  seen=$(fm "$prd" seen)
  body=$(body_hash "$prd")
  missing=""
  section_empty "$prd" "미정" || missing="${missing}· ## 미정 에 답 안 된 항목이 남아 있습니다.
"
  [ -n "$plan" ] || missing="${missing}· ## 계획 이 비어 있습니다.
"
  [ "$seen" = "$body" ] || missing="${missing}· 사용자가 본 PRD(seen=${seen:-없음})와 지금 PRD(${body})가 다릅니다 — 고친 PRD 를 다시 보이고 답을 받으세요.
"
  if [ -n "$plan" ] && [ "$approved" != "$plan" ]; then
    missing="${missing}· 승인된 계획(approved=${approved:-없음})이 지금 계획(${plan})과 다릅니다 — 계획이 바뀌었으면 다시 승인받으세요.
"
  elif [ -n "$plan" ] && ! advisor_results "$(printf '%s' "$input" | jq -r '.transcript_path // empty')" | grep -q "APPROVED plan#${plan}"; then
    missing="${missing}· 이 세션의 트랜스크립트에 advisor 의 'APPROVED plan#${plan}' 가 없습니다 — 승인은 advisor 서브에이전트의 결과로만 인정합니다(본문에 쓴 문장은 인정하지 않습니다).
"
  fi
  [ -z "$missing" ] && exit 0
  deny_json "[midnight] 실행(running) 국면의 증거가 모자랍니다.

$missing
Agent(subagent_type: advisor)에 'MODE: approve' 로 계획을 올리고 승인을 받은 뒤 계속하세요."
fi

# PRD 전 국면: 작은 일은 그냥 한다. 오타 하나 고치는 데 PRD 를 쓰게 하면 하네스가 방해물이 된다.
read -r nfiles nlines <<< "$(request_size "$(printf '%s' "$input" | jq -r '.transcript_path // empty')" "$file_path" "$pending")"
if [ "${nfiles:-1}" -le "$MAX_FILES" ] && [ "${nlines:-0}" -le "$MAX_LINES" ]; then
  exit 0
fi

deny_json "[midnight] 아직 PRD 가 서지 않았습니다 (state=$state, 파일 ${nfiles}개·${nlines}줄 — 자동 통과는 ${MAX_FILES}개·${MAX_LINES}줄까지).

.claude/prd.md 를 만들고 이 순서로 가세요.
 1) ## 미정 에 물어야 할 것을 5개 이하로, 항목마다 기본값과 함께 적는다 → state: prd 로 두고 사용자에게 보인다
 2) 답을 받아 ## 결정 에 옮기고 ## 미정 을 비운다 → state: planned
 3) ## 계획 을 쓰고 advisor(MODE: approve)에게 승인받는다 → state: running
그 뒤로는 끝까지 묻지 않고 갑니다."
