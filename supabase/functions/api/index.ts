import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { Hono } from 'https://deno.land/x/hono@v3.12.0/mod.ts'
import { getServerEnv } from '../shared/env.ts'

const app = new Hono()

app.get('/api/v1/health', (c) => {
  const env = getServerEnv()
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: env.ALLOWED_ORIGINS ? 'configured' : 'missing',
  })
})

// Stub endpoints for Phase 1A
app.get('/api/v1/stations', (c) => c.json({ data: [] }))
app.get('/api/v1/fuel-prices/:townSlug', (c) => c.json({ data: [] }))
app.post('/api/v1/franchise-leads', (c) => c.json({ success: true }, 201))

serve(app.fetch)
