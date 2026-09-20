---
description: midnight-vibe 이 실제로 돌고 있는지 검사한다 (이슈를 열 때 이 출력을 붙인다)
---

아래를 순서대로 확인하고 표로 보고해라. 고칠 수 있는 것은 고치고, 못 고치는 것은 무엇을 해야 하는지 적어라.

1. `jq --version`, `git --version`, `shasum -a 256 </dev/null` — 없으면 게이트가 fail-closed 로 막는다.
2. `.claude/prd.md` 가 있으면 `state`·`seen`·`approved`·`loop` 와 `## 할 일` 의 남은 수.
3. `bin/prd-hash`·`bin/tree-hash`·`bin/body-hash` 가 실행 가능하고 값을 내는지.
4. `python3 hooks/tests/gates.test.py` 를 돌려 몇 건 통과인지.
5. 이 프로젝트 메모리 디렉토리의 파일 수와 90일 이상 손대지 않은 파일 수.
6. `advisor` 에이전트가 쓸 모델이 이 계정에서 실제로 가용한지 — 아니면 게이트 둘이 열리지 않는다.
