#!/bin/bash
#
# Setup database and seeds in Docker
# Usage: ./scripts/setup-db.sh
#

set -e

echo "=========================================="
echo "🗄️  Database Setup"
echo "=========================================="

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Docker containers not running!"
    echo "Start them first with: docker-compose up -d"
    exit 1
fi

echo "Creating database..."
docker-compose exec app bin/rails db:create db:migrate 2>/dev/null || echo "Database already exists"

echo ""
echo "Loading seed data..."
docker-compose exec app bin/rails db:seed

echo ""
echo "=========================================="
echo "✅ Database setup complete!"
echo ""
echo "Seed data loaded:"
echo "  - 8.8.8.8 (Google DNS)"
echo "  - 1.1.1.1 (Cloudflare)"
echo "  - github.com"
echo "  - example.com"
echo ""
echo "Test with:"
echo "  curl -H \"X-API-Key: test123\" http://localhost:3000/api/v1/geolocations/8.8.8.8"
echo "=========================================="
