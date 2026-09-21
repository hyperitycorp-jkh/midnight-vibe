#!/usr/bin/env python3
"""게이트를 위반·오차단 양방향으로 잰다.  python3 hooks/tests/gates.test.py

차단 신호가 두 가지라 둘 다 본다: PreToolUse 는 stdout JSON 의 permissionDecision:deny,
Stop 은 stdout JSON 의 decision:block. exit code 로 재면 전부 통과로 읽힌다."""
import json, subprocess, os, sys, tempfile, hashlib, shutil

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EDIT, STOP, STAMP = (os.path.join(ROOT, "hooks", n) for n in ("gate-edit.sh", "gate-stop.sh", "stamp-prompt.sh"))
FAIL = []

PRD = """---
schema: 1
state: {state}
seen: {seen}
approved: {approved}
loop: {loop}
---
# 목표

## Open questions
{undecided}

## Decisions
- 정해짐

## Plan
{plan}

## Tasks
{todo}
"""

def h8(s):
    return hashlib.sha256(s.encode()).hexdigest()[:8]

def make_project(tmp, state="interview", plan="1. 하나", approved="", undecided="", todo="- [ ] 남음", seen=None, loop=0):
    os.makedirs(os.path.join(tmp, ".claude"), exist_ok=True)
    body = PRD.format(state=state, seen="", approved=approved, loop=loop, undecided=undecided, plan=plan, todo=todo)
    path = os.path.join(tmp, ".claude", "prd.md")
    open(path, "w").write(body)
    if seen == "auto":  # 본문 해시는 훅과 같은 코드로 계산한다 — 파이썬으로 다시 구현하면 둘이 갈린다
        seen = subprocess.run([os.path.join(ROOT, "bin", "body-hash"), path], capture_output=True, text=True).stdout.strip()
    body = PRD.format(state=state, seen=seen or "", approved=approved, loop=loop, undecided=undecided, plan=plan, todo=todo)
    open(path, "w").write(body)
    return path

def transcript(tmp, advisor_result=None, assistant_text=None, user_msgs=0, name="t.jsonl",
               subagent="advisor", pad=0):
    """pad 는 승인 **뒤에** 채워 넣을 군더더기 바이트. 세션이 길어져 승인이 파일
    앞쪽으로 밀려도 찾아내는지 본다 — 예전에는 마지막 400KB 만 읽어서 승인이
    창 밖으로 사라지면 게이트가 영영 안 열렸다."""
    p = os.path.join(tmp, name)  # 이름을 안 나누면 두 트랜스크립트가 같은 파일을 덮어써 테스트가 거짓 실패한다
    lines = []
    for _ in range(user_msgs):
        lines.append({"type": "user", "message": {"content": "해줘"}})
    if assistant_text:
        lines.append({"type": "assistant", "message": {"content": [{"type": "text", "text": assistant_text}]}})
    if advisor_result is not None:
        lines.append({"type": "assistant", "message": {"content": [
            {"type": "tool_use", "id": "t1", "name": "Agent", "input": {"subagent_type": subagent}}]}})
        lines.append({"type": "user", "message": {"content": [
            {"type": "tool_result", "tool_use_id": "t1", "content": advisor_result}]}})
    if pad:
        filler = {"type": "user", "message": {"content": "x" * 900}}
        lines.extend([filler] * (pad // 900 + 1))
    open(p, "w").write("\n".join(json.dumps(l) for l in lines) + "\n")
    return p

def run(hook, payload, env=None):
    e = dict(os.environ); e.setdefault("HOME", payload.get("_home", os.environ["HOME"]))
    if env: e.update(env)
    payload.pop("_home", None)
    return subprocess.run([hook], input=json.dumps(payload), capture_output=True, text=True, errors="replace", env=e)

def denied(p): return '"permissionDecision":"deny"' in p.stdout.replace(" ", "")
def blocked(p): return '"decision":"block"' in p.stdout.replace(" ", "")

def check(label, got, want):
    ok = got == want
    if not ok: FAIL.append(label)
    print(f"{'통과' if ok else '**실패**':8} {'막음' if got else '통과':4}  {label}")

def edit_payload(tmp, path=None, content="x\n", tool="Write", tr=None):
    return {"tool_name": tool, "cwd": tmp, "transcript_path": tr or "",
            "tool_input": {"file_path": path or os.path.join(tmp, "a.ts"), "content": content}}

# ── PRD 전 ────────────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); make_project(tmp)
check("PRD 없음 + 작은 편집(1파일 3줄) → 통과", denied(run(EDIT, edit_payload(tmp, content="a\nb\nc"))), False)
check("PRD 없음 + 큰 편집(60줄) → 차단", denied(run(EDIT, edit_payload(tmp, content="x\n" * 60))), True)
check("PRD 파일 자체 쓰기는 언제나 통과", denied(run(EDIT, edit_payload(tmp, path=os.path.join(tmp, ".claude/prd.md"), content="x\n" * 60))), False)

# ── 승인 증거 ─────────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); prd = make_project(tmp, state="running", plan="1. 하나", seen="auto")
plan_hash = subprocess.run([os.path.join(ROOT, "bin", "prd-hash"), prd], capture_output=True, text=True).stdout.strip()
make_project(tmp, state="running", plan="1. 하나", approved=plan_hash, seen="auto")
tr_ok = transcript(tmp, advisor_result=f"APPROVED plan#{plan_hash}")
tr_text = transcript(tmp, assistant_text=f"APPROVED plan#{plan_hash}", name="t2.jsonl")
check("running + approved 일치 + advisor tool_result → 통과",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_ok))), False)

# 플러그인으로 설치하면 Claude Code 는 에이전트를 `<플러그인>:advisor` 로 노출한다.
# 정확 일치만 보던 시절에는 실설치 세션에서 게이트가 영원히 안 열렸다.
tr_ns = transcript(tmp, advisor_result=f"APPROVED plan#{plan_hash}",
                   subagent="midnight-vibe:advisor", name="t_ns.jsonl")
check("running + 네임스페이스 붙은 advisor 이름 → 통과",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_ns))), False)

# 이름만 비슷한 다른 에이전트는 승인으로 치지 않는다.
for fake in ("notadvisor", "advisor-helper", "advisor:evil"):
    tr_fake = transcript(tmp, advisor_result=f"APPROVED plan#{plan_hash}",
                         subagent=fake, name=f"t_{fake.replace(':','_')}.jsonl")
    check(f"running + '{fake}' 결과 → 차단(승인 아님)",
          denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_fake))), True)

# 세션이 길어져 승인이 파일 앞쪽으로 밀려도 찾아내야 한다.
tr_far = transcript(tmp, advisor_result=f"APPROVED plan#{plan_hash}",
                    name="t_far.jsonl", pad=600_000)
check("running + 승인이 600KB 군더더기 뒤에 있어도 → 통과",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_far))), False)

# ── Bash 쓰기 판별 ────────────────────────────────────────────────
# 증거 없는 running 에서만 판별이 드러난다. 쓰기면 막히고 읽기면 그냥 지나간다.
tmp_b = tempfile.mkdtemp(); make_project(tmp_b, state="running", plan="1. 하나", seen="auto")

def bash_payload(cmd):
    return {"tool_name": "Bash", "cwd": tmp_b, "transcript_path": "",
            "tool_input": {"command": cmd}}

for cmd in ("ls -la 2>/dev/null",
            "grep -rn foo lib 2>/dev/null",
            "git log --oneline 2>&1 | head -3",
            "flutter test 2>&1 | tail -5"):
    check(f"읽기 전용에 붙은 리다이렉션은 쓰기가 아니다 — {cmd[:28]}",
          denied(run(EDIT, bash_payload(cmd))), False)

for cmd in ("echo hi > out.txt",
            "sed -i '' s/a/b/ lib/x.dart",
            "cp a b",
            # `>&` 는 뒤에 숫자나 `-` 가 와야 fd 복제다. 파일 이름이 오면 bash 는
            # 두 스트림을 그 파일로 보낸다 — 진짜 쓰기다. 리다이렉션을 걷어내는
            # 정규식이 이걸 같이 지워서 한때 통과시켰다.
            "echo hi >&out.txt",
            "echo hi >& out.txt",
            "echo hi >&1x",
            "echo hi &>out.txt"):
    check(f"진짜 쓰기는 막는다 — {cmd[:28]}", denied(run(EDIT, bash_payload(cmd))), True)
check("running + assistant 텍스트에만 APPROVED → 차단(위조 불가)",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_text))), True)
make_project(tmp, state="running", plan="1. 하나", approved="deadbeef", seen="auto")
check("running + approved 가 지금 계획과 다름 → 차단",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_ok))), True)
make_project(tmp, state="running", plan="1. 하나", approved=plan_hash, seen="ffffffff")
check("running + seen 불일치(사용자가 본 PRD 아님) → 차단",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_ok))), True)
# 문서대로 흐르면: 질문이 달린 PRD 를 보여주고 답을 받은 뒤, 답을 Decisions 로 옮기고 Plan 을 쓴다.
# 그 재작성이 seen 을 깨면 절차를 지킨 모든 PRD 가 running 에서 막힌다.
p_seen = make_project(tmp, state="prd", plan="", undecided="- 물을 것 — default: 기본", seen="auto")
seen_q = [l for l in open(p_seen) if l.startswith("seen:")][0].split(":", 1)[1].strip()
make_project(tmp, state="running", plan="1. 하나\n2. 둘", seen=seen_q)
plan2 = subprocess.run([os.path.join(ROOT, "bin", "prd-hash"), p_seen], capture_output=True, text=True).stdout.strip()
make_project(tmp, state="running", plan="1. 하나\n2. 둘", approved=plan2, seen=seen_q)
tr_p2 = transcript(tmp, advisor_result=f"APPROVED plan#{plan2}", name="p2.jsonl")
check("답을 Decisions·Plan 으로 옮긴 뒤에도 seen 유지 → 통과",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_p2))), False)
open(p_seen, "w").write(open(p_seen).read().replace("# 목표", "# 바뀐 목표"))
check("사용자가 본 목표가 바뀌면 → 차단",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_p2))), True)
make_project(tmp, state="running", plan="1. 하나", approved=plan_hash, seen="auto", undecided="- 못 정한 것")
check("running + ## Open questions 남음 → 차단",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=tr_ok))), True)

# ── 질문 누출 ─────────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); make_project(tmp, state="running", approved="x", seen="auto")
check("running 에서 AskUserQuestion → 차단",
      denied(run(EDIT, {"tool_name": "AskUserQuestion", "cwd": tmp, "tool_input": {}})), True)
make_project(tmp, state="interview")
check("interview 에서 AskUserQuestion → 통과",
      denied(run(EDIT, {"tool_name": "AskUserQuestion", "cwd": tmp, "tool_input": {}})), False)

# ── 메모리 ────────────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); make_project(tmp)
mem = os.path.join(tmp, "home", ".claude", "projects", "-p", "memory"); os.makedirs(mem)
check("메모리에 todo_ 파일 생성 → 차단",
      denied(run(EDIT, edit_payload(tmp, path=os.path.join(mem, "todo_x.md")))), True)
check("메모리에 사실 파일 생성 → 통과",
      denied(run(EDIT, edit_payload(tmp, path=os.path.join(mem, "deploy-key.md")))), False)
for i in range(12): open(os.path.join(mem, f"f{i}.md"), "w").write("x")
check("메모리 예산 초과 + 새 파일 → 차단",
      denied(run(EDIT, edit_payload(tmp, path=os.path.join(mem, "new.md")))), True)
check("메모리 예산 초과 + 기존 파일 수정 → 통과",
      denied(run(EDIT, edit_payload(tmp, path=os.path.join(mem, "f1.md")))), False)

# ── 할 일 체크는 몰아 칠할 수 없다 ────────────────────────────────
tmp = tempfile.mkdtemp()
prd = make_project(tmp, state="running", todo="\n".join(f"- [ ] 일 {i}" for i in range(1, 11)))
done_all = open(prd).read().replace("- [ ]", "- [x]")
check("PRD 에 열 개를 한 번에 체크 → 차단(자기 신고로 게이트 열기)",
      denied(run(EDIT, edit_payload(tmp, path=prd, content=done_all))), True)
# 치환 횟수를 안 묶으면 "일 1" 이 "일 10" 도 같이 잡아 세 개가 된다
two = open(prd).read().replace("- [ ] 일 1\n", "- [x] 일 1\n", 1).replace("- [ ] 일 2\n", "- [x] 일 2\n", 1)
check("두 개까지는 통과(일이 끝날 때마다 칠하는 것)",
      denied(run(EDIT, edit_payload(tmp, path=prd, content=two))), False)
check("Edit 로 세 개를 한 번에 체크 → 차단",
      denied(run(EDIT, {"tool_name": "Edit", "cwd": tmp, "transcript_path": "",
                        "tool_input": {"file_path": prd,
                                       "old_string": "- [ ] 일 1\n- [ ] 일 2\n- [ ] 일 3",
                                       "new_string": "- [x] 일 1\n- [x] 일 2\n- [x] 일 3"}})), True)
make_project(tmp, state="running", todo="\n".join(f"- [x] 일 {i}" for i in range(1, 11)))
check("체크를 지우는 것은 언제나 통과",
      denied(run(EDIT, edit_payload(tmp, path=prd,
                                    content=open(prd).read().replace("- [x]", "- [ ]")))), False)

# ── 관행 동결·예산 ────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); prd = make_project(tmp, state="running", plan="1. 하나", seen="auto")
plan_hash = subprocess.run([os.path.join(ROOT, "bin", "prd-hash"), prd], capture_output=True, text=True).stdout.strip()
make_project(tmp, state="running", plan="1. 하나", approved=plan_hash, seen="auto")
tr_ok = transcript(tmp, advisor_result=f"APPROVED plan#{plan_hash}", name="cm.jsonl")
rules = os.path.join(tmp, "CLAUDE.md"); open(rules, "w").write("## Conventions\n- 하나\n")
check("running 에서 CLAUDE.md 수정 → 차단(승인 증거가 있어도 동결이 우선)",
      denied(run(EDIT, edit_payload(tmp, path=rules, content="- 둘\n", tr=tr_ok))), True)
make_project(tmp, state="interview")
check("interview 에서 CLAUDE.md 수정 → 통과", denied(run(EDIT, edit_payload(tmp, path=rules, content="- 둘\n"))), False)
open(rules, "w").write("x\n" * 150)
check("CLAUDE.md 줄 예산 초과 + 더 길게 쓰기 → 차단",
      denied(run(EDIT, edit_payload(tmp, path=rules, content="x\n" * 151))), True)
check("CLAUDE.md 줄 예산 초과 + Edit 로 한 줄 늘리기 → 차단",
      denied(run(EDIT, {"tool_name": "Edit", "cwd": tmp, "transcript_path": "",
                        "tool_input": {"file_path": rules, "old_string": "x", "new_string": "x\ny"}})), True)
check("CLAUDE.md 줄 예산 초과 + 합치거나 지워서 줄이기 → 통과",
      denied(run(EDIT, edit_payload(tmp, path=rules, content="x\n" * 20))), False)

# ── 실제 트랜스크립트 모양: 백그라운드로 부른 advisor ─────────────
# 픽스처는 실제 세션에서 뜬 것이다(구조 그대로, 내용만 교체). 지어낸 모양으로 테스트하다가
# 네임스페이스 이름 버그를 놓친 적이 있다 — 모양은 기록에서 가져온다.
FIX = os.path.join(ROOT, "hooks", "tests", "fixtures", "advisor-background.jsonl")
tmp = tempfile.mkdtemp(); prd = make_project(tmp, state="running", plan="1. 하나", seen="auto")
plan_hash = subprocess.run([os.path.join(ROOT, "bin", "prd-hash"), prd], capture_output=True, text=True).stdout.strip()
make_project(tmp, state="running", plan="1. 하나", approved=plan_hash, seen="auto")
p = run(EDIT, edit_payload(tmp, content="x\n" * 60, tr=FIX))
check("백그라운드로 부른 advisor → 차단(판결이 tool_result 에 없다)", denied(p), True)
check("그 차단 메시지가 run_in_background: false 를 알려준다", "run_in_background: false" in p.stdout, True)
make_project(tmp, state="review")
p = run(STOP, {"cwd": tmp, "transcript_path": FIX})
check("review 에서도 같은 안내", "run_in_background: false" in p.stdout, True)

# ── intake: 다 듣고 한 번에 ───────────────────────────────────────
tmp = tempfile.mkdtemp(); prd = make_project(tmp, state="intake")
check("intake 에서 두 줄짜리 수정도 차단(크기와 무관)",
      denied(run(EDIT, edit_payload(tmp, content="a\nb"))), True)
check("intake 에서 PRD 에 한 줄 적기 → 통과",
      denied(run(EDIT, edit_payload(tmp, path=prd, content=open(prd).read() + "\n1. 제목이 계속 오늘\n"))), False)
check("intake 에서 Bash 쓰기 → 차단",
      denied(run(EDIT, {"tool_name": "Bash", "cwd": tmp, "tool_input": {"command": "echo x > a.ts"}})), True)
check("intake 에서 읽기 명령 → 통과",
      denied(run(EDIT, {"tool_name": "Bash", "cwd": tmp, "tool_input": {"command": "ls -la"}})), False)
check("intake 에서 되묻기 → 통과", denied(run(EDIT, {"tool_name": "AskUserQuestion", "cwd": tmp, "tool_input": {}})), False)
check("intake 에서 멈추기 → 허용(매번 사용자 차례)", blocked(run(STOP, {"cwd": tmp})), False)

# ── Stop ──────────────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); make_project(tmp, state="running", todo="- [ ] 남음")
check("running + 남은 할 일 → 끝내지 못함", blocked(run(STOP, {"cwd": tmp})), True)
loop_now = [l for l in open(os.path.join(tmp, ".claude/prd.md")) if l.startswith("loop:")][0]
check("차단할 때 loop 카운터 증가", loop_now.strip() == "loop: 1", True)
make_project(tmp, state="running", todo="- [x] 끝")
check("running + 할 일 전부 완료 → 검수로 가라(역시 끝내지 못함)", blocked(run(STOP, {"cwd": tmp})), True)
make_project(tmp, state="running", todo="- [ ] 남음", loop=25)
check("loop 상한 도달 → 게이트 해제", blocked(run(STOP, {"cwd": tmp})), False)
make_project(tmp, state="interview")
check("interview 에서 멈추기 → 허용(사용자에게 올라가는 자리)", blocked(run(STOP, {"cwd": tmp})), False)
make_project(tmp, state="prd")
check("prd 에서 멈추기 → 허용", blocked(run(STOP, {"cwd": tmp})), False)
make_project(tmp, state="planned")
check("planned 에서 멈추기 → 차단(승인은 advisor 가 한다)", blocked(run(STOP, {"cwd": tmp})), True)

# 검수: tree 해시가 맞아야만 통과
tmp = tempfile.mkdtemp(); make_project(tmp, state="review")
tree = subprocess.run([os.path.join(ROOT, "bin", "tree-hash"), tmp], capture_output=True, text=True).stdout.strip()
check("review + 검수 증거 없음 → 차단", blocked(run(STOP, {"cwd": tmp, "transcript_path": transcript(tmp, advisor_result="아직")})), True)
make_project(tmp, state="review")
check("review + 다른 tree 해시의 통과 → 차단",
      blocked(run(STOP, {"cwd": tmp, "transcript_path": transcript(tmp, advisor_result="REVIEWED ok tree#00000000")})), True)

# ── 킬 스위치 ─────────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); make_project(tmp, state="running", todo="- [ ] 남음")
check("CLAUDE_HARNESS_OFF=1 → Stop 전면 통과", blocked(run(STOP, {"cwd": tmp}, env={"CLAUDE_HARNESS_OFF": "1"})), False)
check("CLAUDE_HARNESS_OFF=1 → 편집 전면 통과",
      denied(run(EDIT, edit_payload(tmp, content="x\n" * 60), env={"CLAUDE_HARNESS_OFF": "1"})), False)
open(os.path.join(tmp, ".claude", "harness.off"), "w").write("")
check(".claude/harness.off → 전면 통과", blocked(run(STOP, {"cwd": tmp})), False)

# ── stamp-prompt ──────────────────────────────────────────────────
tmp = tempfile.mkdtemp(); prd = make_project(tmp, state="prd")
run(STAMP, {"cwd": tmp})
seen = [l for l in open(prd) if l.startswith("seen:")][0].split(":", 1)[1].strip()
check("state=prd 에서 사용자 발화 → seen 이 찍힘", len(seen) == 8, True)
prd = make_project(tmp, state="running")
run(STAMP, {"cwd": tmp})
seen2 = [l for l in open(prd) if l.startswith("seen:")][0].split(":", 1)[1].strip()
check("state=running 에서는 seen 을 건드리지 않음", seen2 == "", True)

print()
if FAIL:
    print(f"실패 {len(FAIL)}건: " + ", ".join(FAIL)); sys.exit(1)
print("전부 통과")
