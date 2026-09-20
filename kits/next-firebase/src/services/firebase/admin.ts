import { getApps, initializeApp, cert } from 'firebase-admin/app'

export function initAdminApp() {
  if (getApps().length > 0) return

  const projectId = process.env.FIREBASE_ADMIN_PROJECT_ID
  const clientEmail = process.env.FIREBASE_ADMIN_CLIENT_EMAIL
  const privateKey = process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n')

  if (clientEmail && privateKey) {
    initializeApp({ credential: cert({ projectId, clientEmail, privateKey }) })
  } else {
    // 로컬 개발: Application Default Credentials (gcloud auth application-default login)
    initializeApp({ projectId })
  }
}
