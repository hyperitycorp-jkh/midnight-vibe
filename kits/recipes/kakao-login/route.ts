/**
 * GET /api/auth/kakao/callback
 * Kakao OAuth callback — code → access_token → user info → Firebase Custom Token
 *
 * 응답:
 * - 성공: /{locale}/auth/kakao-complete?token=...&redirect=... 로 리다이렉트
 * - 실패: /auth/login?error=kakao 로 리다이렉트
 */
import { NextRequest, NextResponse } from 'next/server'
import { initializeApp, getApps, cert } from 'firebase-admin/app'
import { getAuth } from 'firebase-admin/auth'
// extractLocale·sanitizeRedirect 는 각자 프로젝트의 것으로 바꾼다 (리다이렉트는 반드시 화이트리스트 검사)
import { extractLocale, sanitizeRedirect } from '@/lib/validation'

function getAdminAuth() {
  if (!getApps().length) {
    initializeApp({
      credential: cert({
        projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
        clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    })
  }
  return getAuth()
}

interface KakaoTokenResponse {
  access_token?: string
  error?: string
  error_description?: string
}

interface KakaoUserResponse {
  id?: number
  kakao_account?: {
    profile?: {
      nickname?: string
      profile_image_url?: string
    }
    email?: string
  }
}

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl
  const code = searchParams.get('code')
  const state = sanitizeRedirect(searchParams.get('state') ?? '/')
  const locale = extractLocale(state, 'ko')
  const loginUrl = `${process.env.NEXT_PUBLIC_SITE_URL}/${locale}/auth/login`

  if (!code) {
    return NextResponse.redirect(`${loginUrl}?error=kakao`)
  }

  try {
    const appKey = process.env.KAKAO_REST_API_KEY!
    const appSecret = process.env.KAKAO_CLIENT_SECRET
    const redirectUri = `${process.env.NEXT_PUBLIC_SITE_URL}/api/auth/kakao/callback`

    // 1. code → access_token
    const tokenParams = new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: appKey,
      redirect_uri: redirectUri,
      code,
    })
    if (appSecret) tokenParams.set('client_secret', appSecret)

    const tokenRes = await fetch('https://kauth.kakao.com/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: tokenParams,
    })
    const tokenData: KakaoTokenResponse = await tokenRes.json()

    if (!tokenData.access_token) {
      console.error('[Kakao OAuth] token error:', tokenData)
      return NextResponse.redirect(`${loginUrl}?error=kakao`)
    }

    // 2. access_token → user profile
    const profileRes = await fetch('https://kapi.kakao.com/v2/user/me', {
      headers: { Authorization: `Bearer ${tokenData.access_token}` },
    })
    const profile: KakaoUserResponse = await profileRes.json()

    if (!profile.id) {
      console.error('[Kakao OAuth] profile error:', profile)
      return NextResponse.redirect(`${loginUrl}?error=kakao`)
    }

    // 3. Firebase Custom Token 발급 (uid = "kakao:{kakao_id}")
    const uid = `kakao:${profile.id}`
    const adminAuth = getAdminAuth()
    const customToken = await adminAuth.createCustomToken(uid, {
      provider: 'kakao',
      kakaoId: String(profile.id),
      name: profile.kakao_account?.profile?.nickname ?? '',
      photoUrl: profile.kakao_account?.profile?.profile_image_url ?? '',
    })

    // 4. 클라이언트에서 signInWithCustomToken 처리할 페이지로 리다이렉트
    const params = new URLSearchParams({ token: customToken, redirect: state })
    return NextResponse.redirect(
      `${process.env.NEXT_PUBLIC_SITE_URL}/${locale}/auth/kakao-complete?${params.toString()}`
    )
  } catch (err) {
    console.error('[Kakao OAuth] unexpected error:', err)
    return NextResponse.redirect(`${loginUrl}?error=kakao`)
  }
}
