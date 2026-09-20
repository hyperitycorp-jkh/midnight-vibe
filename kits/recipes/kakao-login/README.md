# Kakao login → Firebase custom token

**As of 2026-09.** When Kakao changes its API this goes stale — it is left as is, not patched.
Official docs: https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api

## Flow

`code` → access token → Kakao user info → Firebase custom token → the client calls `signInWithCustomToken`.
The custom token is minted **server-side, always**. Admin SDK credentials reaching the browser opens the whole account.

## Using it

1. Copy `route.ts` to `src/app/api/auth/kakao/callback/route.ts`.
2. Replace `extractLocale` and `sanitizeRedirect` with your project's own. **Validate the redirect against a
   whitelist** — leave it open and you have an open redirect.
3. Env vars: `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`, `FIREBASE_ADMIN_*`, `NEXT_PUBLIC_SITE_URL`.
   All server-side — never prefix them with `NEXT_PUBLIC_`.
4. Register the redirect URI in the Kakao console.

Zalo and Naver work the same way. Only the token endpoint and the user-info fields differ.
