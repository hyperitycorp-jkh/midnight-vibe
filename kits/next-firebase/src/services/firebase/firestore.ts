import { initializeFirestore } from 'firebase/firestore'
import { firebaseApp } from './config'

export const db = initializeFirestore(firebaseApp, {})
