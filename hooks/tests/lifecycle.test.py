#!/usr/bin/env python3
"""한 바퀴를 실제로 돌려 본다 — 단위 케이스가 아니라 국면 전환의 연쇄.
  python3 hooks/tests/lifecycle.test.py

여기서 재는 것은 하나다: **사용자에게 턴이 넘어가는 횟수**. Stop 이 허용된 횟수가 그것이다."""
import json, subprocess, os, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EDIT, STOP, STAMP = (os.path.join(ROOT, "hooks", n) for n in ("gate-edit.sh", "gate-stop.sh", "stamp-prompt.sh"))
FAIL = []

def sh(hook, payload):
    return subprocess.run([hook], input=json.dumps(payload), capture_output=True, text=True, errors="replace")

def write_prd(tmp, state, plan="1. a\n2. b", approved="", undecided="", todo="- [ ] 하나\n- [ ] 둘", seen=""):
    os.makedirs(os.path.join(tmp, ".claude"), exist_ok=True)
    open(os.path.join(tmp, ".claude", "prd.md"), "w").write(
        f"---\nschema: 1\nstate: {state}\nseen: {seen}\napproved: {approved}\nloop: 0\n---\n"
        f"# 목표\n\n## Open questions\n{undecided}\n\n## Decisions\n- 정해짐\n\n## Plan\n{plan}\n\n## Tasks\n{todo}\n")
    return os.path.join(tmp, ".claude", "prd.md")

def hash_of(script, target):
    return subprocess.run([os.path.join(ROOT, "bin", script), target], capture_output=True, text=True).stdout.strip()

def advisor_tr(tmp, text, name="tr.jsonl"):
    p = os.path.join(tmp, name)
    open(p, "w").write("\n".join(json.dumps(x) for x in [
        {"type": "assistant", "message": {"content": [
            {"type": "tool_use", "id": "a1", "name": "Agent", "input": {"subagent_type": "advisor"}}]}},
        {"type": "user", "message": {"content": [
            {"type": "tool_result", "tool_use_id": "a1", "content": text}]}}]) + "\n")
    return p

def edit(tmp, lines=60, tr=""):
    return sh(EDIT, {"tool_name": "Write", "cwd": tmp, "transcript_path": tr,
                     "tool_input": {"file_path": os.path.join(tmp, "a.ts"), "content": "x\n" * lines}})

def stop(tmp, tr=""):
    return sh(STOP, {"cwd": tmp, "transcript_path": tr})

def denied(p): return '"permissionDecision":"deny"' in p.stdout.replace(" ", "")
def blocked(p): return '"decision":"block"' in p.stdout.replace(" ", "")
def want(label, got, exp):
    ok = got == exp
    if not ok: FAIL.append(label)
    print(f"{'통과' if ok else '**실패**':8} {label}")

# ── (가) 오타 한 줄 — 하네스가 보이지 않아야 한다 ──────────────────
tmp = tempfile.mkdtemp()
want("(가) PRD 없이 한 줄 수정이 통과한다", denied(edit(tmp, lines=3)), False)
want("(가) 그대로 끝낼 수 있다", blocked(stop(tmp)), False)

# ── (나) 3파일 기능 한 바퀴 — 개입은 몇 번인가 ─────────────────────
tmp = tempfile.mkdtemp()
handoffs = 0
want("(나) PRD 없이 큰 편집은 막힌다", denied(edit(tmp, 60)), True)

write_prd(tmp, "prd", undecided="- 물어볼 것 — 기본값: X")          # 모델이 PRD 를 쓴다
if not blocked(stop(tmp)): handoffs += 1                              # ① 사용자에게 보인다
sh(STAMP, {"cwd": tmp})                                               # 사용자가 답한다 → seen 찍힘
seen = [l for l in open(os.path.join(tmp, ".claude/prd.md")) if l.startswith("seen:")][0].split(":")[1].strip()

write_prd(tmp, "planned", seen=seen)                                  # 미정 비우고 계획 세움
want("(나) planned 에서는 끝낼 수 없다(승인은 advisor 가 한다)", blocked(stop(tmp)), True)

prd = os.path.join(tmp, ".claude/prd.md")
plan = hash_of("prd-hash", prd)
seen = hash_of("body-hash", prd)
write_prd(tmp, "planned", approved=plan, seen=seen)
tr = advisor_tr(tmp, f"APPROVED plan#{plan}")
write_prd(tmp, "running", approved=plan, seen=hash_of("body-hash", prd))
want("(나) 승인 뒤 실행 편집이 통과한다", denied(edit(tmp, 60, tr)), False)
want("(나) 할 일이 남았으면 끝낼 수 없다", blocked(stop(tmp, tr)), True)

write_prd(tmp, "running", approved=plan, seen=hash_of("body-hash", prd), todo="- [x] 하나\n- [x] 둘")
want("(나) 다 했어도 검수 전에는 끝낼 수 없다", blocked(stop(tmp, tr)), True)

write_prd(tmp, "review", approved=plan, seen=hash_of("body-hash", prd), todo="- [x] 하나\n- [x] 둘")
tree = hash_of("tree-hash", tmp)
tr2 = advisor_tr(tmp, f"REVIEWED ok tree#{tree}", name="tr2.jsonl")
want("(나) 검수 증거가 있어도 마무리 지시가 한 번 온다", blocked(stop(tmp, tr2)), True)

write_prd(tmp, "done", approved=plan, todo="- [x] 하나")
if not blocked(stop(tmp, tr2)): handoffs += 1                         # ② 완료 보고
want("(나) 사용자에게 넘어간 횟수가 정확히 2회", handoffs, 2)

# ── (다) 실행 중 전제가 틀렸다 → 재승인이 강제되는가 ───────────────
tmp = tempfile.mkdtemp()
prd = write_prd(tmp, "running", plan="1. a\n2. b")
plan = hash_of("prd-hash", prd)
write_prd(tmp, "running", plan="1. a\n2. b", approved=plan, seen="")
write_prd(tmp, "running", plan="1. a\n2. b", approved=plan, seen=hash_of("body-hash", prd))
tr = advisor_tr(tmp, f"APPROVED plan#{plan}")
want("(다) 승인된 계획으로는 편집이 통과한다", denied(edit(tmp, 60, tr)), False)

# 전제가 틀려 계획을 고쳤다 → 해시가 달라진다
write_prd(tmp, "running", plan="1. a\n2. 전제가 틀려 바꿈", approved=plan, seen="")
write_prd(tmp, "running", plan="1. a\n2. 전제가 틀려 바꿈", approved=plan, seen=hash_of("body-hash", prd))
want("(다) 계획을 고치면 옛 승인이 자동으로 무효가 된다", denied(edit(tmp, 60, tr)), True)

plan2 = hash_of("prd-hash", prd)
write_prd(tmp, "running", plan="1. a\n2. 전제가 틀려 바꿈", approved=plan2, seen="")
write_prd(tmp, "running", plan="1. a\n2. 전제가 틀려 바꿈", approved=plan2, seen=hash_of("body-hash", prd))
tr3 = advisor_tr(tmp, f"APPROVED plan#{plan2}", name="tr3.jsonl")
want("(다) 재승인을 받으면 다시 통과한다", denied(edit(tmp, 60, tr3)), False)
want("(다) 옛 승인 트랜스크립트로는 통과하지 못한다", denied(edit(tmp, 60, tr)), True)

print()
if FAIL:
    print(f"실패 {len(FAIL)}건: " + ", ".join(FAIL)); sys.exit(1)
print("한 바퀴 검증 통과")
