#!/bin/bash

echo "Starting server and running tests..."

# Start the server in background
cd /mnt/d/log-reg
node debug-server.js &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "Testing health endpoint..."
curl -s http://localhost:8080/health

echo ""
echo "Testing POST endpoint..."
curl -s -X POST http://localhost:8080/test -H "Content-Type: application/json" -d '{"test": "data"}'

echo ""
echo "Stopping server..."
kill $SERVER_PID

echo "Test completed!"
