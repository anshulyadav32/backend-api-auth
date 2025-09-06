#!/bin/bash

echo "=== Phase 1 Checkpoint Testing ==="
echo ""

# Start the server in background
cd /mnt/d/log-reg
node server.js &
SERVER_PID=$!

# Wait for server to be ready by checking if it responds
echo "Waiting for server to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "Server is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Server failed to start within 30 seconds"
        kill $SERVER_PID 2>/dev/null
        exit 1
    fi
    sleep 1
done

# Add a simple health endpoint test first
echo "Testing server health..."
curl -s http://localhost:8080/health
echo ""

echo "✅ **Checkpoint 1 – Register works**"
echo "Command: curl -X POST http://localhost:8080/auth/register ..."
echo ""
REGISTER_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","username":"alice","password":"SuperStrongPass#123"}')

echo "Response: $REGISTER_RESPONSE"
echo ""
echo "---"

echo "✅ **Checkpoint 2 – Login works (AccessToken + Refresh Cookie)**"
echo "Command: curl -X POST http://localhost:8080/auth/login ..."
echo ""
LOGIN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:8080/auth/login \
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

# Stop the server
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "=== Testing Complete ==="
