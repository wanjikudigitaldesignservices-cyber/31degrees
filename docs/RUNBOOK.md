# 31 DEGREES - Runbook

## Rollback Procedure
1. Navigate to Vercel dashboard.
2. Select previous deployment.
3. Click "Promote to Production".
4. Revert DB migrations locally, commit rollback migration, push.

## Alerts
- **Payment Webhook Failures**: Check Sentry, manually reconcile with IntaSend dashboard.
- **Cron Job Failures**: Check Supabase logs for `pg_cron` / edge function output.
- **Stale Prices**: Regional managers alerted at 30 days; escalating to HQ at 35 days.
