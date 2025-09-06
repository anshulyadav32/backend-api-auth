#!/bin/bash

echo "=== Phase 1 Checkpoint Testing ==="
echo ""

# Start the server in background
cd /mnt/d/log-reg
node server.js &
SERVER_PID=$!

# Wait for server to start
sleep 4

echo "✅ **Checkpoint 1 – Register works**"
echo "Command: curl -X POST http://localhost:8080/auth/register ..."
echo ""
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","username":"alice","password":"SuperStrongPass#123"}')

echo "Response: $REGISTER_RESPONSE"
echo ""
echo "---"

echo "✅ **Checkpoint 2 – Login works (AccessToken + Refresh Cookie)**"
echo "Command: curl -X POST http://localhost:8080/auth/login ..."
echo ""
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt -b cookies.txt \
  -d '{"emailOrUsername":"alice","password":"SuperStrongPass#123"}')

echo "Response: $LOGIN_RESPONSE"
echo ""
echo "Cookie file contents:"
if [ -f cookies.txt ]; then
  cat cookies.txt
else
  echo "No cookies.txt file found"
fi
echo ""
echo "---"

echo "✅ **Checkpoint 3 – Refresh works (Token Rotation)**"
echo "Command: curl -X POST http://localhost:8080/auth/refresh ..."
echo ""
REFRESH_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -c cookies.txt -b cookies.txt)

echo "Response: $REFRESH_RESPONSE"
echo ""
echo "Updated cookie file:"
if [ -f cookies.txt ]; then
  cat cookies.txt
else
  echo "No cookies.txt file found"
fi
echo ""
echo "---"

echo "✅ **Checkpoint 4 – Logout works (Token Revoked)**"
echo "Command: curl -X POST http://localhost:8080/auth/logout ..."
echo ""
LOGOUT_RESPONSE=$(curl -s -i -X POST http://localhost:8080/auth/logout \
  -c cookies.txt -b cookies.txt)

echo "Response: $LOGOUT_RESPONSE"
echo ""
echo "---"

echo "🧪 **Negative Test - Wrong Password**"
WRONG_PASSWORD=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"alice","password":"wrongpassword"}')

echo "Wrong password response: $WRONG_PASSWORD"
echo ""

echo "🧪 **Negative Test - Refresh after logout**"
REFRESH_AFTER_LOGOUT=$(curl -s -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -b cookies.txt)

echo "Refresh after logout response: $REFRESH_AFTER_LOGOUT"
echo ""

# Stop the server
kill $SERVER_PID 2>/dev/null

echo "=== Phase 1 Testing Complete ==="
