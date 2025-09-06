#!/bin/bash

echo "=== Phase 2 Security Hardening Tests ==="
echo ""

# Start the server in background
cd /mnt/d/log-reg
node server.js &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to be ready..."
for i in {1..15}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "Server is ready!"
        break
    fi
    sleep 1
done

echo "✅ **Checkpoint 1 – Security Headers**"
echo "Command: curl -i http://localhost:8080/health"
echo ""

HEADERS_RESPONSE=$(curl -s -i http://localhost:8080/health)
echo "$HEADERS_RESPONSE"
echo ""

# Check for specific headers
if echo "$HEADERS_RESPONSE" | grep -q "Content-Security-Policy"; then
    echo "✅ Content-Security-Policy header present"
else
    echo "❌ Content-Security-Policy header missing"
fi

if echo "$HEADERS_RESPONSE" | grep -q "Referrer-Policy"; then
    echo "✅ Referrer-Policy header present"
else
    echo "❌ Referrer-Policy header missing"
fi

if echo "$HEADERS_RESPONSE" | grep -q "X-Powered-By"; then
    echo "❌ X-Powered-By header found (should be removed)"
else
    echo "✅ X-Powered-By header properly removed"
fi

echo ""
echo "---"

echo "✅ **Checkpoint 2 – Rate Limiting**"
echo "Command: 25 rapid login attempts with wrong password..."
echo ""

# Create a test user first
curl -s -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"ratetest@example.com","username":"ratetest","password":"SuperStrongPass#123"}' > /dev/null

echo "Testing rate limiting with rapid login attempts:"
RATE_LIMIT_HIT=false
for i in {1..25}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST http://localhost:8080/auth/login \
      -H "Content-Type: application/json" \
      -d '{"emailOrUsername":"ratetest","password":"wrongpassword"}')
    
    if [ "$HTTP_CODE" = "429" ]; then
        echo "✅ Rate limit hit at attempt $i (HTTP 429)"
        RATE_LIMIT_HIT=true
        break
    elif [ $i -le 5 ] || [ $((i % 5)) -eq 0 ]; then
        echo "Attempt $i: HTTP $HTTP_CODE"
    fi
done

if [ "$RATE_LIMIT_HIT" = false ]; then
    echo "❌ Rate limiting not working - no 429 responses"
fi

echo ""
echo "---"

echo "✅ **Checkpoint 3 – CSRF Protection**"
echo ""

echo "Step A: Get CSRF token"
echo "Command: curl -c cookies.txt -b cookies.txt http://localhost:8080/auth/csrf"
CSRF_RESPONSE=$(curl -s -c cookies.txt -b cookies.txt http://localhost:8080/auth/csrf)
echo "Response: $CSRF_RESPONSE"

# Extract CSRF token from response
CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | grep -o '"csrfToken":"[^"]*"' | cut -d'"' -f4)
echo "Extracted CSRF Token: $CSRF_TOKEN"
echo ""

echo "Step B: Call protected endpoint WITHOUT CSRF token"
echo "Command: curl -X POST http://localhost:8080/auth/logout (without CSRF)"
NO_CSRF_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/logout \
  -c cookies.txt -b cookies.txt)
echo "Response without CSRF: $NO_CSRF_RESPONSE"
echo ""

echo "Step C: Call protected endpoint WITH CSRF token"
echo "Command: curl -X POST http://localhost:8080/auth/logout (with CSRF header)"

# First login to get a refresh token
curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt -b cookies.txt \
  -d '{"emailOrUsername":"ratetest","password":"SuperStrongPass#123"}' > /dev/null

WITH_CSRF_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/logout \
  -c cookies.txt -b cookies.txt \
  -H "x-csrf-token: $CSRF_TOKEN")
echo "Response with CSRF: $WITH_CSRF_RESPONSE"
echo ""

echo "---"

echo "✅ **Checkpoint 4 – Error Handling**"
echo "Command: curl -i http://localhost:8080/unknown"
echo ""

ERROR_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:8080/unknown)
echo "Error response: $ERROR_RESPONSE"
echo ""

# Stop the server
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "=== Phase 2 Security Testing Complete ==="
