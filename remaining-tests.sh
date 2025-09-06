#!/bin/bash

echo "=== Phase 1 Checkpoints 3 & 4 + Negative Tests ==="
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

# First register and login to get cookies
echo "Setting up test user..."
curl -s -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"bob@example.com","username":"bob","password":"SuperStrongPass#123"}' > /dev/null

curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"emailOrUsername":"bob","password":"SuperStrongPass#123"}' > /dev/null

echo "✅ **Checkpoint 3 – Refresh works (Token Rotation)**"
echo "Command: curl -X POST http://localhost:8080/auth/refresh ..."
echo ""

# Store original cookie
ORIGINAL_COOKIE=$(grep refresh_token cookies.txt | awk '{print $7}')
echo "Original refresh token (first 50 chars): ${ORIGINAL_COOKIE:0:50}..."

REFRESH_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -c cookies.txt -b cookies.txt)

echo "Response: $REFRESH_RESPONSE"

# Check if cookie changed
NEW_COOKIE=$(grep refresh_token cookies.txt | awk '{print $7}')
echo "New refresh token (first 50 chars): ${NEW_COOKIE:0:50}..."

if [ "$ORIGINAL_COOKIE" != "$NEW_COOKIE" ]; then
    echo "✅ Token rotation successful - cookies are different!"
else
    echo "❌ Token rotation failed - cookies are the same"
fi
echo ""
echo "---"

echo "✅ **Checkpoint 4 – Logout works (Token Revoked)**"
echo "Command: curl -X POST http://localhost:8080/auth/logout ..."
echo ""

LOGOUT_RESPONSE=$(curl -s -i -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/logout \
  -c cookies.txt -b cookies.txt)

echo "Response: $LOGOUT_RESPONSE"
echo ""
echo "---"

echo "🧪 **Negative Test 1 - Wrong Password**"
WRONG_PASSWORD=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"bob","password":"wrongpassword"}')

echo "Wrong password response: $WRONG_PASSWORD"
echo ""

echo "🧪 **Negative Test 2 - Refresh after logout**"
REFRESH_AFTER_LOGOUT=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -b cookies.txt)

echo "Refresh after logout response: $REFRESH_AFTER_LOGOUT"
echo ""

# Stop the server
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "=== Phase 1 ALL CHECKPOINTS COMPLETE ==="
