#!/bin/bash

echo "Testing Phase 1 Authentication Endpoints"
echo "========================================"

# Test 1: Registration
echo "1. Testing Registration..."
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"testuser","password":"SuperStrongPass#123"}')

echo "Registration Response: $REGISTER_RESPONSE"
echo ""

# Test 2: Login
echo "2. Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"emailOrUsername":"testuser","password":"SuperStrongPass#123"}')

echo "Login Response: $LOGIN_RESPONSE"
echo ""

# Test 3: Refresh Token
echo "3. Testing Token Refresh..."
REFRESH_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -c cookies.txt)

echo "Refresh Response: $REFRESH_RESPONSE"
echo ""

# Test 4: Logout
echo "4. Testing Logout..."
LOGOUT_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/logout \
  -b cookies.txt)

echo "Logout Response: $LOGOUT_RESPONSE"
echo ""

echo "All tests completed!"
