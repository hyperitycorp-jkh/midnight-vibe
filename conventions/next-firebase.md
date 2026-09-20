---
name: next-firebase
applies: Next.js (App Router) 웹 (kits/next-firebase 로 시작한 것 포함)
---

# Next.js — App Router · Firebase

**인터뷰에서 이걸 다시 묻지 않는다.**

## 구조

```
src/
  app/         라우트만. 화면 로직을 여기 쌓지 않는다
  modules/     기능 단위 — 그 기능의 화면·상태·호출이 한 폴더에
  widgets/     여러 기능이 같이 쓰는 UI
  services/    외부 세계 (firebase/*, 외부 API)
  stores/      전역 상태 (zustand)
  lib/         순수 유틸·검증·로깅
  config/      상수
  types/       공용 타입
```

## 지키는 것

- **Firebase 설정은 전부 환경변수.** 코드에 키를 박지 않는다. `NEXT_PUBLIC_` 은 브라우저로
  나가는 값에만 — Admin 자격증명에 붙이면 계정이 통째로 열린다.
- 클라이언트 키가 공개되는 건 정상이다. 대신 **App Check·보안 규칙·API 키 제한이 실제로 걸려 있어야 한다.**
- 커스텀 토큰 발급·관리자 작업은 **서버(route handler)에서만.**
- 외부 리다이렉트는 화이트리스트로 검사한다.
- 초기화는 `getApps().length ? getApp() : initializeApp(...)` — hot reload 중복 초기화를 막는다.
