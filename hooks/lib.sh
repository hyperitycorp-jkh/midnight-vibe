#!/bin/bash
# midnight-vibe 훅 공용부. 상태는 오직 `.claude/prd.md` 프론트매터에 있다 —
# 대화 맥락에서 국면을 추론하지 않는다(압축·리셋에서 사라지므로).

MV_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# 훅보다 먼저 있는 스위치. 하네스가 망가졌을 때 사용자가 일을 못 하게 되면 안 된다.
mv_off() {
  [ "${CLAUDE_HARNESS_OFF:-}" = "1" ] && return 0
  [ -e "${1:-.}/.claude/harness.off" ] && return 0
  return 1
}

mv_prd() { printf '%s/.claude/prd.md' "${1:-.}"; }

# 프론트매터 한 줄 읽기. 첫 `---` 블록만 본다.
fm() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 0
  awk -v k="$key" '
    NR==1 && $0=="---" {inb=1; next}
    inb && $0=="---" {exit}
    inb && $0 ~ "^"k":" {sub("^"k":[[:space:]]*",""); sub(/[[:space:]]*#.*$/,""); sub(/[[:space:]]*$/,""); print; exit}
  ' "$file"
}

# `## <제목>` 섹션의 알맹이가 비었는가 (목록 표시나 공백만 있으면 빈 것으로 본다).
section_empty() {
  local file="$1" head="$2" body
  [ -f "$file" ] || return 0
  body=$(awk -v h="## $head" '$0==h{f=1;next} /^## /{f=0} f' "$file" | tr -d '[:space:]-')
  [ -z "$body" ]
}

# 트랜스크립트에서 **advisor 서브에이전트의 tool_result 본문만** 모은다.
# assistant 가 쓴 텍스트는 보지 않는다 — 모델은 자기 텍스트에 승인 토큰을 쓸 수 있지만
# tool_result 는 만들 수 없다. 게이트의 위조 방지는 전부 이 한 가지에 걸려 있다.
advisor_results() {
  local transcript="$1" lines ids
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 0
  if [ "$(wc -c < "$transcript" 2>/dev/null | tr -d ' ')" -gt 400000 ]; then
    lines=$(tail -c 400000 "$transcript" 2>/dev/null | tail -n +2)
  else
    lines=$(cat "$transcript" 2>/dev/null)
  fi
  ids=$(printf '%s\n' "$lines" | jq -R -r '
      fromjson? // empty | select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and (.name=="Agent" or .name=="Task"))
      | select((.input.subagent_type // "") == "advisor") | .id' 2>/dev/null)
  [ -z "$ids" ] && return 0
  printf '%s\n' "$lines" | jq -R -r --argjson ids "$(printf '%s\n' "$ids" | jq -R . | jq -s .)" '
      fromjson? // empty | select(.type=="user") | .message.content[]?
      | select(.type=="tool_result") | select(.tool_use_id as $i | $ids | index($i))
      | (.content | if type=="string" then . else (map(.text? // "") | join("\n")) end)' 2>/dev/null
}

# 게이트가 못 도는 채로 조용히 통과시키지 않는다.
require_jq() {
  command -v jq >/dev/null 2>&1 && return 0
  printf '[midnight] jq 가 없어 게이트가 돌지 않습니다. 통과시키지 않습니다 — jq 를 설치하세요.\n' >&2
  exit 2
}

deny_json() {  # PreToolUse 에서 도구 호출을 거부하는 공식 형식
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

block_stop() {  # Stop 에서 "끝내지 마라"
  printf '{"decision":"block","reason":%s}\n' "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

# 프론트매터를 뺀 PRD 본문의 hash. 사용자가 "본 판"을 이 값으로 식별한다.
body_hash() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk 'NR==1 && $0=="---"{inb=1;next} inb && $0=="---"{inb=0;next} !inb' "$file" \
    | sed 's/[[:space:]]*$//' | shasum -a 256 2>/dev/null | cut -c1-8
}

# 이번 요청에서 고친 파일 수와 바뀐 줄 수. 세션 누적으로 세면 앞 요청이 컸다는 이유로
# 다음 오타 수정까지 막힌다 — 범위는 마지막 사용자 지시 이후다.
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
  # 훅 자신의 차단 안내문은 경계로 치지 않는다 — 치면 막힌 뒤 카운터가 0이 되어 그다음
  # 편집이 그냥 통과한다(게이트가 자기 안내문으로 열린다).
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
