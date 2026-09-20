import {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
  deleteObject,
  listAll,
} from 'firebase/storage'
import { firebaseApp } from './config'
import { logger } from '@/lib/logger'
import { compressImage, compressBannerImage, compressImages } from '@/utils/image'

export const storage = getStorage(firebaseApp)

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif']
const MAX_FILE_SIZE = 10 * 1024 * 1024

function validateImageFile(file: File): void {
  if (!ALLOWED_IMAGE_TYPES.includes(file.type) && !file.type.startsWith('image/')) {
    throw new Error(`Invalid file type: ${file.type}`)
  }
  if (file.size > MAX_FILE_SIZE) {
    throw new Error(`File too large: ${(file.size / 1024 / 1024).toFixed(1)}MB (max 10MB)`)
  }
}

export async function uploadImages(
  folder: string,
  id: string,
  files: File[],
  onProgress?: (completed: number, total: number) => void,
): Promise<string[]> {
  files.forEach(validateImageFile)
  const compressed = await compressImages(files)
  const total = compressed.length
  let completed = 0

  return Promise.all(
    compressed.map(async (file) => {
      const path = `${folder}/${id}/${crypto.randomUUID()}.webp`
      const storageRef = ref(storage, path)
      await uploadBytes(storageRef, file)
      const url = await getDownloadURL(storageRef)
      completed += 1
      onProgress?.(completed, total)
      return url
    }),
  )
}

export async function uploadProfileImage(uid: string, file: File): Promise<string> {
  validateImageFile(file)
  const compressed = await compressImage(file)
  const path = `profiles/${uid}/avatar.webp`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, compressed)
  return getDownloadURL(storageRef)
}

export async function uploadCouponImage(couponId: string, file: File): Promise<string> {
  validateImageFile(file)
  const compressed = await compressBannerImage(file)
  const path = `coupons/${couponId}.webp`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, compressed)
  return getDownloadURL(storageRef)
}

export async function uploadSponsorImage(sponsorId: string, file: File): Promise<string> {
  validateImageFile(file)
  const compressed = await compressImage(file)
  const path = `sponsors/${sponsorId}.webp`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, compressed)
  return getDownloadURL(storageRef)
}

export async function uploadCommunityImages(
  postId: string,
  files: File[],
): Promise<string[]> {
  files.forEach(validateImageFile)
  const compressed = await compressImages(files)
  const uploads = compressed.map(async (file) => {
    const path = `community/${postId}/${crypto.randomUUID()}.webp`
    const storageRef = ref(storage, path)
    await uploadBytes(storageRef, file)
    return getDownloadURL(storageRef)
  })
  return Promise.all(uploads)
}

export async function uploadSeedImage(
  folder: string,
  docId: string,
  sourceUrl: string,
): Promise<string> {
  const res = await fetch(sourceUrl)
  const blob = await res.blob()
  const path = `${folder}/${docId}/${crypto.randomUUID()}.webp`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, blob)
  return getDownloadURL(storageRef)
}

export async function deleteSeedFolder(folder: string, docId: string): Promise<void> {
  try {
    const folderRef = ref(storage, `${folder}/${docId}`)
    const result = await listAll(folderRef)
    await Promise.all(result.items.map((item) => deleteObject(item)))
  } catch (e) {
    logger.warn('storage.deleteSeedFolder', 'Folder may not exist', { folder, docId })
  }
}

export async function uploadLogoImage(file: File): Promise<string> {
  validateImageFile(file)
  const compressed = await compressImage(file)
  const path = `siteConfig/logo.webp`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, compressed)
  return getDownloadURL(storageRef)
}

export async function uploadFavicon(file: File): Promise<string> {
  validateImageFile(file)
  const path = `siteConfig/favicon.png`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, file)
  return getDownloadURL(storageRef)
}

export async function uploadPwaIcon(file: File, size: '192' | '512'): Promise<string> {
  validateImageFile(file)
  const path = `siteConfig/pwa-icon-${size}.png`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, file)
  return getDownloadURL(storageRef)
}

export async function uploadOgImage(file: File): Promise<string> {
  validateImageFile(file)
  const compressed = await compressImage(file)
  const path = `siteConfig/og-image.webp`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, compressed)
  return getDownloadURL(storageRef)
}

export async function deleteFileByUrl(url: string): Promise<void> {
  try {
    const storageRef = ref(storage, url)
    await deleteObject(storageRef)
  } catch (e) {
    logger.warn('storage.deleteFileByUrl', 'File may already be deleted', { url })
  }
}
