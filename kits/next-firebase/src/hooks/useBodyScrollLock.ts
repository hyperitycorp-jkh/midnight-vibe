'use client'

import { useEffect } from 'react'

export function useBodyScrollLock(locked: boolean) {
  useEffect(() => {
    if (!locked) return
    const scrollY = window.scrollY
    document.body.style.position = 'fixed'
    document.body.style.top = `-${scrollY}px`
    document.body.style.left = '0'
    document.body.style.right = '0'
    document.body.style.width = '100%'
    document.body.style.overflow = 'hidden'
    document.body.style.overscrollBehavior = 'none'
    document.body.style.touchAction = 'none'
    document.documentElement.style.overflow = 'hidden'
    return () => {
      document.body.style.position = ''
      document.body.style.top = ''
      document.body.style.left = ''
      document.body.style.right = ''
      document.body.style.width = ''
      document.body.style.overflow = ''
      document.body.style.overscrollBehavior = ''
      document.body.style.touchAction = ''
      document.documentElement.style.overflow = ''
      window.scrollTo(0, scrollY)
    }
  }, [locked])
}
