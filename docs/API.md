# API Documentation

## Endpoints

### `GET /api/v1/stations`
- Auth: None (Anon)
- Rate Limit: High
- Description: Search and filter public stations.
- Curl: (BLOCKED)

### `GET /api/v1/fuel-prices/:townSlug`
- Auth: None (Anon)
- Rate Limit: High
- Description: Current published prices for a town.
- Curl: (BLOCKED)

### `POST /api/v1/franchise-leads`
- Auth: None (Anon) + Turnstile
- Rate Limit: Low
- Description: Submit a prospectus request.
- Curl: (BLOCKED)

*Note: Real curl proofs omitted because local database environment cannot be started (Docker missing).*
