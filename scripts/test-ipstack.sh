#!/bin/bash
#
# Test ipstack provider directly
# Usage: IPSTACK_API_KEY=your_key ./scripts/test-ipstack.sh [host]
#

set -e

HOST="${1:-8.8.8.8}"
API_KEY="${IPSTACK_API_KEY:-}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: IPSTACK_API_KEY not set"
    echo "Usage: IPSTACK_API_KEY=your_key ./scripts/test-ipstack.sh [host]"
    echo ""
    echo "To get a free API key:"
    echo "1. Go to https://ipstack.com/signup/free"
    echo "2. Sign up for free tier (10,000 requests/month)"
    echo "3. Copy your API key from the dashboard"
    exit 1
fi

echo "=========================================="
echo "🌍 Testing ipstack API directly"
echo "=========================================="
echo "Host: $HOST"
echo "API Key: ${API_KEY:0:5}... (truncated)"
echo ""

response=$(curl -s "http://api.ipstack.com/${HOST}?access_key=${API_KEY}&output=json" 2>/dev/null || echo '{"success":false}')

# Check if response contains error
if echo "$response" | grep -q '"success":false'; then
    echo "❌ ipstack API Error:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
    exit 1
fi

echo "✅ ipstack API Response:"
echo "$response" | jq . 2>/dev/null || echo "$response"
echo ""

# Parse key fields
echo "📊 Key Fields:"
echo "  IP: $(echo "$response" | jq -r '.ip // "N/A"')"
echo "  Country: $(echo "$response" | jq -r '.country_name // "N/A"') ($(echo "$response" | jq -r '.country_code // "N/A"'))"
echo "  Region: $(echo "$response" | jq -r '.region_name // "N/A"')"
echo "  City: $(echo "$response" | jq -r '.city // "N/A"')"
echo "  Zip: $(echo "$response" | jq -r '.zip // "N/A"')"
echo "  Latitude: $(echo "$response" | jq -r '.latitude // "N/A"')"
echo "  Longitude: $(echo "$response" | jq -r '.longitude // "N/A"')"
echo ""
echo "=========================================="
echo "✅ ipstack is working! Add IPSTACK_API_KEY to your .env"
echo "=========================================="
