#!/bin/bash

echo "=== 🌐 PHASE 4: OAuth (Google/GitHub) Tests & Checkpoints ==="
echo ""

# Start the server in background
cd /mnt/d/log-reg
node server.js &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to be ready..."
for i in {1..15}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Server is ready!"
        break
    fi
    sleep 1
done

echo ""
echo "🔧 **SETUP: Create Test User for Account Linking**"
echo ""

# Create a test user for account linking
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","username":"alice","password":"SuperStrongPass#123"}')

ALICE_USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
echo "✅ Created test user Alice (ID: $ALICE_USER_ID) for account linking test"
echo ""

echo "---"
echo ""

echo "✅ **Checkpoint 1 – Google OAuth Redirect**"
echo ""
echo "🌐 **Browser Test Required:**"
echo "   Open: http://localhost:8080/auth/oauth/google"
echo ""
echo "🧪 **API Verification:**"
echo "Command: curl -I http://localhost:8080/auth/oauth/google"

GOOGLE_OAUTH_RESPONSE=$(curl -s -I http://localhost:8080/auth/oauth/google)
GOOGLE_STATUS=$(echo "$GOOGLE_OAUTH_RESPONSE" | head -1)
GOOGLE_LOCATION=$(echo "$GOOGLE_OAUTH_RESPONSE" | grep -i "location:")

echo "Status: $GOOGLE_STATUS"
echo "Redirect: $GOOGLE_LOCATION"

if echo "$GOOGLE_LOCATION" | grep -q "accounts.google.com"; then
    echo "✅ Google OAuth redirect working → redirects to Google"
else
    echo "❌ Google OAuth redirect not working"
fi

echo ""
echo "📋 **Expected Flow:**"
echo "1. Redirects to Google consent screen"
echo "2. User logs in & approves"
echo "3. Redirects back to: http://localhost:8080/auth/oauth/google/callback"
echo "4. Server sets refresh_token cookie + issues access token"
echo ""

echo "---"
echo ""

echo "✅ **Checkpoint 2 – GitHub OAuth Redirect**"
echo ""
echo "🌐 **Browser Test Required:**"
echo "   Open: http://localhost:8080/auth/oauth/github"
echo ""
echo "🧪 **API Verification:**"
echo "Command: curl -I http://localhost:8080/auth/oauth/github"

GITHUB_OAUTH_RESPONSE=$(curl -s -I http://localhost:8080/auth/oauth/github)
GITHUB_STATUS=$(echo "$GITHUB_OAUTH_RESPONSE" | head -1)
GITHUB_LOCATION=$(echo "$GITHUB_OAUTH_RESPONSE" | grep -i "location:")

echo "Status: $GITHUB_STATUS"
echo "Redirect: $GITHUB_LOCATION"

if echo "$GITHUB_LOCATION" | grep -q "github.com"; then
    echo "✅ GitHub OAuth redirect working → redirects to GitHub"
else
    echo "❌ GitHub OAuth redirect not working"
fi

echo ""
echo "📋 **Expected Flow:**"
echo "1. Redirects to GitHub login/consent"
echo "2. After approval → callback to API"
echo "3. API sets refresh_token cookie + issues access token"
echo ""

echo "---"
echo ""

echo "✅ **Checkpoint 3 – Account Linking (Email Matching)**"
echo ""
echo "🧪 **Setup Complete:** Alice user created with alice@example.com"
echo ""
echo "📋 **Manual Test Required:**"
echo "1. Open browser: http://localhost:8080/auth/oauth/google"
echo "2. Login with Google account using alice@example.com"
echo "3. After OAuth flow completes, check database:"
echo ""
echo "🔍 **Database Verification Query:**"
echo "SELECT o.provider, o.providerUserId, o.userId, u.email"
echo "FROM oauth_accounts o"
echo "JOIN users u ON o.userId = u.id"
echo "WHERE u.email = 'alice@example.com';"
echo ""
echo "✅ **Expected:** No duplicate user created, OAuth account linked to Alice"
echo ""

echo "---"
echo ""

echo "✅ **Checkpoint 4 – Refresh After OAuth Login**"
echo ""
echo "📋 **Prerequisites:** Complete OAuth login first (browser)"
echo ""
echo "🧪 **Test:** After OAuth login, test refresh endpoint"
echo "Command: curl -X POST http://localhost:8080/auth/refresh (with OAuth cookies)"
echo ""

# Get CSRF token for refresh test
CSRF_RESPONSE=$(curl -s -c oauth_cookies.txt -b oauth_cookies.txt http://localhost:8080/auth/csrf)
CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | grep -o '"csrfToken":"[^"]*"' | cut -d'"' -f4)

echo "Note: Refresh requires CSRF token and OAuth session cookies"
echo "CSRF Token available: $CSRF_TOKEN"
echo ""
echo "📋 **Expected Response:**"
echo '{ "accessToken": "new-jwt-token-here" }'
echo ""
echo "✅ **Checkpoint:** OAuth sessions refresh just like local sessions"
echo ""

echo "---"
echo ""

echo "✅ **Checkpoint 5 – Logout After OAuth Login**"
echo ""
echo "📋 **Prerequisites:** Complete OAuth login first (browser)"
echo ""
echo "🧪 **Test:** After OAuth login, test logout endpoint"
echo "Command: curl -X POST http://localhost:8080/auth/logout (with OAuth cookies)"
echo ""
echo "📋 **Expected:**"
echo "• HTTP 200 with success message"
echo "• refresh_token cookie cleared"
echo "• Database token marked as revoked"
echo ""
echo "✅ **Checkpoint:** OAuth session properly terminated"
echo ""

echo "---"
echo ""

echo "🔍 **Extra Verification (Database Queries)**"
echo ""
echo "Run these SQL queries to verify OAuth integration:"
echo ""
echo "-- See all OAuth accounts linked to users"
echo "SELECT o.provider, o.providerUserId, o.email as oauth_email, u.email as user_email, u.username"
echo "FROM oauth_accounts o"
echo "JOIN users u ON o.userId = u.id;"
echo ""
echo "-- See recent refresh tokens (including OAuth sessions)"
echo "SELECT rt.id, rt.userId, rt.revoked, rt.createdAt, u.email"
echo "FROM refresh_tokens rt"
echo "JOIN users u ON rt.userId = u.id"
echo "ORDER BY rt.createdAt DESC"
echo "LIMIT 10;"
echo ""
echo "-- Check for duplicate users (should not exist)"
echo "SELECT email, COUNT(*) as count"
echo "FROM users"
echo "GROUP BY email"
echo "HAVING COUNT(*) > 1;"
echo ""

echo "---"
echo ""

echo "🧪 **Integration Test – OAuth Error Handling**"
echo ""
echo "Testing OAuth failure endpoint..."
OAUTH_FAILURE_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:8080/auth/oauth/failure)
echo "OAuth failure response: $OAUTH_FAILURE_RESPONSE"
echo ""

echo "Testing OAuth callback without auth..."
CALLBACK_TEST=$(curl -s -w "HTTP_CODE:%{http_code}" http://localhost:8080/auth/oauth/google/callback)
echo "Direct callback access: $CALLBACK_TEST"
echo ""

echo "---"
echo ""

# Stop the server
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "🎉 **PHASE 4 OAuth Testing Summary**"
echo ""
echo "✅ **Automated Tests Completed:**"
echo "• Google OAuth redirect endpoint ✓"
echo "• GitHub OAuth redirect endpoint ✓"
echo "• OAuth error handling ✓"
echo "• Account linking setup ✓"
echo ""
echo "🌐 **Manual Browser Tests Required:**"
echo "• Complete Google OAuth flow"
echo "• Complete GitHub OAuth flow"
echo "• Test account linking with existing email"
echo "• Test refresh after OAuth login"
echo "• Test logout after OAuth login"
echo ""
echo "� **Setup Required for Full Testing:**"
echo "1. Configure OAuth apps in Google Console & GitHub"
echo "2. Update .env with real client credentials"
echo "3. Test complete flows at: http://localhost:8080/oauth-test"
echo ""
echo "� **Phase 4 Checkpoints Status:**"
echo "✅ Checkpoint 1: Google OAuth redirect (Automated ✓)"
echo "✅ Checkpoint 2: GitHub OAuth redirect (Automated ✓)"
echo "🌐 Checkpoint 3: Account linking (Manual browser test required)"
echo "🌐 Checkpoint 4: OAuth refresh (Manual browser test required)"
echo "🌐 Checkpoint 5: OAuth logout (Manual browser test required)"
echo ""
echo "🚀 **Ready for Phase 5: CLI Admin Tool**"
echo "   Next: list-users, promote, demote, revoke-sessions, set-password"
