import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  signInWithRedirect,
  signInWithCustomToken,
  signInWithPhoneNumber,
  GoogleAuthProvider,
  RecaptchaVerifier,
  signOut,
  sendPasswordResetEmail,
  onAuthStateChanged,
  deleteUser,
  type User,
  type ConfirmationResult,
} from 'firebase/auth'
import { firebaseApp } from './config'

export const auth = getAuth(firebaseApp)

const googleProvider = new GoogleAuthProvider()

export const signInEmail = (email: string, password: string) =>
  signInWithEmailAndPassword(auth, email, password)

export const signUpEmail = (email: string, password: string) =>
  createUserWithEmailAndPassword(auth, email, password)

function isNativeApp(): boolean {
  if (typeof navigator === 'undefined') return false
  return /__APP_UA_MARK__/.test(navigator.userAgent)
}

export const signInGoogle = () => {
  if (isNativeApp()) {
    return signInWithRedirect(auth, googleProvider)
  }
  return signInWithPopup(auth, googleProvider)
}

export const signOutUser = () => signOut(auth)

export const deleteCurrentUser = () => {
  const user = auth.currentUser
  if (!user) throw new Error('No user')
  return deleteUser(user)
}

export const resetPassword = (email: string) =>
  sendPasswordResetEmail(auth, email)

export const signInWithCustom = (customToken: string) =>
  signInWithCustomToken(auth, customToken)

export const onAuthChange = (callback: (user: User | null) => void) =>
  onAuthStateChanged(auth, callback)

export const setupRecaptcha = (containerId: string): RecaptchaVerifier =>
  new RecaptchaVerifier(auth, containerId, { size: 'invisible' })

export const sendPhoneOtp = (
  phone: string,
  verifier: RecaptchaVerifier,
): Promise<ConfirmationResult> => signInWithPhoneNumber(auth, phone, verifier)

export async function getAuthToken(): Promise<string | null> {
  const user = auth.currentUser
  if (!user) return null
  return user.getIdToken()
}

export async function authedFetch(url: string, init?: RequestInit): Promise<Response> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(init?.headers as Record<string, string> ?? {}),
  }
  if (typeof window !== 'undefined') {
    const { getAppCheckToken } = await import('./appCheck')
    const [token, appCheckToken] = await Promise.all([getAuthToken(), getAppCheckToken()])
    if (token) headers['Authorization'] = `Bearer ${token}`
    if (appCheckToken) headers['X-Firebase-AppCheck'] = appCheckToken
  } else {
    const token = await getAuthToken()
    if (token) headers['Authorization'] = `Bearer ${token}`
  }
  return fetch(url, { ...init, headers })
}
