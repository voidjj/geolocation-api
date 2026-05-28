# Geolocation API

A RESTful API for storing and retrieving geolocation data based on IP addresses or domain names. Built with Rails 8, PostgreSQL, and [ipstack](https://ipstack.com) as the geolocation provider.

## Requirements

- Ruby 3.4.7
- PostgreSQL
- API key for authentication (`API_KEY` env var)
- ipstack API key ([ipstack.com](https://ipstack.com)) — for geolocation lookups

## Quick Start (Docker Compose)

The easiest way to run the application — PostgreSQL is included:

```bash
cp .env.example .env   # fill in RAILS_MASTER_KEY, IPSTACK_API_KEY, API_KEY
docker-compose up --build
```

App will be available at `http://localhost:3000`.

To load sample geolocation records (no ipstack key needed):

```bash
docker-compose exec app bin/rails db:seed
```

> The Dockerfile uses a multi-stage build with jemalloc and runs as a non-root user.


## Local Development

```bash
bundle install
cp .env.example .env  # fill in your keys
rails db:create db:migrate db:seed
rails server
```

Environment variables (`.env`):

```env
IPSTACK_API_KEY=your_ipstack_key
API_KEY=your_api_key
DATABASE_URL=postgresql://localhost/geolocation_api_development
```

## Running Tests

```bash
bundle exec rspec
```

## Linting

```bash
bundle exec rubocop
```

## API

All endpoints require the `X-API-Key` header.

### GET /api/v1/geolocations/:id

Returns stored geolocation data for the given IP or domain.

```bash
curl -H "X-API-Key: your_key" http://localhost:3000/api/v1/geolocations/example.com
```

### POST /api/v1/geolocations

Fetches geolocation from ipstack and stores it.

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "X-API-Key: your_key" \
  -H "Content-Type: application/json" \
  -d '{"geolocation": {"host": "example.com"}}'
```

### DELETE /api/v1/geolocations/:id

Deletes stored geolocation.

```bash
curl -X DELETE -H "X-API-Key: your_key" http://localhost:3000/api/v1/geolocations/example.com
```

## Response Codes

| Code | Description |
|------|-------------|
| 200  | OK |
| 201  | Created |
| 204  | Deleted |
| 401  | Missing or invalid API key |
| 404  | Not found |
| 409  | Geolocation already exists for this host |
| 422  | Validation error or provider failure |

---

## Design Decisions

- **Thin controllers** — no business logic; delegates to `LookupService` and `Creator`
- **Provider abstraction** — `LookupService` accepts any provider via `provider:` DI argument; swapping ipstack requires only a new class implementing `#fetch(host)`
- **Faraday over the official ipstack gem** — the official gem is unmaintained; Faraday gives full control over timeouts and error handling
- **dry-schema** — ipstack responses are validated at the boundary before anything is stored
- **`host` as unique key, `ip` stored separately** — `host` is what the client submits (domain or IP) and is the lookup key; `ip` is the resolved address from ipstack. No DNS resolution on insert — that would add failure modes not required by the task
- **Only core geo fields stored** — `raw_response` was deliberately skipped; storing the full provider payload would tie the schema to ipstack's format, which conflicts with the provider-agnostic goal
- **API key auth** — `X-API-Key` header with `secure_compare`
- **Caching** — `Rails.cache` with configurable TTL (`GEOLOCATION_CACHE_TTL`, default 1 day); no Redis needed, `solid_cache` ships with Rails 8
- **LLM tooling** — I used Windsurf / Cascade during development, mainly for test scaffolding and edge case coverage. All generated code was reviewed and adjusted where needed.
