import { create } from 'zustand'

interface ThemeStore {
  logoUrl: string | null
  isThemeLoaded: boolean
  setLogoUrl: (url: string | null) => void
  setThemeLoaded: (loaded: boolean) => void
}

export const useThemeStore = create<ThemeStore>((set) => ({
  logoUrl: null,
  isThemeLoaded: false,
  setLogoUrl: (url) => set({ logoUrl: url }),
  setThemeLoaded: (loaded) => set({ isThemeLoaded: loaded }),
}))
