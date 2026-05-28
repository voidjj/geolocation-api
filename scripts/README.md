# Testing Scripts

## Quick Start

### 1. Start the application
```bash
docker-compose up --build
```

### 2. Setup database with seeds
```bash
./scripts/setup-db.sh
```

### 3. Run API tests
```bash
./scripts/test-api.sh [API_KEY] [BASE_URL]

# Default:
./scripts/test-api.sh

# Custom:
./scripts/test-api.sh mykey123 http://localhost:3000
```

## Test ipstack provider

Get free API key: https://ipstack.com/signup/free

```bash
# Test ipstack directly
IPSTACK_API_KEY=your_key_here ./scripts/test-ipstack.sh 8.8.8.8

# Or without key (shows error with instructions)
./scripts/test-ipstack.sh
```

## Manual curl commands

```bash
# Health check
curl http://localhost:3000/up

# Get geolocation (seed data - no ipstack needed)
curl -H "X-API-Key: test123" http://localhost:3000/api/v1/geolocations/8.8.8.8

# Create new geolocation (requires ipstack key)
curl -X POST -H "X-API-Key: test123" -H "Content-Type: application/json" \
  http://localhost:3000/api/v1/geolocations \
  -d '{"geolocation": {"host": "google.com"}}'

# Delete geolocation
curl -X DELETE -H "X-API-Key: test123" \
  http://localhost:3000/api/v1/geolocations/google.com
```

## Postman / HTTP Client

**Base URL:** `http://localhost:3000`

**Headers for all requests:**
- `X-API-Key: test123`
- `Content-Type: application/json` (for POST)

**Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/up` | Health check |
| GET | `/api/v1/geolocations/:host` | Get geolocation |
| POST | `/api/v1/geolocations` | Create geolocation |
| DELETE | `/api/v1/geolocations/:host` | Delete geolocation |

**POST body:**
```json
{
  "geolocation": {
    "host": "google.com"
  }
}
```

## Test without ipstack (seeds only)

If you don't have ipstack API key, you can still test with seed data:

```bash
# These work without ipstack (pre-loaded in seeds)
curl -H "X-API-Key: test123" http://localhost:3000/api/v1/geolocations/8.8.8.8
curl -H "X-API-Key: test123" http://localhost:3000/api/v1/geolocations/1.1.1.1
curl -H "X-API-Key: test123" http://localhost:3000/api/v1/geolocations/example.com
```
