---
name: flutter-cubit-firebase
applies: Flutter 앱 (kits/flutter-cubit-firebase 로 시작한 것 포함)
---

# Flutter — cubit · Firebase

**인터뷰에서 이걸 다시 묻지 않는다.** 계획이 이 관행을 어기면 승인 전에 고친다.
킷 안의 `CODE_RULES.md` 와 같은 내용이다 — 코드 옆에도, 인터뷰가 읽는 자리에도 둔다.

## 구조

```
lib/
  models/        전체 데이터 모델
  repositories/  Firestore CRUD 전담 — 비즈니스 로직 금지
  services/      외부 API (Auth, Gemini, Storage)
  cubits/        모든 비즈니스 로직과 상태
  pages/         화면
  widgets/       재사용 위젯
  configs/       설정·상수·유틸
```

## 상태

- **cubit 으로만.** `setState` 를 쓰지 않는다. cubit 만 제대로 지키면 상태 관련 에러가 안 난다는 게 실측이다.
- State 는 `Equatable` 상속, 상태 값은 enum.
- `page` 는 위젯을 조립하고 상태로 분기한다. 같은 모양이 두 번 나오면 그때 위젯으로 뽑는다.
- **로딩은 `Stack` 위의 오버레이.** 화면을 치우고 스피너만 남기지 않는다.
- 콜백 함수는 최대한 쓰지 않는다.

## 데이터

- **repository 하나 = 컬렉션 하나**, CRUD 만. 여러 컬렉션 조합·상태 변경은 cubit 으로.
- 파라미터와 반환값은 **모델 객체로 통일** — `fromJson` / `toJson` / `copyWith` / `Equatable`.
- 하드코딩 문자열 대신 enum.
- **스트림을 적극적으로 쓴다.** 한 번 읽고 마는 대신 흐름으로 받는다.
- 집계 쿼리를 쓸 수 있으면 쓴다.

## 스타일

- 로깅은 `Log.d()` / `Log.e()`. try-catch 는 세분화해서.
- `withOpacity()` 대신 `withAlpha()`. nullable 은 `!` 대신 null 체크.
- **워닝이 남은 코드는 커밋하지 않는다.**
- 디자인은 플랫.
