# 카카오 로그인 → Firebase 커스텀 토큰

**기준일 2026-09.** 카카오가 API 를 바꾸면 이 코드는 낡는다 — 고치지 않고 그대로 둔다.
공식 문서: https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api

## 흐름

`code` → 액세스 토큰 → 카카오 사용자 정보 → Firebase 커스텀 토큰 → 클라이언트가 `signInWithCustomToken`.
커스텀 토큰을 만드는 쪽은 **반드시 서버**다. Admin SDK 자격증명이 브라우저로 나가면 계정 전체가 열린다.

## 쓰는 법

1. `route.ts` 를 `src/app/api/auth/kakao/callback/route.ts` 로 복사한다.
2. `extractLocale`·`sanitizeRedirect` 를 프로젝트 것으로 바꾼다. **리다이렉트 주소는 화이트리스트로 검사한다** —
   여기를 열어 두면 오픈 리다이렉트가 된다.
3. 환경변수: `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`, `FIREBASE_ADMIN_*`, `NEXT_PUBLIC_SITE_URL`.
   전부 서버 전용이다 — `NEXT_PUBLIC_` 을 붙이지 않는다.
4. 카카오 콘솔에 Redirect URI 를 등록한다.

같은 모양으로 Zalo·네이버도 된다. 토큰 교환 주소와 사용자 정보 필드만 다르다.
