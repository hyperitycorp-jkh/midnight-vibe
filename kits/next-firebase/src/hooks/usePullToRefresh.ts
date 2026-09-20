'use client'

import { useRef, useEffect, useState, useCallback } from 'react'

const THRESHOLD = 80

export function usePullToRefresh(onRefresh: () => Promise<void>) {
  const [pulling, setPulling] = useState(false)
  const [refreshing, setRefreshing] = useState(false)
  const [pullDistance, setPullDistance] = useState(0)
  const startY = useRef(0)
  const isDragging = useRef(false)

  const handleTouchStart = useCallback((e: TouchEvent) => {
    if (window.scrollY > 0 || refreshing) return
    startY.current = e.touches[0].clientY
    isDragging.current = true
  }, [refreshing])

  const handleTouchMove = useCallback((e: TouchEvent) => {
    if (!isDragging.current) return
    const diff = e.touches[0].clientY - startY.current
    if (diff < 0) { isDragging.current = false; setPullDistance(0); setPulling(false); return }
    setPullDistance(Math.min(diff * 0.4, THRESHOLD * 1.5))
    setPulling(diff > THRESHOLD)
  }, [])

  const handleTouchEnd = useCallback(async () => {
    if (!isDragging.current) return
    isDragging.current = false
    if (pulling) {
      setRefreshing(true)
      setPullDistance(THRESHOLD * 0.6)
      try { await onRefresh() } finally {
        setRefreshing(false)
        setPullDistance(0)
        setPulling(false)
      }
    } else {
      setPullDistance(0)
      setPulling(false)
    }
  }, [pulling, onRefresh])

  useEffect(() => {
    document.addEventListener('touchstart', handleTouchStart, { passive: true })
    document.addEventListener('touchmove', handleTouchMove, { passive: true })
    document.addEventListener('touchend', handleTouchEnd)
    return () => {
      document.removeEventListener('touchstart', handleTouchStart)
      document.removeEventListener('touchmove', handleTouchMove)
      document.removeEventListener('touchend', handleTouchEnd)
    }
  }, [handleTouchStart, handleTouchMove, handleTouchEnd])

  return { pullDistance, refreshing }
}
