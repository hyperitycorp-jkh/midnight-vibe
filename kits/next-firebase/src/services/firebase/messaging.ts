'use client'

import { getMessaging, getToken, deleteToken, onMessage, type Messaging } from 'firebase/messaging'
import { doc, setDoc, deleteDoc, serverTimestamp, collection, query, where, getDocs, writeBatch } from 'firebase/firestore'
import { firebaseApp } from './config'
import { db } from './firestore'

let messaging: Messaging | null = null

function getFirebaseMessaging(): Messaging | null {
  if (typeof window === 'undefined') return null
  if (!messaging) {
    try {
      messaging = getMessaging(firebaseApp)
    } catch {
      return null
    }
  }
  return messaging
}

// Workbox SW (sw.js)에 Firebase Messaging이 통합됨 — 별도 등록 불필요
async function getSwRegistration(): Promise<ServiceWorkerRegistration | null> {
  if (!('serviceWorker' in navigator)) return null

  // 이전 firebase-messaging-sw.js SW가 남아있으면 제거 (중복 알림 방지)
  const registrations = await navigator.serviceWorker.getRegistrations()
  for (const reg of registrations) {
    if (reg.active?.scriptURL?.includes('firebase-messaging-sw.js')) {
      await reg.unregister()
    }
  }

  return navigator.serviceWorker.ready
}

// FCM 토큰 요청 및 Firestore 저장
export async function requestPushPermission(uid: string): Promise<string | null> {
  try {
    // Native app uses Flutter's firebase_messaging instead of web FCM
    if (isNativeApp()) {
      setupNativeTokenBridge(uid)
      return null
    }

    const m = getFirebaseMessaging()
    if (!m) return null

    if (!('Notification' in window)) return null
    const permission = await Notification.requestPermission()
    if (permission !== 'granted') return null

    const reg = await getSwRegistration()
    if (!reg) return null

    const vapidKey = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY
    const token = await getToken(m, { vapidKey, serviceWorkerRegistration: reg })

    if (token) {
      await setDoc(doc(db, 'fcmTokens', `${uid}_${token.slice(-10)}`), {
        uid,
        token,
        platform: getPlatform(),
        updatedAt: serverTimestamp(),
      })
    }

    return token
  } catch (err) {
    console.error('FCM token error:', err)
    return null
  }
}

// FCM 토큰 삭제 (로그아웃 시) — 이 기기 토큰 한 건만
export async function removePushToken(uid: string, token: string): Promise<void> {
  try {
    await deleteDoc(doc(db, 'fcmTokens', `${uid}_${token.slice(-10)}`))
  } catch {
    // ignore
  }
}

// 푸시 끄기 — 이 기기 구독을 완전 해제
// Why: localStorage 플래그만 끄면 서버는 여전히 Firestore 토큰으로 발송함.
// 토큰 회전으로 orphan doc이 남거나 doc id 패턴이 어긋나면 단건 삭제로는 못 지움.
// 1) 이 기기의 현재 FCM 토큰을 알아내 token 일치 doc을 모두 삭제 (orphan 청소)
// 2) FCM 구독을 deleteToken 으로 끊어 OS 레벨로 푸시가 도달하지 않게 함
export async function unsubscribePush(uid: string): Promise<void> {
  const m = getFirebaseMessaging()

  let token: string | null = null
  try {
    const reg = await navigator.serviceWorker?.ready
    if (m && reg) {
      const vapidKey = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY
      token = await getToken(m, { vapidKey, serviceWorkerRegistration: reg })
    }
  } catch (err) {
    console.error('unsubscribePush getToken error:', err)
  }

  if (token) {
    try {
      const q = query(collection(db, 'fcmTokens'), where('uid', '==', uid), where('token', '==', token))
      const snap = await getDocs(q)
      if (!snap.empty) {
        const batch = writeBatch(db)
        snap.docs.forEach((d) => batch.delete(d.ref))
        await batch.commit()
      } else {
        await deleteDoc(doc(db, 'fcmTokens', `${uid}_${token.slice(-10)}`))
      }
    } catch (err) {
      console.error('unsubscribePush firestore cleanup error:', err)
    }
  }

  if (m) {
    try {
      await deleteToken(m)
    } catch (err) {
      console.error('unsubscribePush deleteToken error:', err)
    }
  }
}

// 현재 FCM 토큰 조회 (삭제용)
export async function getCurrentToken(): Promise<string | null> {
  try {
    const m = getFirebaseMessaging()
    if (!m) return null
    const ready = navigator.serviceWorker?.ready
    if (!ready) return null
    const reg = await Promise.race([
      ready,
      new Promise<null>((resolve) => setTimeout(() => resolve(null), 3000)),
    ])
    if (!reg) return null
    const vapidKey = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY
    return await getToken(m, { vapidKey, serviceWorkerRegistration: reg })
  } catch {
    return null
  }
}

// 포그라운드 메시지 수신
export function onForegroundMessage(callback: (payload: { title: string; body: string; data?: Record<string, string> }) => void) {
  const m = getFirebaseMessaging()
  if (!m) return () => {}

  return onMessage(m, (payload) => {
    callback({
      title: payload.notification?.title || 'Hi Xóm',
      body: payload.notification?.body || '',
      data: payload.data as Record<string, string> | undefined,
    })
  })
}

function isNativeApp(): boolean {
  if (typeof navigator === 'undefined') return false
  return /__APP_UA_MARK__/.test(navigator.userAgent)
}

function getPlatform(): string {
  if (typeof navigator === 'undefined') return 'web'
  const ua = navigator.userAgent
  if (isNativeApp()) {
    if (/iPhone|iPad|iPod/.test(ua)) return 'ios-native'
    return 'android-native'
  }
  if (/iPhone|iPad|iPod/.test(ua)) return 'ios'
  if (/Android/.test(ua)) return 'android'
  return 'web'
}

// Flutter 앱에서 네이티브 FCM 토큰을 받아 Firestore에 저장
export function setupNativeTokenBridge(uid: string) {
  if (typeof window === 'undefined' || !isNativeApp()) return

  const saveNativeToken = async (token: string) => {
    const { doc, setDoc, serverTimestamp } = await import('firebase/firestore')
    const { db } = await import('./firestore')
    await setDoc(doc(db, 'fcmTokens', `${uid}_${token.slice(-10)}`), {
      uid,
      token,
      platform: getPlatform(),
      updatedAt: serverTimestamp(),
    })
  }

  // Flutter가 토큰을 이미 주입했으면 바로 저장
  const w = window as unknown as Record<string, unknown>
  const existing = w.__NATIVE_PUSH_TOKEN as string | undefined
  if (existing) {
    saveNativeToken(existing)
  }

  // Flutter가 나중에 토큰을 보내면 콜백으로 저장
  w.__NATIVE_TOKEN_CALLBACK = saveNativeToken
}
