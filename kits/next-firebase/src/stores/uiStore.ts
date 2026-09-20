import { create } from 'zustand'

interface ConfirmConfig {
  title: string
  message: string
  onConfirm: () => void
}

interface UiStore {
  // 어드민 모드
  isAdminMode: boolean
  setAdminMode: (on: boolean) => void

  // 모달 상태
  loginModalOpen: boolean
  setLoginModalOpen: (open: boolean) => void


  shareModalOpen: boolean
  shareModalUrl: string
  shareModalTitle: string
  openShareModal: (url: string, title: string) => void
  closeShareModal: () => void

  regionModalOpen: boolean
  setRegionModalOpen: (open: boolean) => void

  mobileFilterOpen: boolean
  setMobileFilterOpen: (open: boolean) => void

  confirmConfig: ConfirmConfig | null
  openConfirm: (config: ConfirmConfig) => void
  closeConfirm: () => void
}

export const useUiStore = create<UiStore>((set) => ({
  isAdminMode: false,
  setAdminMode: (on) => { set({ isAdminMode: on }); if (typeof window !== 'undefined') localStorage.setItem('adminMode', String(on)) },

  loginModalOpen: false,
  setLoginModalOpen: (open) => set({ loginModalOpen: open }),


  shareModalOpen: false,
  shareModalUrl: '',
  shareModalTitle: '',
  openShareModal: (url, title) => set({ shareModalOpen: true, shareModalUrl: url, shareModalTitle: title }),
  closeShareModal: () => set({ shareModalOpen: false }),

  regionModalOpen: false,
  setRegionModalOpen: (open) => set({ regionModalOpen: open }),

  mobileFilterOpen: false,
  setMobileFilterOpen: (open) => set({ mobileFilterOpen: open }),

  confirmConfig: null,
  openConfirm: (config) => set({ confirmConfig: config }),
  closeConfirm: () => set({ confirmConfig: null }),
}))
