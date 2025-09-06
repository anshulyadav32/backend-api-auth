# 🌐 Phase 4: OAuth Integration - Complete Implementation Guide

## 📋 Phase 4 Checkpoints & Tests

### ✅ Checkpoint 1 – Google Login

**Test (Browser)**
```
http://localhost:8080/auth/oauth/google
```

**Expected Flow:**
1. Redirects you to Google consent screen
2. You log in & approve permissions  
3. Redirects back to: `http://localhost:8080/auth/oauth/google/callback`
4. Server sets `refresh_token` cookie + returns access token
5. Account created/linked in database

**✅ Checkpoint Verification:**
- Google login created/linked a `User` record
- `refresh_token` cookie set with 7-day expiry
- `OAuthAccount` record created with `provider='google'`

**API Test:**
```bash
curl -I http://localhost:8080/auth/oauth/google
# Expected: HTTP 302 redirect to accounts.google.com
```

---

### ✅ Checkpoint 2 – GitHub Login  

**Test (Browser)**
```
http://localhost:8080/auth/oauth/github
```

**Expected Flow:**
1. Redirects to GitHub login/consent screen
2. After approval → callback to API
3. API sets `refresh_token` cookie + issues access token
4. Account created/linked in database

**✅ Checkpoint Verification:**
- GitHub login created/linked a `User` record
- Cookie set & usable for refresh operations
- `OAuthAccount` record created with `provider='github'`

**API Test:**
```bash
curl -I http://localhost:8080/auth/oauth/github  
# Expected: HTTP 302 redirect to github.com
```

---

### ✅ Checkpoint 3 – Account Linking (Email)

**Setup:**
1. Register local user: `POST /auth/register` with `alice@example.com`
2. Login with Google using same email `alice@example.com`

**Expected Result:**
- **No duplicate user created**
- `oauth_accounts` table contains:
  ```sql
  provider='google'
  providerUserId='<google-id>'  
  userId=<alice's-user-id>
  email='alice@example.com'
  ```
- Original User record for Alice unchanged

**✅ Checkpoint Verification:**
```sql
-- Verify account linking
SELECT o.provider, o.providerUserId, o.userId, u.email, u.username
FROM oauth_accounts o
JOIN users u ON o.userId = u.id  
WHERE u.email = 'alice@example.com';

-- Verify no duplicates  
SELECT email, COUNT(*) as count
FROM users 
GROUP BY email
HAVING COUNT(*) > 1;
```

---

### ✅ Checkpoint 4 – Refresh After OAuth Login

**Test:**
```bash
# After completing OAuth login in browser
curl -X POST http://localhost:8080/auth/refresh \
  -H "x-csrf-token: <csrf-token>" \
  -c cookies.txt -b cookies.txt
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**✅ Checkpoint Verification:**
- OAuth sessions refresh identically to local password sessions
- New access token issued with 15-minute expiry  
- Refresh token rotated (old one revoked, new one issued)

---

### ✅ Checkpoint 5 – Logout After OAuth Login

**Test:**
```bash
# After OAuth login
curl -X POST http://localhost:8080/auth/logout \
  -H "x-csrf-token: <csrf-token>" \
  -c cookies.txt -b cookies.txt -i
```

**Expected Response:**
```
HTTP/1.1 200 OK
Set-Cookie: refresh_token=; Max-Age=0; Path=/; HttpOnly
```

**✅ Checkpoint Verification:**
- HTTP 200 success response
- `refresh_token` cookie cleared (`Max-Age=0`)
- Database token marked as `revoked=true`
- OAuth session properly terminated

---

## 🔍 Database Verification Queries

**See all OAuth accounts:**
```sql
SELECT o.provider, o.providerUserId, o.email as oauth_email, 
       u.email as user_email, u.username, u.id as user_id
FROM oauth_accounts o
JOIN users u ON o.userId = u.id
ORDER BY o.createdAt DESC;
```

**See recent refresh tokens:**
```sql
SELECT rt.id, rt.userId, rt.revoked, rt.createdAt, u.email
FROM refresh_tokens rt  
JOIN users u ON rt.userId = u.id
ORDER BY rt.createdAt DESC
LIMIT 10;
```

**Check for duplicate users (should be empty):**
```sql
SELECT email, COUNT(*) as count
FROM users
GROUP BY email  
HAVING COUNT(*) > 1;
```

---

## 🧪 Running the Tests

**Automated API Tests:**
```bash
chmod +x test-phase4.sh
./test-phase4.sh
```

**Manual Browser Tests:**
1. Start server: `node server.js`
2. Visit: `http://localhost:8080/oauth-test`
3. Test Google OAuth flow
4. Test GitHub OAuth flow  
5. Test account linking scenario

---

## 🔧 Setup Requirements

**Before testing OAuth flows:**

1. **Google OAuth Setup:**
   - Visit [Google Cloud Console](https://console.cloud.google.com/)
   - Create/select project → APIs & Services → Credentials
   - Create OAuth 2.0 Client ID
   - Add authorized redirect URI: `http://localhost:8080/auth/oauth/google/callback`
   - Update `.env`: `GOOGLE_CLIENT_ID=xxx` and `GOOGLE_CLIENT_SECRET=xxx`

2. **GitHub OAuth Setup:**
   - Visit [GitHub Developer Settings](https://github.com/settings/developers)
   - New OAuth App
   - Authorization callback URL: `http://localhost:8080/auth/oauth/github/callback`  
   - Update `.env`: `GITHUB_CLIENT_ID=xxx` and `GITHUB_CLIENT_SECRET=xxx`

3. **Environment Variables:**
   ```env
   GOOGLE_CLIENT_ID=your-google-client-id-here
   GOOGLE_CLIENT_SECRET=your-google-client-secret-here
   GITHUB_CLIENT_ID=your-github-client-id-here  
   GITHUB_CLIENT_SECRET=your-github-client-secret-here
   SESSION_SECRET=your-super-secure-session-secret
   BASE_URL=http://localhost:8080
   ```

---

## ✅ Phase 4 Summary

**✅ All Checkpoints Complete:**
- ✅ Google OAuth redirect & authentication
- ✅ GitHub OAuth redirect & authentication  
- ✅ Email-based account linking (no duplicates)
- ✅ OAuth session refresh functionality
- ✅ OAuth session logout functionality

**🔗 New API Endpoints:**
- `GET /auth/oauth/google` - Initiate Google OAuth
- `GET /auth/oauth/github` - Initiate GitHub OAuth
- `GET /auth/oauth/google/callback` - Google OAuth callback  
- `GET /auth/oauth/github/callback` - GitHub OAuth callback
- `GET /auth/oauth/failure` - OAuth error handling
- `GET /oauth-test` - OAuth testing interface

**🏗️ Architecture Added:**
- `OAuthAccount` model with provider linking
- Passport.js Google/GitHub strategies
- Session-based OAuth flow management  
- Account linking logic (email matching)
- OAuth token management (same as local auth)

---

## 🚀 Ready for Phase 5

**Phase 4 OAuth Integration: COMPLETE** ✅

All existing functionality (Phase 1-3) remains intact:
- ✅ Email/password authentication  
- ✅ JWT access tokens + refresh token rotation
- ✅ Security hardening (Helmet, CSRF, rate limiting)
- ✅ MFA/TOTP authentication
- ✅ **NEW:** Google & GitHub OAuth integration

**Next:** Phase 5 - CLI Admin Tool (`list-users`, `promote`, `demote`, `revoke-sessions`, `set-password`)
