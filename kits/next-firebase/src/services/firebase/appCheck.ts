import { getToken, initializeAppCheck, ReCaptchaEnterpriseProvider, type AppCheck } from 'firebase/app-check'
import { firebaseApp } from './config'

let appCheck: AppCheck | null = null

export function initAppCheck(): AppCheck | null {
  if (typeof window === 'undefined') return null
  if (appCheck) return appCheck

  const siteKey = process.env.NEXT_PUBLIC_RECAPTCHA_ENTERPRISE_SITE_KEY
  if (!siteKey) {
    if (process.env.NODE_ENV === 'production') {
      console.warn('[AppCheck] NEXT_PUBLIC_RECAPTCHA_ENTERPRISE_SITE_KEY missing — skipping init')
    }
    return null
  }

  // 로컬 개발: debug token 자동 발급. 콘솔 로그에 출력된 토큰을
  // Firebase Console → App Check → Apps → Manage debug tokens 에 등록.
  // ⚠️ initializeAppCheck 호출 전에 세팅 필수. window는 메인 스레드 표준 글로벌.
  if (process.env.NODE_ENV !== 'production') {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(window as any).FIREBASE_APPCHECK_DEBUG_TOKEN = true
  }

  appCheck = initializeAppCheck(firebaseApp, {
    provider: new ReCaptchaEnterpriseProvider(siteKey),
    isTokenAutoRefreshEnabled: true,
  })

  return appCheck
}

export async function getAppCheckToken(): Promise<string | null> {
  const ac = initAppCheck()
  if (!ac) return null
  try {
    const result = await getToken(ac, /* forceRefresh */ false)
    return result.token
  } catch (err) {
    console.warn('[AppCheck] getToken failed:', err)
    return null
  }
}
