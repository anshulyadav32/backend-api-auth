# 🔐 Secure Auth System – Consolidated QA Test Plan
## Complete Phase 1 → Phase 6 Testing Matrix

### 📋 Test Plan Overview
- **Total Test Cases**: 42 core scenarios
- **Coverage**: Registration → OAuth → MFA → Admin → Extended Features
- **Format**: Ready for Excel/Sheets export
- **Execution**: Manual testing with curl/browser + CLI validation

---

## 📌 Phase 1 – Core Local Authentication

| **TC ID** | **Test Case** | **Method** | **Endpoint** | **Test Data** | **Steps** | **Expected Result** | **Validation** | **Priority** |
|-----------|---------------|------------|--------------|---------------|-----------|-------------------|----------------|--------------|
| TC-1.1 | Register new user | POST | `/api/auth/register` | `{email:"test@example.com", password:"SecurePass123!"}` | Send registration request | `201` + `{id, email, createdAt}` | Check user in DB | Critical |
| TC-1.2 | Register duplicate email | POST | `/api/auth/register` | Same email as TC-1.1 | Attempt duplicate registration | `409 Conflict` + error message | No duplicate in DB | High |
| TC-1.3 | Register weak password | POST | `/api/auth/register` | `{email:"test2@example.com", password:"123"}` | Send weak password | `400 Bad Request` + validation error | No user created | High |
| TC-1.4 | Login valid credentials | POST | `/api/auth/login` | `{email:"test@example.com", password:"SecurePass123!"}` | Send login request | `200` + `{accessToken}` + refresh cookie | Token valid, cookie set | Critical |
| TC-1.5 | Login invalid email | POST | `/api/auth/login` | `{email:"fake@example.com", password:"SecurePass123!"}` | Login with wrong email | `401 Unauthorized` + generic error | No token issued | High |
| TC-1.6 | Login invalid password | POST | `/api/auth/login` | `{email:"test@example.com", password:"WrongPass123!"}` | Login with wrong password | `401 Unauthorized` + generic error | No token issued | High |
| TC-1.7 | Access protected route | GET | `/api/auth/protected` | `Authorization: Bearer {token}` | Call with valid token | `200` + user data | User info returned | Critical |
| TC-1.8 | Access without token | GET | `/api/auth/protected` | No Authorization header | Call without token | `401 Unauthorized` | Access denied | Medium |
| TC-1.9 | Refresh token valid | POST | `/api/auth/refresh` | Valid refresh cookie | Send refresh request | `200` + new `accessToken` + rotated cookie | New token works, old cookie invalid | Critical |
| TC-1.10 | Refresh token reuse | POST | `/api/auth/refresh` | Previously used refresh cookie | Attempt token reuse | `401 Unauthorized` | Security violation detected | High |
| TC-1.11 | Logout session | POST | `/api/auth/logout` | Valid refresh cookie | Send logout request | `204 No Content` + cookie cleared | Cookie removed, token revoked | Critical |

---

## 📌 Phase 2 – Security Hardening

| **TC ID** | **Test Case** | **Method** | **Endpoint** | **Test Data** | **Steps** | **Expected Result** | **Validation** | **Priority** |
|-----------|---------------|------------|--------------|---------------|-----------|-------------------|----------------|--------------|
| TC-2.1 | Security headers present | GET | `/api/health` | N/A | Check response headers | Security headers present | X-Content-Type-Options, X-Frame-Options, CSP | Critical |
| TC-2.2 | Rate limiting normal | POST | `/api/auth/login` | Valid login data (5x) | Send 5 login attempts | All succeed normally | No rate limiting triggered | Medium |
| TC-2.3 | Rate limiting exceeded | POST | `/api/auth/login` | Wrong password (25x) | Send 25 rapid failed logins | First 20 → `401`, then `429 Too Many Requests` | Rate limit blocks excess | High |
| TC-2.4 | CSRF token generation | GET | `/api/auth/csrf-token` | N/A | Request CSRF token | `200` + `{csrfToken}` + cookie set | Token and cookie valid | High |
| TC-2.5 | CSRF protection active | POST | `/api/auth/login` | Login data without CSRF | Login without CSRF token | `403 Forbidden` + CSRF error | Request blocked | High |
| TC-2.6 | CSRF protection valid | POST | `/api/auth/login` | Login data + valid CSRF | Login with correct CSRF token | Login proceeds normally | CSRF validation passed | Critical |
| TC-2.7 | Input sanitization | POST | `/api/auth/register` | `{email:"<script>alert(1)</script>@test.com"}` | Send XSS payload | `400 Bad Request` or sanitized | No script execution | High |
| TC-2.8 | Error handling secure | GET | `/api/nonexistent` | N/A | Call invalid endpoint | `404` + generic error (no stack trace) | No sensitive info leaked | Medium |

---

## 📌 Phase 3 – Multi-Factor Authentication (MFA)

| **TC ID** | **Test Case** | **Method** | **Endpoint** | **Test Data** | **Steps** | **Expected Result** | **Validation** | **Priority** |
|-----------|---------------|------------|--------------|---------------|-----------|-------------------|----------------|--------------|
| TC-3.1 | MFA setup initiate | GET | `/api/auth/mfa/setup` | Valid access token | Request MFA setup | `200` + QR code data + backup codes | QR scannable, codes generated | Critical |
| TC-3.2 | MFA enable valid | POST | `/api/auth/mfa/enable` | `{totpCode:"123456"}` (from app) | Enable with valid TOTP | `200` + success message | MFA enabled in DB | Critical |
| TC-3.3 | MFA enable invalid | POST | `/api/auth/mfa/enable` | `{totpCode:"000000"}` | Enable with wrong TOTP | `400 Bad Request` + invalid code error | MFA not enabled | High |
| TC-3.4 | Login MFA required | POST | `/api/auth/login` | Valid email/password (MFA user) | Login MFA-enabled user | `200` + `{mfaRequired:true}` + temp session | No full tokens yet | Critical |
| TC-3.5 | MFA verify valid | POST | `/api/auth/mfa/verify` | `{totpCode:"654321"}` (valid) | Complete MFA verification | `200` + full tokens issued | Access granted | Critical |
| TC-3.6 | MFA verify invalid | POST | `/api/auth/mfa/verify` | `{totpCode:"000000"}` | Wrong MFA code | `400 Bad Request` + invalid code | Access denied | High |
| TC-3.7 | MFA backup code | POST | `/api/auth/mfa/verify` | `{backupCode:"ABC12345"}` | Use backup code | `200` + tokens + code consumed | Backup code marked used | High |
| TC-3.8 | MFA disable | POST | `/api/auth/mfa/disable` | Valid access token | Disable user MFA | `200` + MFA disabled | Normal login restored | Medium |

---

## 📌 Phase 4 – OAuth Integration (Google/GitHub)

| **TC ID** | **Test Case** | **Method** | **Endpoint** | **Test Data** | **Steps** | **Expected Result** | **Validation** | **Priority** |
|-----------|---------------|------------|--------------|---------------|-----------|-------------------|----------------|--------------|
| TC-4.1 | Google OAuth start | GET | `/auth/google` | N/A | Click Google login | Redirect to Google OAuth | URL contains client_id, scope | Critical |
| TC-4.2 | Google OAuth callback new | GET | `/auth/google/callback` | Valid authorization code | Complete Google auth (new user) | Redirect + tokens + user created | New user in DB with OAuth link | Critical |
| TC-4.3 | Google OAuth callback existing | GET | `/auth/google/callback` | Code for existing OAuth user | Login existing Google user | Redirect + fresh tokens | User authenticated, no duplicate | High |
| TC-4.4 | Google account linking | GET | `/auth/google/callback` | Google email = existing email user | OAuth with existing email match | Accounts linked successfully | OAuth account tied to existing user | High |
| TC-4.5 | GitHub OAuth start | GET | `/auth/github` | N/A | Click GitHub login | Redirect to GitHub OAuth | URL contains client_id, scope | Critical |
| TC-4.6 | GitHub OAuth callback new | GET | `/auth/github/callback` | Valid authorization code | Complete GitHub auth (new user) | Redirect + tokens + user created | New user in DB with OAuth link | Critical |
| TC-4.7 | GitHub OAuth callback existing | GET | `/auth/github/callback` | Code for existing OAuth user | Login existing GitHub user | Redirect + fresh tokens | User authenticated | High |
| TC-4.8 | OAuth error handling | GET | `/auth/google/callback` | `?error=access_denied` | User denies OAuth | Error page + no authentication | No user created, graceful handling | Medium |
| TC-4.9 | OAuth refresh token | POST | `/api/auth/refresh` | Refresh cookie from OAuth login | Refresh OAuth session | New access token + rotated cookie | OAuth session maintained | High |

---

## 📌 Phase 5 – CLI Administration Tools

| **TC ID** | **Test Case** | **Tool** | **Command** | **Test Data** | **Steps** | **Expected Result** | **Validation** | **Priority** |
|-----------|---------------|----------|-------------|---------------|-----------|-------------------|----------------|--------------|
| TC-5.1 | CLI tool help | CLI | `node auth-admin-cli.js --help` | N/A | Run help command | Help menu displayed | Commands and options shown | Medium |
| TC-5.2 | List all users | CLI | `node auth-admin-cli.js list-users` | Users in DB | Execute list command | Table of users displayed | All users shown with details | High |
| TC-5.3 | List admin users | CLI | `node auth-admin-cli.js list-users --admin-only` | Admin users exist | List with filter | Only admin users shown | Filter working correctly | Medium |
| TC-5.4 | Promote user | CLI | `node auth-admin-cli.js promote test@example.com` | Existing non-admin user | Promote to admin | Success message + DB updated | User role = admin in DB | Critical |
| TC-5.5 | Promote nonexistent | CLI | `node auth-admin-cli.js promote fake@example.com` | Non-existent email | Attempt promotion | Error: user not found | No DB changes | Medium |
| TC-5.6 | Demote admin user | CLI | `node auth-admin-cli.js demote admin@example.com` | Existing admin user | Demote from admin | Success message + DB updated | User role = user in DB | Critical |
| TC-5.7 | Revoke user sessions | CLI | `node auth-admin-cli.js revoke-sessions test@example.com` | User with active sessions | Revoke all sessions | Success + tokens invalidated | Refresh tokens deleted from DB | Critical |
| TC-5.8 | CLI database connection | CLI | Any command | Database available | Execute any CLI command | Command completes successfully | No connection errors | High |

---

## 📌 Phase 6 – Extended Features

| **TC ID** | **Test Case** | **Method** | **Endpoint** | **Test Data** | **Steps** | **Expected Result** | **Validation** | **Priority** |
|-----------|---------------|------------|--------------|---------------|-----------|-------------------|----------------|--------------|
| TC-6.1 | Password reset request | POST | `/api/auth/password-reset/request` | `{email:"test@example.com"}` | Request password reset | `200` + generic success message | Reset token created in DB | Critical |
| TC-6.2 | Password reset nonexistent | POST | `/api/auth/password-reset/request` | `{email:"fake@example.com"}` | Reset for invalid email | `200` + same generic message | No token created (security) | High |
| TC-6.3 | Reset token validation | GET | `/api/auth/password-reset/validate/{token}` | Valid reset token | Validate reset token | `200` + token valid message | Token exists and not expired | High |
| TC-6.4 | Reset invalid token | GET | `/api/auth/password-reset/validate/{invalid}` | Invalid token | Validate bad token | `400 Bad Request` + invalid token | Token validation failed | Medium |
| TC-6.5 | Complete password reset | POST | `/api/auth/password-reset/complete` | `{token:"valid", password:"NewPass123!"}` | Reset with valid token | `200` + password updated | Old password fails, new works | Critical |
| TC-6.6 | Reset expired token | POST | `/api/auth/password-reset/complete` | Expired token + new password | Use expired token | `400 Bad Request` + token expired | Password not changed | High |
| TC-6.7 | Email verification send | POST | `/api/auth/email/resend-verification` | `{email:"unverified@example.com"}` | Resend verification | `200` + email sent message | Verification token created | High |
| TC-6.8 | Email verify valid | GET | `/api/auth/email/verify/{token}` | Valid verification token | Verify email address | `200` + email verified | User verified status = true | Critical |
| TC-6.9 | Email verify invalid | GET | `/api/auth/email/verify/{invalid}` | Invalid token | Verify with bad token | `400 Bad Request` + invalid token | User remains unverified | Medium |
| TC-6.10 | Login unverified user | POST | `/api/auth/login` | Unverified user credentials | Login unverified user | `401 Unauthorized` + verification required | Access blocked until verified | High |
| TC-6.11 | Audit log login | POST | `/api/auth/login` | Valid credentials | Successful login | Normal login + audit entry | Log: user_id, action=login, ip, timestamp | Medium |
| TC-6.12 | Audit log failed login | POST | `/api/auth/login` | Wrong password | Failed login attempt | `401` + audit entry | Log: email, action=failed_login, ip | Medium |

---

## 📊 **QA Execution Checklist**

### **Pre-Test Setup**
```bash
# 1. Start the server
npm start

# 2. Reset database
npm run db:reset

# 3. Verify environment
curl http://localhost:3000/api/health
```

### **Test Data Setup**
```bash
# Create test users
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!"}'

curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"AdminPass123!"}'

# Promote admin user
node auth-admin-cli.js promote admin@example.com
```

### **Validation Queries**
```sql
-- Check user creation
SELECT id, email, created_at, is_verified, role FROM users;

-- Check refresh tokens
SELECT user_id, token_hash, expires_at FROM refresh_tokens;

-- Check OAuth accounts
SELECT user_id, provider, provider_id FROM oauth_accounts;

-- Check audit logs
SELECT user_id, action, ip_address, created_at FROM audit_logs;
```

---

## 🎯 **Test Execution Priority**

### **P1 - Critical (Must Pass)**
- All TC-1.x (Core Auth)
- TC-3.1, TC-3.4, TC-3.5 (MFA Core)
- TC-4.1, TC-4.2, TC-4.5, TC-4.6 (OAuth Core)
- TC-5.4, TC-5.6, TC-5.7 (Admin Core)
- TC-6.1, TC-6.5, TC-6.8 (Extended Core)

### **P2 - High (Should Pass)**
- Security and error handling tests
- Edge cases and validation

### **P3 - Medium/Low (Nice to Have)**
- Advanced filtering and audit features

---

## 📋 **Excel Export Template**

| **TC ID** | **Phase** | **Test Case** | **Status** | **Notes** | **Tester** | **Date** | **Build** |
|-----------|-----------|---------------|------------|-----------|------------|----------|-----------|
| TC-1.1 | Phase 1 | Register new user | ☐ Pass ☐ Fail | | | | |
| TC-1.2 | Phase 1 | Register duplicate email | ☐ Pass ☐ Fail | | | | |
| ... | ... | ... | ... | ... | ... | ... | ... |

---

✅ **This consolidated test plan gives you:**
- **42 comprehensive test cases** covering all phases
- **Ready-to-copy format** for Excel/Google Sheets
- **SQL validation queries** for backend verification  
- **Priority matrix** for test execution planning
- **Setup instructions** for QA environment

🚀 **Would you like me to generate the actual Excel file (.xlsx) with this test matrix so you can use it directly in your QA process?**
