<h1 align="center">midnight-vibe</h1>

<p align="center">
  <b>인터뷰 없이 착수하지 못하고, 증거 없이 끝나지 못한다.<br>
  그 사이에는 묻지 않는다.</b>
</p>

<p align="center">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-black">
  <img alt="tests" src="https://img.shields.io/badge/tests-46%20passing-brightgreen">
  <img alt="plugin" src="https://img.shields.io/badge/claude%20code-plugin-8b5cf6">
  <a href="README.md"><img alt="English" src="https://img.shields.io/badge/lang-English-lightgrey"></a>
</p>

<p align="center"><img src="assets/hero.svg" alt="" width="820"></p>

---

## 명령 하나 넣으면 앱이 나온다

```
/midnight-vibe:new next-firebase ~/Dev/my-app
```

그 폴더엔 이미 Firebase 가 환경변수로 배선돼 있고(App Check·Admin SDK 포함), 다크모드까지 되는
디자인 토큰이 깔려 있고, TestFlight·스토어 문구·스크린샷 fastlane 레인이 들어 있다.
그다음 거기서 세션을 열고 만들 걸 말하면 된다.

- **이걸 알 필요가 없다.** 부를 스킬도, 외울 슬래시 명령도, 잘 써야 할 프롬프트도 없다.
  그냥 말하면 게이트가 순서를 잡는다.
- **디자인이 나중 일이 아니다.** 웹 킷이 토큰 세트를 들고 온다 — 흰 배경·검정 ink·1px 라인·
  파스텔 악센트 한둘. 관행이 모든 화면을 거기 붙들어 둔다. 다크모드는 같은 토큰을 뒤집은 것이라
  컴포넌트가 따로 분기하지 않는다.
- **출시까지 들어 있다.** "빌드는 된다" 다음 — TestFlight, 스토어 문구, 그리고 **살아 있는 걸
  지우지 않는** 스크린샷 레인.

게이트는 도구 호출을 실제로 거부하는 훅이다. 일하는 모습은 이렇다.

```console
$ claude
> 인증 흐름 통째로 붙여줘

⏺ Write(src/auth/session.ts)
  ⎿  [midnight] No PRD yet (state=none; 1 file, 64 lines — auto-pass is 2 files and 40 lines).

     Create .claude/prd.md and go in this order.
      1) Put what must be asked under ## Open questions — five or fewer, each with a default
      2) Move the answers into ## Decisions and empty ## Open questions → state: planned
      3) Write ## Plan and get it approved by the advisor (MODE: approve) → state: running
     After that it runs to the end without asking.
```

그 국면은 대화가 아니라 파일 한 장에 적혀 있다.

```mermaid
flowchart LR
    I(interview) --> P(prd) --> N(planned) --> R(running) --> V(review) --> D(done)
    R -. "전제가 틀렸다" .-> N
    classDef s fill:#1e1b4b,stroke:#8b5cf6,color:#fff,rx:6
    class I,P,N,R,V,D s
```

| 국면 | 넘어가는 조건 | 무엇이 막나 |
|---|---|---|
| `interview` → `prd` | PRD 를 써서 보인다 | 2파일·40줄 넘는 편집 |
| `prd` → `planned` | 답장을 받고 `## Open questions` 가 빈다 | 사용자가 본 PRD 의 해시 |
| `planned` → `running` | `advisor` 가 `APPROVED plan#<해시>` | 계획 자신의 해시 |
| `running` → `review` | `## Tasks` 가 전부 체크된다 | 남아 있으면 Stop 이 거부 |
| `review` → `done` | `advisor` 가 `REVIEWED ok tree#<해시>` | 작업트리 해시 |

사용자에게 턴이 넘어가는 자리는 **둘뿐**이다: PRD 를 보이는 자리와 완료 보고.
그 사이에는 `AskUserQuestion` 이 거부되고 Stop 도 막히므로 사용자 턴이 아예 생기지 않는다.

## 왜 만들었나

에이전트에게 일을 시킬 때마다 같은 네 가지가 반복된다.

1. **맥락이 모자란 채로 막 시작한다.** 물어봤어야 할 걸 안 묻고 코드부터 짠다.
2. **정작 일이 굴러갈 때는 자꾸 묻는다.** 스스로 풀었어야 할 문제를 들고 와 사람을 붙잡는다.
3. **파일이 계속 늘어난다.** PRD·TASKS·MEMORY·ARCHITECTURE… 관리 대상만 불어나고 곧 낡는다.
4. **메모리가 쌓이기만 한다.** 이 기계의 한 프로젝트 메모리에는 파일이 **144개**, 다른 곳엔
   반년째 방치된 `prd_*` 8개와 `todo_*` 7개가 있었다. 낡은 메모리는 없느니만 못하다 —
   에이전트가 그걸 읽고 자신 있게 틀린다.

1번과 2번은 모순처럼 보이지만 아니다. **순서가 뒤집혔을 뿐이다.**
질문은 착수 전에 몰아서 하고, 합의가 끝나면 한 번도 묻지 않으면 된다.
그 경계가 PRD 한 장이고, 이 저장소는 그 경계를 훅으로 강제한다.

3번에 대한 유행하는 답 — `docs/` 밑에 PRD·ARCHITECTURE·RULES·DESIGN·TASKS·MEMORY 6종을 두는 방식 —
은 따르지 않았다. 공식 근거가 없는 관행이고(2025년 Cline "Memory Bank" 의 재포장이다),
컨텍스트를 상시 점유하면서 낡는 것을 아무도 책임지지 않는다.
여기서는 **진행 중에만 `.claude/prd.md` 한 장**이 있고 끝나면 스스로 지워진다.

## 뭐가 다른가

| | 흔한 방식 | midnight-vibe |
|---|---|---|
| 규칙 | 문서에 적고 모델이 지키길 기대 | 훅이 실제로 도구 호출을 막는다 |
| 상태 | 대화 맥락에 들고 있다 — 압축되면 사라짐 | 파일 프론트매터에 적는다 — 압축돼도 남는다 |
| 승인 | 모델이 "승인받았다"고 말하면 끝 | 서브에이전트 `tool_result` 안의 토큰만 인정 (모델이 위조 불가) |
| 완료 | 모델이 "다 됐다"고 하면 끝 | 검수 증거가 작업트리 해시와 맞아야 끝 |
| 파일 | `docs/` 6종이 영구히 남는다 | 진행 중 한 장, 끝나면 삭제 |
| 루프 | 슬래시 명령으로 켠다 | `state` 값으로 돈다 — 켤 일이 없다 |
| 한계 | 대개 안 적혀 있다 | [게이트와 그 한계](#게이트와-그-한계) 에 못 막는 것까지 적었다 |

## 설치

```bash
/plugin marketplace add hyperitycorp-jkh/midnight-vibe
/plugin install midnight-vibe
```

두 줄인 것은 단계가 둘이기 때문이다. 첫 줄은 **내 기계의** Claude Code 에게 "이 깃 주소에 플러그인
목록이 있다"고 알려 주는 것이고, 둘째 줄이 그중 하나를 켠다. 어디에 제출하는 것도, 중앙 목록에
등록되는 것도 아니다 — `marketplace add` 는 내 기계에만 적히고, 공개되는 건 GitHub 저장소 자체뿐이다.

플러그인은 훅·에이전트·스킬·슬래시 명령을 한 묶음으로 만든 것이다. 설치하면 모든 세션에 자동으로
물린다 — 심링크를 손으로 걸 일도, 프로젝트마다 뭘 돌릴 일도 없다.

`jq` 와 `git` 이 필요하다. 없으면 게이트가 통과시키지 않고 막는다(조용한 통과 금지).
`/midnight-vibe:doctor` 로 실제로 물렸는지 확인한다.

## 쓰는 법

### 1. 새 앱을 시작한다

```
/midnight-vibe:new flutter-cubit-firebase ~/Dev/my-app
```

킷이 그 경로로 복사된다. **이 저장소 안에 앱을 만들지 않는다** — 저장소는 플러그인으로 설치돼
있고, 앱은 바깥의 자기 폴더에서 산다. 그다음 그 폴더에서 세션을 열고 그냥 말한다 —
"중고 거래 앱 만들자".
구조를 다시 정하지 않는다. 킷의 `CODE_RULES.md` 와 `conventions/` 가 이미 정답을 갖고 있고,
**거기 적힌 것은 다시 묻지 않는다.**

### 2. 기능 하나를 만든다

하고 싶은 걸 한 줄로 말하면 된다. 그다음 일어나는 일:

| 무엇이 보이나 | 무엇을 하면 되나 |
|---|---|
| `.claude/prd.md` 한 장이 열리고 `## Open questions` 에 질문 5개 이하, 항목마다 기본값 | 답한다. 답하기 싫으면 "기본값대로" 한마디면 된다 |
| 계획이 서고 `advisor` 가 승인한다 | **아무것도 안 해도 된다.** 반려돼도 알아서 고쳐 다시 올린다 |
| 끝까지 돈다 — 막혀도 묻지 않는다 | 기다린다. 중간에 끼어들고 싶으면 그냥 말하면 된다 |
| `advisor` 검수 → 완료 보고 | 받는다. `.claude/prd.md` 는 스스로 지워진다 |

질문이 5개를 넘거나 기본값 없이 오면 그건 버그다. 이슈를 열어 달라.

### 3. 작은 수정은 그냥 한다

오타 하나 고치는 데 PRD 를 쓰게 하면 하네스가 방해물이다.
**2파일·40줄 이하는 게이트가 보이지도 않는다** — 그냥 고쳐지고 그냥 끝난다.
문턱은 `hooks/gate-edit.sh` 의 `MAX_FILES`·`MAX_LINES` 에 있다.

### 4. 하네스가 막았을 때

차단 메시지는 **무엇이 모자란지**를 적어 준다 — "seen 이 다르다"면 고친 PRD 를 다시 보이라는 뜻이고,
"APPROVED 가 없다"면 `advisor` 를 안 불렀다는 뜻이다. 우회하려 들지 말고 그 한 줄을 읽으면 된다.

진짜로 방해가 되면 **끈다**. 아래 "끄기".

## 저장소 구조

```
midnight-vibe/
├─ hooks/              게이트 — 이것만이 실제로 강제한다
│  ├─ gate-edit.sh       PreToolUse: 인터뷰 전 큰 편집·증거 없는 실행·실행 중 질문·메모리 비대화
│  ├─ gate-stop.sh       Stop: 할 일이 남거나 검수 증거가 없으면 끝내지 못한다 (= 자율 루프)
│  ├─ stamp-prompt.sh    UserPromptSubmit: 사용자가 본 PRD 의 해시를 찍는다
│  ├─ session-brief.sh   SessionStart: 압축·재개 뒤에 국면을 되살린다
│  └─ tests/             게이트 26건 + 한 바퀴 13건
├─ bin/                prd-hash · tree-hash · body-hash — 승인과 검수가 걸리는 해시
├─ agents/advisor.md   게이트 둘을 지키는 상급 검토자 (승인 · 검수)
├─ skills/work/        인터뷰 절차와 PRD 쓰는 법
├─ output-styles/      국면에 따라 묻고, 국면이 지나면 묻지 않는 응답 규칙
├─ commands/           /midnight-vibe:doctor · :off
├─ conventions/        다시 묻지 않을 관행 — 하네스가 자라는 자리
├─ kits/               앱을 뚝딱 시작하는 출발점 + 복붙용 레시피
└─ templates/prd.md    진행 중 단 하나의 파일
```

## 위조가 안 되는 이유

`state: running` 이라고 적는 건 누구나 할 수 있다. 그래서 상태를 믿지 않고,
**그 상태의 증거**를 행동할 때마다 다시 검사한다.

- 승인·검수는 **advisor 서브에이전트의 `tool_result` 안**에 있는 토큰만 인정한다.
  모델은 자기 답변에 `APPROVED` 라고 쓸 수 있어도 `tool_result` 를 만들어 낼 수는 없다.
- 승인은 `## Plan` 섹션의 해시에 걸린다. 승인 뒤 계획을 고치면 자동으로 무효가 된다.
- 검수는 작업트리 해시에 걸린다. 통과 뒤 코드를 고치면 역시 무효가 된다.
- `seen:`(사용자가 본 PRD 의 해시)은 `UserPromptSubmit` 훅만 찍는다 —
  사용자 메시지는 모델이 만들어 낼 수 없는 유일한 사건이다.

## 게이트와 그 한계

| 게이트 | 훅이 막는 것 | 훅이 **못** 막는 것 |
|---|---|---|
| PRD 합의 | PRD 전의 큰 편집(기본 2파일·40줄 초과) | 질문의 질, Bash 히어독 우회(패턴 휴리스틱) |
| 계획 승인 | 승인 증거 없는 실행 국면 편집 | advisor 의 판단 품질, 승인받기 쉬운 얄팍한 계획 |
| 검수 통과 | 할 일이 남은 채 끝내기, 증거 없는 종료 | 검수 결과를 정직하게 요약하는 것 |
| 질문 누출 | 실행 국면의 `AskUserQuestion` | 답변 본문의 물음표 — 턴이 안 끝나므로 무해 |
| 메모리 | `prd_`·`todo_` 류 생성, 예산 초과 신규 파일 | 이미 쌓인 것 — `done` 에서 정리를 강제할 뿐 |
| 관행 | 일이 도는 중의 `CLAUDE.md` 수정, 예산 넘겨 늘리기 | 계획·diff 가 실제로 그걸 지키는지 — 그건 advisor 의 독해다 |

**Stop 훅은 이미 나온 응답을 되돌리거나 고치지 못한다.** 할 수 있는 건 "끝내지 못하게" 하는 것뿐이고,
그것도 상한이 있다. midnight-vibe 는 상한(기본 25회)에 닿으면 스스로 게이트를 풀고 알린다 —
조용히 무한히 토큰을 태우지 않는다. 이 한계를 숨기지 않는 것이 이 저장소의 태도다.

## 킷 — 앱을 뚝딱 시작하는 자리

복사해서 시작하고, 쓰면서 다듬고, 다듬은 것이 다시 킷으로 돌아온다.

| 킷 | 무엇 |
|---|---|
| `kits/flutter-cubit-firebase` | Flutter + cubit + Firebase. repository 는 컬렉션 하나의 CRUD, 로직은 전부 cubit |
| `kits/next-firebase` | Next.js(App Router) + Firebase. 설정은 전부 환경변수, App Check·Admin SDK 포함 |
| `kits/recipes/` | 붙이기 귀찮은 것 — 카카오 로그인, fastlane 릴리즈·스토어 스크린샷 — 을 **복붙용**으로 |

킷에는 **실제 Firebase 설정을 넣지 않는다.** Flutter 는 `firebase_options.dart.template` 만 두고
실파일은 `.gitignore` — 새 앱은 `flutterfire configure` 로 자기 것을 만든다. 웹은 전부 환경변수다.

레시피에는 규칙이 하나 있다: **아무 데서도 import 되지 않는다.** 쓸 때 복사해 가는 코드 한 장이라,
카카오가 API 를 바꿔 그게 낡아도 **어떤 앱도 깨지지 않고 따라 올릴 버전도 없다.**
대신 맨 위에 기준일과 공식 문서 링크를 단다 — 날짜가 곧 경고다. 낡았다고 지우지 않는다.

## 쌓아 가는 것

다시 묻지 않을 것을 담는 자리는 둘이고, 둘은 대등하지 않다.

**프로젝트의 `CLAUDE.md`** 가 그 프로젝트의 규칙이고 이긴다. 이 저장소의 `conventions/` 는 하네스
저자의 기본값이다 — 스택 규칙, 디자인 시스템, 일하는 방식(예: 종류마다 달라지는 것은 프롬프트
문자열이 아니라 enum 과 빠짐없는 표로). 파일마다 `applies:` 가 있어서 남의 Next 앱에 Flutter 규칙을
들이대지 않는다. 인터뷰에서 내린 결정은 둘 다 이긴다 — `## Decisions` 가 어떤 상시 규칙보다 새것이다.

관행이 굳으면 그 줄은 **그 프로젝트의 `CLAUDE.md`** 로 간다. 플러그인 디렉토리에 쓰지 않는다 —
거긴 버전별 캐시라 다음 설치에 고아가 된다. 같은 줄이 두 번째 프로젝트에서 또 나오면, 그때
여기 `conventions/` 로 PR 을 보낼 자격이 생긴 것이다.

일이 도는 동안 `CLAUDE.md` 는 얼어 있다. 계획은 그 규칙을 기준으로 승인됐으니, 통과시키려고 규칙을
고치는 건 승인 뒤 계획을 고치는 것과 같은 속임수다. 인터뷰는 여기부터 읽고,
**여기 적힌 것은 다시 묻지 않는다.** 일이 끝나고 새로 굳은 관행이 생기면 한 줄 더한다 —
하네스가 자라는 자리는 여기다.

## 안 만드는 것

`docs/` 6종 세트(PRD·ARCHITECTURE·RULES·DESIGN·TASKS·MEMORY), `plans/` 디렉토리, 전역 규칙 파일,
ralph-loop 의존. 파일은 진행 중 `.claude/prd.md` 한 장이고 끝나면 지운다.
자율 루프는 Stop 훅이 곧 루프라 사용자가 켤 일이 없다 — 트리거가 슬래시 명령이 아니라 `state` 값이다.

## 검증

```bash
python3 hooks/tests/gates.test.py      # 게이트 단위 33건 — 위반·오차단 양방향
python3 hooks/tests/lifecycle.test.py  # 한 바퀴 13건 — interview→done 연쇄
```

한 바퀴 검증이 재는 것은 하나다: **사용자에게 턴이 넘어가는 횟수가 정확히 2회.**

아직 안 한 것: 플러그인을 실제로 물린 **라이브 세션 한 바퀴**. 위 검증은 훅을 직접 호출해 잰 것이라,
Claude Code 가 훅을 등록하고 부르는 경로 자체는 `/midnight-vibe:doctor` 로 확인해야 한다.

## 업데이트

```bash
claude plugin marketplace add hyperitycorp-jkh/midnight-vibe   # 한 번만
claude plugin install midnight-vibe@midnight-vibe
```

**세션이 시작될 때 등록된 훅은 재설치로 바뀌지 않는다.** 새 버전이 깔리고 `claude plugin list` 에도
그렇게 보이지만, 돌고 있는 세션은 새 세션을 열기 전까지 옛 훅 스크립트를 계속 부른다.
방금 업데이트했는데 동작이 그대로라면 이유는 그것이다.

## 끄기

```bash
export CLAUDE_HARNESS_OFF=1   # 이번만
touch .claude/harness.off     # 이 프로젝트에서 계속
```

훅보다 먼저 있는 스위치다. 하네스가 일을 방해하면 끄는 게 맞다.

## 라이선스

MIT.
