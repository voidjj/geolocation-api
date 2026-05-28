#!/bin/bash
#
# API Testing Script for Geolocation API
# Usage: ./scripts/test-api.sh [API_KEY] [BASE_URL]
#

set -e

# Read API_KEY from .env if not provided as argument
if [ -f .env ]; then
    ENV_API_KEY=$(grep "^API_KEY=" .env | cut -d'=' -f2 | tr -d ' ')
fi
API_KEY="${1:-${ENV_API_KEY:-test123}}"
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
    body=$(echo "$response" | sed '$d')

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

# Test 4: Get Google DNS (create if needed, then get)
echo -n "Testing: GET Google DNS (8.8.8.8) ... "
curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{"geolocation": {"host": "8.8.8.8"}}' "$BASE_URL/api/v1/geolocations" > /dev/null 2>&1
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$BASE_URL/api/v1/geolocations/8.8.8.8" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then echo -e "${GREEN}✓ PASS ($http_code)${NC}"; else echo -e "${RED}✗ FAIL ($http_code)${NC}"; fi

# Test 5: Get Cloudflare (create if needed, then get)
echo -n "Testing: GET Cloudflare (1.1.1.1) ... "
curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{"geolocation": {"host": "1.1.1.1"}}' "$BASE_URL/api/v1/geolocations" > /dev/null 2>&1
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$BASE_URL/api/v1/geolocations/1.1.1.1" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then echo -e "${GREEN}✓ PASS ($http_code)${NC}"; else echo -e "${RED}✗ FAIL ($http_code)${NC}"; fi

# Test 6: Get example.com (create if needed, then get)
echo -n "Testing: GET example.com ... "
curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{"geolocation": {"host": "example.com"}}' "$BASE_URL/api/v1/geolocations" > /dev/null 2>&1
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$BASE_URL/api/v1/geolocations/example.com" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then echo -e "${GREEN}✓ PASS ($http_code)${NC}"; else echo -e "${RED}✗ FAIL ($http_code)${NC}"; fi

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
echo "🌍 IPSTACK CREATE TESTS (various hosts)"
echo "=========================================="

# Array of test hosts
declare -a HOSTS=(
    "9.9.9.9:Quad9 DNS"
    "208.67.222.222:OpenDNS"
    "cloudflare.com:Cloudflare domain"
    "stackoverflow.com:Stack Overflow"
    "httpbin.org:HTTPBin testing service"
)

for host_data in "${HOSTS[@]}"; do
    IFS=':' read -r host desc <<< "$host_data"
    
    echo -n "Testing: POST $desc ($host) ... "
    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"geolocation\": {\"host\": \"$host\"}}" \
        "$BASE_URL/api/v1/geolocations" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✓ PASS ($http_code)${NC}"
        # Cleanup - delete what we created
        curl -s -X DELETE -H "X-API-Key: $API_KEY" "$BASE_URL/api/v1/geolocations/$host" > /dev/null 2>&1
    elif [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ PASS ($http_code - already existed)${NC}"
    elif [ "$http_code" = "422" ]; then
        echo -e "${YELLOW}⚠ PASS ($http_code - ipstack can't locate this host)${NC}"
    elif [ "$http_code" = "503" ]; then
        echo -e "${YELLOW}⚠ SERVICE UNAVAILABLE (ipstack error)${NC}"
    else
        echo -e "${RED}✗ FAIL ($http_code)${NC}"
    fi
done

echo ""
echo "🔧 EDGE CASE & VALIDATION TESTS"
echo "=========================================="

# Test 10: IPv6 address (if supported)
echo -n "Testing: GET IPv6 address ... "
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" \
    "$BASE_URL/api/v1/geolocations/2001:4860:4860::8888" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "422" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - IPv6 handled)${NC}"
else
    echo -e "${YELLOW}⚠ IPv6 response: $http_code${NC}"
fi

# Test 11: Domain with subdomain - create first, then get
echo -n "Testing: GET subdomain (api.github.com) ... "
# First create via POST (ipstack)
curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{"geolocation": {"host": "api.github.com"}}' \
    "$BASE_URL/api/v1/geolocations" > /dev/null 2>&1
# Then get
response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" \
    "$BASE_URL/api/v1/geolocations/api.github.com" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    echo -e "${GREEN}✓ PASS ($http_code)${NC}"
else
    echo -e "${RED}✗ FAIL ($http_code)${NC}"
fi

# Test 12: Create duplicate (conflict test - should return existing or 201)
echo -n "Testing: POST duplicate host (idempotent) ... "
response1=$(curl -s -w "\n%{http_code}" -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{"geolocation": {"host": "duplicate-test.example.com"}}' \
    "$BASE_URL/api/v1/geolocations" 2>/dev/null || echo -e "\n000")
http_code1=$(echo "$response1" | tail -n1)

if [ "$http_code1" = "201" ] || [ "$http_code1" = "200" ]; then
    # Try to create again - should return same record (200 or 201)
    response2=$(curl -s -w "\n%{http_code}" -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
        -d '{"geolocation": {"host": "duplicate-test.example.com"}}' \
        "$BASE_URL/api/v1/geolocations" 2>/dev/null || echo -e "\n000")
    http_code2=$(echo "$response2" | tail -n1)
    
    if [ "$http_code2" = "200" ] || [ "$http_code2" = "201" ]; then
        echo -e "${GREEN}✓ PASS ($http_code1 then $http_code2 - idempotent)${NC}"
    else
        echo -e "${YELLOW}⚠ Second request returned $http_code2${NC}"
    fi
    
    # Cleanup
    curl -s -X DELETE -H "X-API-Key: $API_KEY" "$BASE_URL/api/v1/geolocations/duplicate-test.example.com" > /dev/null 2>&1
else
    echo -e "${YELLOW}⚠ First creation returned $http_code1 (ipstack needed?)${NC}"
fi

# Test 13: Invalid host format
test_endpoint "GET" "/api/v1/geolocations/not_a_valid_host!@#" "" "404" "GET invalid host format (404 expected)"

# Test 14: Empty request body
echo -n "Testing: POST with empty body ... "
response=$(curl -s -w "\n%{http_code}" -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{}' "$BASE_URL/api/v1/geolocations" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "422" ] || [ "$http_code" = "400" ] || [ "$http_code" = "503" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - validation error)${NC}"
else
    echo -e "${YELLOW}⚠ Empty body returned $http_code${NC}"
fi

# Test 15: Missing host parameter
echo -n "Testing: POST with missing host ... "
response=$(curl -s -w "\n%{http_code}" -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
    -d '{"geolocation": {}}' "$BASE_URL/api/v1/geolocations" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "422" ] || [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - validation error)${NC}"
else
    echo -e "${YELLOW}⚠ Missing host returned $http_code${NC}"
fi

# Test 16: Invalid HTTP method
echo -n "Testing: PUT method (not allowed) ... "
response=$(curl -s -w "\n%{http_code}" -X PUT -H "X-API-Key: $API_KEY" \
    "$BASE_URL/api/v1/geolocations/8.8.8.8" 2>/dev/null || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "405" ] || [ "$http_code" = "404" ]; then
    echo -e "${GREEN}✓ PASS ($http_code - method not allowed)${NC}"
else
    echo -e "${YELLOW}⚠ PUT returned $http_code${NC}"
fi

# Test 17: Special characters in host (encoded)
test_endpoint "GET" "/api/v1/geolocations/localhost" "" "404" "GET localhost (should be 404 - not in seeds)"

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
