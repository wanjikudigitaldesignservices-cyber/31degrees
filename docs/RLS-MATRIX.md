# RLS Matrix

Role definitions and expected database permissions.

| Table | Anon | Customer | Station Manager | Regional Manager | Content Editor | HQ Admin | Super Admin |
|-------|------|----------|-----------------|------------------|----------------|----------|-------------|
| stations | R | R | R, U (own) | R, U (own region) | R | R, U | ALL |
| fuel_prices | R | R | R | R, U (own region drafts) | R | R, U | ALL |
| products | R | R | R | R | R | ALL | ALL |
| orders | None | R (own) | R, U (own station) | R (own region) | None | ALL | ALL |
| franchise_applications | None | None | None | None | None | ALL | ALL |
| user_roles | None | None | None | None | None | R | ALL |

**Note**: All writes to critical tables require MFA for non-customer roles.
