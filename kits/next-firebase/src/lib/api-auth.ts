import { NextRequest, NextResponse } from 'next/server'
import { getAuth } from 'firebase-admin/auth'
import { getFirestore } from 'firebase-admin/firestore'
import { getAppCheck } from 'firebase-admin/app-check'
import { initAdminApp } from '@/services/firebase/admin'

initAdminApp()

export interface AuthedUser {
  uid: string
  role: string
}

// App Check enforce 모드 — 'monitor'면 검증 실패해도 통과시키되 로그만 남김.
// Firebase Console에서 Enforce 켠 후 prod에서 'enforce'로 전환.
const APPCHECK_MODE = (process.env.APPCHECK_MODE ?? 'monitor') as 'monitor' | 'enforce'

async function verifyAppCheck(req: NextRequest): Promise<NextResponse | null> {
  const token = req.headers.get('x-firebase-appcheck')
  if (!token) {
    if (APPCHECK_MODE === 'enforce') {
      return NextResponse.json({ error: 'Missing App Check token' }, { status: 401 })
    }
    console.warn('[AppCheck:monitor] missing token on', req.nextUrl.pathname)
    return null
  }

  try {
    await getAppCheck().verifyToken(token)
    return null
  } catch (err) {
    if (APPCHECK_MODE === 'enforce') {
      return NextResponse.json({ error: 'Invalid App Check token' }, { status: 401 })
    }
    const msg = err instanceof Error ? err.message : 'unknown'
    console.warn('[AppCheck:monitor] verify failed on', req.nextUrl.pathname, msg)
    return null
  }
}

export async function verifyAuth(req: NextRequest): Promise<AuthedUser | NextResponse> {
  const appCheckErr = await verifyAppCheck(req)
  if (appCheckErr) return appCheckErr

  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return NextResponse.json({ error: 'Missing authorization token' }, { status: 401 })
  }

  const token = authHeader.slice(7)
  try {
    const decoded = await getAuth().verifyIdToken(token)
    const userDoc = await getFirestore().doc(`users/${decoded.uid}`).get()
    const role = userDoc.data()?.role ?? 'member'
    return { uid: decoded.uid, role }
  } catch {
    return NextResponse.json({ error: 'Invalid or expired token' }, { status: 401 })
  }
}

export function requireAdmin(user: AuthedUser): NextResponse | null {
  if (user.role !== 'admin' && user.role !== 'superadmin') {
    return NextResponse.json({ error: 'Forbidden: admin access required' }, { status: 403 })
  }
  return null
}

export function isAuthedUser(result: AuthedUser | NextResponse): result is AuthedUser {
  return 'uid' in result
}
