export const logger = {
  error: (context: string, error: unknown, meta?: Record<string, unknown>) => {
    console.error(JSON.stringify({
      level: 'error',
      context,
      message: error instanceof Error ? error.message : String(error),
      ...(error instanceof Error && { stack: error.stack }),
      ...meta,
      timestamp: new Date().toISOString(),
    }))
  },
  warn: (context: string, message: string, meta?: Record<string, unknown>) => {
    console.warn(JSON.stringify({ level: 'warn', context, message, ...meta, timestamp: new Date().toISOString() }))
  },
}
