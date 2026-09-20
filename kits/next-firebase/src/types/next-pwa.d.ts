declare module 'next-pwa' {
  import type { NextConfig } from 'next'
  interface PWAOptions {
    dest: string
    register?: boolean
    skipWaiting?: boolean
    disable?: boolean
    runtimeCaching?: object[]
  }
  function withPWAInit(options: PWAOptions): (config: NextConfig) => NextConfig
  export = withPWAInit
}
