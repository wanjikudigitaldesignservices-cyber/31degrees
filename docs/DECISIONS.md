# Decisions Log

1. **Monorepo structure**: Vercel frontend + Supabase functions. Easy to share TS types (Zod schemas).
2. **Environment Variable Validation**: Handled strictly via Zod at boot. Fails fast if any required secret is missing.
3. **Database normalisation**: Strict 3NF for core entities. Geo stored via PostGIS for fast "nearest station" queries.
4. **RBAC implementation**: Uses Supabase RLS paired with a private `has_role` helper function to avoid infinite recursion bugs common in direct role lookups.
5. **Session persistence**: Standard Supabase localStorage. Mitigated with strict CSP, short JWT life, and mandatory MFA on admin roles.
