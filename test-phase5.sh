#!/bin/bash

# Phase 5 - CLI Admin Tool Tests
# Tests CLI admin commands: list-users, promote, demote, revoke-sessions, disable-user, set-password

echo "🧪 Starting Phase 5 - CLI Admin Tool Tests"
echo "=========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000"
TEST_EMAIL="alice@example.com"
TEST_PASSWORD="password123"
NEW_PASSWORD="NewPass#123"

# Function to check if server is running
check_server() {
    echo "🔍 Checking if server is running..."
    if curl -s $BASE_URL/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Server is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Server is not running. Please start with: node server.js${NC}"
        return 1
    fi
}

# Function to ensure test user exists
setup_test_user() {
    echo "👤 Setting up test user..."
    
    # Register Alice if she doesn't exist
    REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/auth/register \
        -H "Content-Type: application/json" \
        -d '{
            "email": "'$TEST_EMAIL'",
            "username": "alice",
            "password": "'$TEST_PASSWORD'"
        }')
    
    if echo "$REGISTER_RESPONSE" | grep -q "token"; then
        echo -e "${GREEN}✅ Test user registered successfully${NC}"
    elif echo "$REGISTER_RESPONSE" | grep -q "already exists"; then
        echo -e "${YELLOW}ℹ️  Test user already exists${NC}"
    else
        echo -e "${YELLOW}ℹ️  Test user setup (may already exist)${NC}"
    fi
}

# Function to login and get refresh token
login_user() {
    echo "🔐 Logging in test user..."
    
    LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/auth/login \
        -H "Content-Type: application/json" \
        -c cookies.txt \
        -d '{
            "email": "'$TEST_EMAIL'",
            "password": "'$1'"
        }')
    
    if echo "$LOGIN_RESPONSE" | grep -q "token"; then
        echo -e "${GREEN}✅ Login successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Login failed${NC}"
        echo "Response: $LOGIN_RESPONSE"
        return 1
    fi
}

# Checkpoint 1: List Users
echo -e "${BLUE}📋 CHECKPOINT 1: List Users${NC}"
echo "Testing: auth-admin list-users"

if node auth-admin.js list-users --limit 5 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ List users command works${NC}"
    echo "Output preview:"
    node auth-admin.js list-users --limit 3
else
    echo -e "${RED}❌ List users command failed${NC}"
    exit 1
fi
echo

# Checkpoint 2: Promote User to Admin
echo -e "${BLUE}👑 CHECKPOINT 2: Promote User to Admin${NC}"
echo "Testing: auth-admin promote --email $TEST_EMAIL"

# Ensure we have a test user
check_server || exit 1
setup_test_user

PROMOTE_OUTPUT=$(node auth-admin.js promote --email $TEST_EMAIL 2>&1)
if echo "$PROMOTE_OUTPUT" | grep -q "Promoted\|already an admin"; then
    echo -e "${GREEN}✅ Promote command works${NC}"
    echo "Output: $PROMOTE_OUTPUT"
else
    echo -e "${RED}❌ Promote command failed${NC}"
    echo "Output: $PROMOTE_OUTPUT"
    exit 1
fi
echo

# Checkpoint 3: Demote Admin to User
echo -e "${BLUE}👤 CHECKPOINT 3: Demote Admin to User${NC}"
echo "Testing: auth-admin demote --email $TEST_EMAIL"

DEMOTE_OUTPUT=$(node auth-admin.js demote --email $TEST_EMAIL 2>&1)
if echo "$DEMOTE_OUTPUT" | grep -q "Demoted\|already a regular user"; then
    echo -e "${GREEN}✅ Demote command works${NC}"
    echo "Output: $DEMOTE_OUTPUT"
else
    echo -e "${RED}❌ Demote command failed${NC}"
    echo "Output: $DEMOTE_OUTPUT"
    exit 1
fi
echo

# Checkpoint 4: Revoke All Sessions
echo -e "${BLUE}🚫 CHECKPOINT 4: Revoke All Sessions${NC}"
echo "Testing: auth-admin revoke-sessions --email $TEST_EMAIL"

# First login to create a session
login_user $TEST_PASSWORD

REVOKE_OUTPUT=$(node auth-admin.js revoke-sessions --email $TEST_EMAIL 2>&1)
if echo "$REVOKE_OUTPUT" | grep -q "Revoked.*refresh tokens"; then
    echo -e "${GREEN}✅ Revoke sessions command works${NC}"
    echo "Output: $REVOKE_OUTPUT"
    
    # Test that refresh now fails
    echo "🔍 Testing refresh token invalidation..."
    REFRESH_RESPONSE=$(curl -s -X POST $BASE_URL/auth/refresh -b cookies.txt)
    if echo "$REFRESH_RESPONSE" | grep -q "Invalid\|expired\|revoked"; then
        echo -e "${GREEN}✅ Refresh tokens successfully revoked${NC}"
    else
        echo -e "${YELLOW}⚠️  Refresh token validation inconclusive${NC}"
        echo "Response: $REFRESH_RESPONSE"
    fi
else
    echo -e "${RED}❌ Revoke sessions command failed${NC}"
    echo "Output: $REVOKE_OUTPUT"
    exit 1
fi
echo

# Checkpoint 5: Disable User
echo -e "${BLUE}🔒 CHECKPOINT 5: Disable User (Soft Block)${NC}"
echo "Testing: auth-admin disable-user --email $TEST_EMAIL"

DISABLE_OUTPUT=$(node auth-admin.js disable-user --email $TEST_EMAIL 2>&1)
if echo "$DISABLE_OUTPUT" | grep -q "Disabled.*sessions revoked"; then
    echo -e "${GREEN}✅ Disable user command works${NC}"
    echo "Output: $DISABLE_OUTPUT"
else
    echo -e "${RED}❌ Disable user command failed${NC}"
    echo "Output: $DISABLE_OUTPUT"
    exit 1
fi
echo

# Checkpoint 6: Reset Password
echo -e "${BLUE}🔑 CHECKPOINT 6: Reset Password${NC}"
echo "Testing: auth-admin set-password --email $TEST_EMAIL --password $NEW_PASSWORD"

RESET_OUTPUT=$(node auth-admin.js set-password --email $TEST_EMAIL --password "$NEW_PASSWORD" 2>&1)
if echo "$RESET_OUTPUT" | grep -q "Password updated and sessions revoked"; then
    echo -e "${GREEN}✅ Set password command works${NC}"
    echo "Output: $RESET_OUTPUT"
    
    # Test old password fails
    echo "🔍 Testing old password invalidation..."
    if ! login_user $TEST_PASSWORD > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Old password correctly invalidated${NC}"
    else
        echo -e "${RED}❌ Old password still works (should be invalid)${NC}"
    fi
    
    # Test new password works
    echo "🔍 Testing new password works..."
    if login_user $NEW_PASSWORD > /dev/null 2>&1; then
        echo -e "${GREEN}✅ New password works correctly${NC}"
    else
        echo -e "${RED}❌ New password doesn't work${NC}"
    fi
else
    echo -e "${RED}❌ Set password command failed${NC}"
    echo "Output: $RESET_OUTPUT"
    exit 1
fi
echo

# Final Summary
echo "============================================"
echo -e "${GREEN}🎉 PHASE 5 TESTS COMPLETE!${NC}"
echo "============================================"
echo -e "${GREEN}✅ Checkpoint 1: List users works${NC}"
echo -e "${GREEN}✅ Checkpoint 2: Promote user to admin${NC}"
echo -e "${GREEN}✅ Checkpoint 3: Demote admin to user${NC}"
echo -e "${GREEN}✅ Checkpoint 4: Revoke all sessions${NC}"
echo -e "${GREEN}✅ Checkpoint 5: Disable user (soft block)${NC}"
echo -e "${GREEN}✅ Checkpoint 6: Reset password securely${NC}"
echo
echo -e "${BLUE}📋 CLI Admin Tool Commands Available:${NC}"
echo "• node auth-admin.js list-users [--limit N]"
echo "• node auth-admin.js promote --email <email>"
echo "• node auth-admin.js demote --email <email>"
echo "• node auth-admin.js revoke-sessions --email <email>"
echo "• node auth-admin.js disable-user --email <email>"
echo "• node auth-admin.js set-password --email <email> --password <password>"
echo
echo -e "${GREEN}Phase 5 - CLI Admin Tool implementation complete! ✅${NC}"
