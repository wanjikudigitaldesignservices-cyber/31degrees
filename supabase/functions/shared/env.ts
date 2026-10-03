import { z } from 'zod';

export const serverEnvSchema = z.object({
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  INTASEND_PUBLISHABLE_KEY: z.string().min(1).optional(),
  INTASEND_SECRET_KEY: z.string().min(1).optional(),
  INTASEND_WEBHOOK_CHALLENGE: z.string().min(1).optional(),
  TURNSTILE_SECRET_KEY: z.string().min(1),
  EMAIL_API_KEY: z.string().min(1).optional(),
  EMAIL_FROM: z.string().min(1).optional(),
  VERCEL_DEPLOY_HOOK_URL: z.string().url().optional(),
  ALLOWED_ORIGINS: z.string().min(1),
  BOOTSTRAP_ADMIN_EMAIL: z.string().email(),
});

export function getServerEnv() {
  return serverEnvSchema.parse({
    SUPABASE_SERVICE_ROLE_KEY: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
    INTASEND_PUBLISHABLE_KEY: Deno.env.get('INTASEND_PUBLISHABLE_KEY'),
    INTASEND_SECRET_KEY: Deno.env.get('INTASEND_SECRET_KEY'),
    INTASEND_WEBHOOK_CHALLENGE: Deno.env.get('INTASEND_WEBHOOK_CHALLENGE'),
    TURNSTILE_SECRET_KEY: Deno.env.get('TURNSTILE_SECRET_KEY'),
    EMAIL_API_KEY: Deno.env.get('EMAIL_API_KEY'),
    EMAIL_FROM: Deno.env.get('EMAIL_FROM'),
    VERCEL_DEPLOY_HOOK_URL: Deno.env.get('VERCEL_DEPLOY_HOOK_URL'),
    ALLOWED_ORIGINS: Deno.env.get('ALLOWED_ORIGINS'),
    BOOTSTRAP_ADMIN_EMAIL: Deno.env.get('BOOTSTRAP_ADMIN_EMAIL'),
  });
}
