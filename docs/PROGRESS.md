# 31 DEGREES - Progress Report

## Phase Status: Phase 1A (Foundation)
**Status**: BLOCKED

### Decisions Made
- Migrations 00001-00016 generated.
- RLS policies fully defined.
- Roles structured using the non-recursive SECURITY DEFINER helper function approach.

### Open Issues
- **Database Local Setup**: Supabase CLI cannot run locally because Docker is not available.
- **API Tests**: Cannot run curl requests without a running backend.
- **RLS Matrix Test**: Blocked by database unavailability.

### NEEDS_CLIENT_INPUT
- Live IntaSend keys
- Turnstile site/secret keys
- Email provider API keys
- Real stations details & coordinates
- Franchise application details (funding capacity bands, SLA timing)

### Phase 1A Checklist
- [x] Repo & tooling
- [x] Image pre-flight
- [x] Supabase project (Schema & RLS defined)
- [x] Edge function structure
- [x] CI stubbed
- [ ] Database applied to empty DB (BLOCKED)
- [ ] `pg_tables` check (BLOCKED)
- [ ] RLS matrix pass (BLOCKED)
- [ ] `API.md` with real curl proofs (BLOCKED)
