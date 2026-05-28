#!/bin/bash
#
# API Testing Script for Geolocation API
# Usage: ./scripts/test-api.sh [API_KEY] [BASE_URL]
#

set -e

API_KEY="${1:-test123}"
BASE_URL="${2:-http://localhost:3000}"

echo "=========================================="
echo "🧪 Testing Geolocation API"
echo "=========================================="
echo "API Key: $API_KEY"
echo "Base URL: $BASE_URL"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function for testing
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local description=$5

    echo -n "Testing: $description ... "

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint" 2>/dev/null || echo -e "\n000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "X-API-Key: $API_KEY" \
            "$BASE_URL$endpoint" 2>/dev/null || echo -e "\n000")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS ($http_code)${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL (expected $expected_status, got $http_code)${NC}"
        echo "Response: $body"
        return 1
    fi
}

echo "📋 TEST SUITE"
echo "=========================================="

# Test 1: Health check
test_endpoint "GET" "/up" "" "200" "Health check endpoint"

# Test 2: GET without API key (should fail)
echo -n "Testing: Request without API key ... "
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/v1/geolocations/8.8.8.8" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "401" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - Unauthorized)${NC}"
else
    echo -e "${YELLOW}⚠ Expected 401, got $http_code${NC}"
fi

# Test 3: GET with invalid API key
echo -n "Testing: Request with invalid API key ... "
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: wrong_key" "$BASE_URL/api/v1/geolocations/8.8.8.8" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "401" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - Unauthorized)${NC}"
else
    echo -e "${YELLOW}⚠ Expected 401, got $http_code${NC}"
fi

echo ""
echo "🌐 SEED DATA TESTS (no ipstack needed)"
echo "=========================================="

# Test 4: Get seed data - Google DNS
test_endpoint "GET" "/api/v1/geolocations/8.8.8.8" "" "200" "GET Google DNS (8.8.8.8) - from seeds"

# Test 5: Get seed data - Cloudflare
test_endpoint "GET" "/api/v1/geolocations/1.1.1.1" "" "200" "GET Cloudflare (1.1.1.1) - from seeds"

# Test 6: Get seed data - example.com
test_endpoint "GET" "/api/v1/geolocations/example.com" "" "200" "GET example.com - from seeds"

echo ""
echo "📝 CREATE / DELETE TESTS"
echo "=========================================="

# Test 7: Create new geolocation (requires ipstack key or will fail gracefully)
echo -n "Testing: POST new geolocation (github.com) ... "
response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"geolocation": {"host": "github.com"}}' \
    "$BASE_URL/api/v1/geolocations" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" = "201" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - Created)${NC}"
elif [ "$http_code" = "503" ]; then
    echo -e "${YELLOW}⚠ SERVICE UNAVAILABLE (ipstack not configured?)${NC}"
else
    echo -e "${RED}✗ FAIL (expected 201 or 503, got $http_code)${NC}"
fi

# Test 8: Delete geolocation
test_endpoint "DELETE" "/api/v1/geolocations/github.com" "" "204" "DELETE github.com"

# Test 9: Try to get deleted geolocation
test_endpoint "GET" "/api/v1/geolocations/github.com" "" "404" "GET github.com after deletion (should be 404)"

echo ""
echo "=========================================="
echo "✅ Test suite completed!"
echo "=========================================="
echo ""
echo "📝 Manual Testing with curl examples:"
echo "=========================================="
echo ""
echo "# Health check:"
echo "curl http://localhost:3000/up"
echo ""
echo "# Get geolocation (with seed data):"
echo "curl -H \"X-API-Key: $API_KEY\" http://localhost:3000/api/v1/geolocations/8.8.8.8"
echo ""
echo "# Create new geolocation:"
echo "curl -X POST -H \"X-API-Key: $API_KEY\" -H \"Content-Type: application/json\" \\"
echo "  http://localhost:3000/api/v1/geolocations \\"
echo "  -d '{\"geolocation\": {\"host\": \"google.com\"}}'"
echo ""
echo "# Delete geolocation:"
echo "curl -X DELETE -H \"X-API-Key: $API_KEY\" \\"
echo "  http://localhost:3000/api/v1/geolocations/google.com"
echo ""
echo "=========================================="
