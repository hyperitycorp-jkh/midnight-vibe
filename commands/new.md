---
description: 킷으로 새 앱을 시작한다 — /midnight-vibe:new <kit> <경로>
argument-hint: "flutter-cubit-firebase|next-firebase  ~/Dev/my-app"
---

새 앱을 만든다. 인자: 킷 이름과 만들 경로. 둘 중 하나가 없으면 되물어라(아직 인터뷰 국면이다).

1. `${CLAUDE_PLUGIN_ROOT}/kits/` 를 보여 주고 고른 킷이 실제로 있는지 확인한다.
2. `cp -R "${CLAUDE_PLUGIN_ROOT}/kits/<킷>/" <경로>` — 대상이 이미 있으면 덮지 말고 멈춘다.
3. 대상에서 `git init`, 그리고 킷의 `START.md`(있으면)를 따라 초기화한다.
   Flutter 면 `flutterfire configure` 가 `lib/firebase_options.dart` 를 만든다는 것을,
   웹이면 `.env.example` 을 `.env.local` 로 복사해 채워야 한다는 것을 알린다.
4. 그 폴더에서 이어서 일하려면 세션을 거기서 열어야 한다는 것을 한 줄로 알린다.
5. **아직 기능을 만들지 마라.** 무엇을 만들 앱인지 물어 `.claude/prd.md` 부터 세운다.

킷은 출발점이지 정답이 아니다. 새 앱에서 구조를 바꿨다면 그게 좋은 판단이었는지 끝나고 한 줄로 남겨라 —
반복되면 킷으로 돌아와야 한다.
