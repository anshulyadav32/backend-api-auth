# Master Test Plan - Authentication System
## Complete QA/Development Handoff Documentation

### Document Information
- **Project**: Comprehensive Authentication System
- **Version**: 1.0
- **Date**: September 7, 2025
- **Phases Covered**: 1-6 (Basic Auth → Extended Features)
- **Test Environment**: Node.js v18.19.1, Express.js, PostgreSQL/SQLite

---

## Executive Summary

This master test plan covers a complete enterprise-grade authentication system implemented in 6 phases:
- **Phase 1**: Basic email/password authentication with JWT tokens
- **Phase 2**: Security hardening with comprehensive protection measures
- **Phase 3**: Multi-factor authentication (MFA/TOTP) implementation
- **Phase 4**: OAuth integration with Google and GitHub
- **Phase 5**: CLI administration tools for user management
- **Phase 6**: Extended features (password reset, email verification, audit logging)

**Total Test Cases**: 165 across all phases
**Critical Path**: Basic Auth → Security → MFA → OAuth → Admin Tools → Extended Features

---

## PHASE 1: BASIC AUTHENTICATION
### Test Environment Setup
- Database: PostgreSQL or SQLite fallback
- Server: Express.js running on Node.js v18.19.1
- Tools: Postman/cURL for API testing
- Testing libraries: Jest, Supertest

### Test Cases

#### User Registration
1. **TC1.1**: Register with valid email/password/name
   - **Input**: Valid email, password, name
   - **Expected**: User created in database, 201 status
   - **Assertions**: Response contains user ID, success message

2. **TC1.2**: Register with invalid email format
   - **Input**: Invalid email, valid password, name
   - **Expected**: 400 status, validation error
   - **Assertions**: Response contains specific error about email format

3. **TC1.3**: Register with weak password
   - **Input**: Valid email, weak password, valid name
   - **Expected**: 400 status, validation error
   - **Assertions**: Response contains specific error about password strength

4. **TC1.4**: Register with duplicate email
   - **Input**: Already registered email
   - **Expected**: 409 status, conflict error
   - **Assertions**: Response contains specific error about email already in use

5. **TC1.5**: Register with missing required fields
   - **Input**: Missing email/password/name
   - **Expected**: 400 status, validation error
   - **Assertions**: Response lists all missing fields

#### User Login
6. **TC1.6**: Login with valid credentials
   - **Input**: Valid email/password
   - **Expected**: 200 status, authentication successful
   - **Assertions**: Response contains JWT token, refresh token

7. **TC1.7**: Login with invalid email
   - **Input**: Non-existent email, any password
   - **Expected**: 401 status, authentication failed
   - **Assertions**: Generic error message (no info disclosure)

8. **TC1.8**: Login with invalid password
   - **Input**: Valid email, wrong password
   - **Expected**: 401 status, authentication failed
   - **Assertions**: Generic error message (no info disclosure)

9. **TC1.9**: Login with case-insensitive email
   - **Input**: Email with different case than registered
   - **Expected**: 200 status, authentication successful
   - **Assertions**: Response contains JWT token, refresh token

#### Token Management
10. **TC1.10**: Validate valid JWT token
    - **Input**: Valid JWT token in Authorization header
    - **Expected**: 200 status, token valid
    - **Assertions**: Response contains user information

11. **TC1.11**: Validate expired JWT token
    - **Input**: Expired JWT token in Authorization header
    - **Expected**: 401 status, token expired
    - **Assertions**: Error indicates token expiration

12. **TC1.12**: Validate malformed JWT token
    - **Input**: Malformed JWT token in Authorization header
    - **Expected**: 401 status, token invalid
    - **Assertions**: Error indicates invalid token

13. **TC1.13**: Refresh token with valid refresh token
    - **Input**: Valid refresh token
    - **Expected**: 200 status, new tokens issued
    - **Assertions**: Response contains new JWT token, refresh token

14. **TC1.14**: Refresh token with invalid refresh token
    - **Input**: Invalid/expired refresh token
    - **Expected**: 401 status, token invalid
    - **Assertions**: Error indicates invalid refresh token

#### User Profile
15. **TC1.15**: Get user profile with valid token
    - **Input**: Valid JWT token in Authorization header
    - **Expected**: 200 status, profile retrieved
    - **Assertions**: Response contains user profile data

16. **TC1.16**: Update user profile with valid token
    - **Input**: Valid JWT token, updated profile fields
    - **Expected**: 200 status, profile updated
    - **Assertions**: Response contains updated profile data

17. **TC1.17**: Access user profile with invalid token
    - **Input**: Invalid JWT token in Authorization header
    - **Expected**: 401 status, unauthorized
    - **Assertions**: Error indicates authentication required

## PHASE 2: SECURITY HARDENING
### Test Environment Setup
- Same as Phase 1
- Additional tools: OWASP ZAP for security testing
- Additional libraries: helmet, rate-limiter-flexible

### Test Cases

#### Input Validation & Sanitization
18. **TC2.1**: Register with malicious script in name field
    - **Input**: Name with XSS payload (`<script>alert('XSS')</script>`)
    - **Expected**: 400 status or sanitized input
    - **Assertions**: No XSS vulnerability present in responses

19. **TC2.2**: Login with SQL injection attempt
    - **Input**: Email field with SQL injection payload
    - **Expected**: 401 status, login fails
    - **Assertions**: No SQL error exposed, authentication fails securely

20. **TC2.3**: Update profile with oversized payload
    - **Input**: Very large JSON payload (10MB+)
    - **Expected**: 413 status, payload too large
    - **Assertions**: Error indicates payload size limit

#### CSRF Protection
21. **TC2.4**: Get CSRF token
    - **Input**: Valid JWT token in Authorization header
    - **Expected**: 200 status, CSRF token provided
    - **Assertions**: Response contains CSRF token

22. **TC2.5**: Submit request with valid CSRF token
    - **Input**: Valid JWT token, valid CSRF token
    - **Expected**: 200 status, request accepted
    - **Assertions**: Operation completed successfully

23. **TC2.6**: Submit request with invalid CSRF token
    - **Input**: Valid JWT token, invalid CSRF token
    - **Expected**: 403 status, CSRF validation failed
    - **Assertions**: Error indicates CSRF token mismatch

24. **TC2.7**: Submit request with missing CSRF token
    - **Input**: Valid JWT token, no CSRF token
    - **Expected**: 403 status, CSRF validation failed
    - **Assertions**: Error indicates missing CSRF token

#### Rate Limiting
25. **TC2.8**: Login attempt rate limiting
    - **Input**: Repeated login attempts from same IP
    - **Expected**: 429 status after threshold exceeded
    - **Assertions**: Error indicates too many requests, retry after header

26. **TC2.9**: API rate limiting
    - **Input**: Repeated API calls from same IP/user
    - **Expected**: 429 status after threshold exceeded
    - **Assertions**: Error indicates too many requests, retry after header

#### Security Headers
27. **TC2.10**: Verify security headers on all responses
    - **Expected**: All security headers properly set
    - **Assertions**: Content-Security-Policy, X-XSS-Protection, etc.

28. **TC2.11**: Verify CORS configuration
    - **Input**: Cross-origin requests
    - **Expected**: Appropriate CORS headers for allowed origins
    - **Assertions**: Access-Control-Allow-Origin matches configuration

#### Password Security
29. **TC2.12**: Password hashing verification
    - **Expected**: Passwords stored securely
    - **Assertions**: Database uses bcrypt/Argon2 hashing

30. **TC2.13**: Password complexity requirements
    - **Input**: Various password strengths
    - **Expected**: Reject passwords that don't meet requirements
    - **Assertions**: Error details specific requirements

## PHASE 3: MULTI-FACTOR AUTHENTICATION
### Test Environment Setup
- Same as Phase 2
- Additional libraries: speakeasy or node-2fa for TOTP

### Test Cases

#### MFA Setup
31. **TC3.1**: Generate MFA secret
    - **Input**: Valid JWT token
    - **Expected**: 200 status, MFA secret and QR code URL
    - **Assertions**: Response contains valid TOTP secret

32. **TC3.2**: Verify MFA setup with valid token
    - **Input**: Valid TOTP token from authenticator app
    - **Expected**: 200 status, MFA enabled for account
    - **Assertions**: User record updated with MFA enabled flag

33. **TC3.3**: Verify MFA setup with invalid token
    - **Input**: Invalid TOTP token
    - **Expected**: 400 status, verification failed
    - **Assertions**: MFA not enabled, error message provided

#### MFA Login Flow
34. **TC3.4**: Login with MFA enabled (first step)
    - **Input**: Valid email/password for MFA-enabled account
    - **Expected**: 200 status, partial auth, MFA required
    - **Assertions**: Response indicates MFA required, temporary token

35. **TC3.5**: Complete login with valid MFA token
    - **Input**: Valid TOTP token, temporary auth token
    - **Expected**: 200 status, full authentication
    - **Assertions**: Response contains JWT token, refresh token

36. **TC3.6**: Attempt login with invalid MFA token
    - **Input**: Invalid TOTP token, temporary auth token
    - **Expected**: 401 status, MFA validation failed
    - **Assertions**: Error indicates invalid MFA token

#### MFA Recovery Options
37. **TC3.7**: Generate recovery codes
    - **Input**: Valid JWT token
    - **Expected**: 200 status, recovery codes generated
    - **Assertions**: Response contains list of recovery codes

38. **TC3.8**: Use recovery code for login
    - **Input**: Valid recovery code, temporary auth token
    - **Expected**: 200 status, full authentication
    - **Assertions**: Response contains JWT token, recovery code marked as used

39. **TC3.9**: Use already-used recovery code
    - **Input**: Previously used recovery code
    - **Expected**: 401 status, invalid recovery code
    - **Assertions**: Error indicates invalid or used recovery code

#### MFA Management
40. **TC3.10**: Disable MFA
    - **Input**: Valid JWT token, current password
    - **Expected**: 200 status, MFA disabled
    - **Assertions**: User record updated, MFA flag disabled

41. **TC3.11**: Reset MFA
    - **Input**: Valid JWT token, current password
    - **Expected**: 200 status, new MFA secret
    - **Assertions**: User MFA data reset, new secret provided

## PHASE 4: OAUTH INTEGRATION
### Test Environment Setup
- Same as Phase 3
- OAuth provider accounts (Google, GitHub)
- OAuth provider developer accounts and API credentials

### Test Cases

#### OAuth Provider Configuration
42. **TC4.1**: Get available OAuth providers
    - **Input**: None
    - **Expected**: 200 status, list of configured providers
    - **Assertions**: Response includes Google, GitHub in providers list

43. **TC4.2**: OAuth authorization URL generation
    - **Input**: Provider name (Google/GitHub)
    - **Expected**: 200 status, authorization URL
    - **Assertions**: URL contains correct client ID, scopes, redirect URI

#### OAuth Authentication Flow
44. **TC4.3**: Google OAuth callback with valid code
    - **Input**: Valid authorization code from Google
    - **Expected**: 200 status, authentication successful
    - **Assertions**: Response contains JWT token, user account created/linked

45. **TC4.4**: GitHub OAuth callback with valid code
    - **Input**: Valid authorization code from GitHub
    - **Expected**: 200 status, authentication successful
    - **Assertions**: Response contains JWT token, user account created/linked

46. **TC4.5**: OAuth callback with invalid code
    - **Input**: Invalid authorization code
    - **Expected**: 401 status, authentication failed
    - **Assertions**: Error indicates invalid OAuth code

47. **TC4.6**: OAuth callback with expired code
    - **Input**: Expired authorization code
    - **Expected**: 401 status, authentication failed
    - **Assertions**: Error indicates expired OAuth code

#### OAuth Account Linking
48. **TC4.7**: Link OAuth account to existing user
    - **Input**: Valid JWT token, valid OAuth authorization code
    - **Expected**: 200 status, account linked
    - **Assertions**: User record updated with OAuth provider info

49. **TC4.8**: Login with linked OAuth account
    - **Input**: Valid OAuth authorization code for linked account
    - **Expected**: 200 status, authentication successful
    - **Assertions**: Response contains JWT token for existing account

50. **TC4.9**: Unlink OAuth account
    - **Input**: Valid JWT token, OAuth provider name
    - **Expected**: 200 status, account unlinked
    - **Assertions**: OAuth provider info removed from user record

#### OAuth Error Handling
51. **TC4.10**: OAuth error response handling
    - **Input**: Error response from OAuth provider
    - **Expected**: Appropriate error status, clear message
    - **Assertions**: Error details provided, secure handling

52. **TC4.11**: OAuth scope validation
    - **Input**: OAuth response with insufficient scopes
    - **Expected**: 400 status, scope validation failed
    - **Assertions**: Error indicates required scopes

## PHASE 5: CLI ADMINISTRATION TOOLS
### Test Environment Setup
- Same as Phase 4
- Command-line interface for admin operations

### Test Cases

#### User Management Commands
53. **TC5.1**: List users
    - **Input**: `node auth-admin.js list-users`
    - **Expected**: List of users in system
    - **Assertions**: Output contains user IDs, emails, status

54. **TC5.2**: Get user details
    - **Input**: `node auth-admin.js get-user --id <userId>`
    - **Expected**: Detailed user information
    - **Assertions**: Output contains all user fields

55. **TC5.3**: Create user
    - **Input**: `node auth-admin.js create-user --email test@example.com --password "Password123!" --name "Test User"`
    - **Expected**: User created successfully
    - **Assertions**: Output confirms creation, user exists in database

56. **TC5.4**: Update user
    - **Input**: `node auth-admin.js update-user --id <userId> --name "Updated Name"`
    - **Expected**: User updated successfully
    - **Assertions**: Output confirms update, changes reflected in database

57. **TC5.5**: Delete user
    - **Input**: `node auth-admin.js delete-user --id <userId>`
    - **Expected**: User deleted successfully
    - **Assertions**: Output confirms deletion, user no longer in database

#### Role Management
58. **TC5.6**: Promote user to admin
    - **Input**: `node auth-admin.js promote --id <userId>`
    - **Expected**: User promoted to admin role
    - **Assertions**: Output confirms promotion, user has admin role

59. **TC5.7**: Demote admin to regular user
    - **Input**: `node auth-admin.js demote --id <userId>`
    - **Expected**: Admin demoted to regular user
    - **Assertions**: Output confirms demotion, admin role removed

#### Authentication Management
60. **TC5.8**: Reset user password
    - **Input**: `node auth-admin.js reset-password --id <userId> --password "NewPassword123!"`
    - **Expected**: Password reset successfully
    - **Assertions**: Output confirms reset, user can login with new password

61. **TC5.9**: Force logout (revoke tokens)
    - **Input**: `node auth-admin.js force-logout --id <userId>`
    - **Expected**: All user tokens invalidated
    - **Assertions**: Output confirms logout, existing tokens no longer work

#### MFA Management
62. **TC5.10**: Reset user MFA
    - **Input**: `node auth-admin.js reset-mfa --id <userId>`
    - **Expected**: MFA reset successfully
    - **Assertions**: Output confirms reset, MFA disabled for user

#### System Commands
63. **TC5.11**: Check system status
    - **Input**: `node auth-admin.js status`
    - **Expected**: System status information
    - **Assertions**: Output shows version, uptime, user counts

64. **TC5.12**: Generate system report
    - **Input**: `node auth-admin.js report --type full`
    - **Expected**: Comprehensive system report
    - **Assertions**: Output contains users, activity, errors summary

## PHASE 6: EXTENDED FEATURES
### Test Environment Setup
- Same as Phase 5
- Email testing setup (Ethereal/Mailtrap)

### Test Cases

#### Password Reset Flow
65. **TC6.1**: Request password reset
    - **Input**: Valid email address
    - **Expected**: 200 status, reset email sent
    - **Assertions**: Response indicates email sent, token created in database

66. **TC6.2**: Verify password reset token
    - **Input**: Valid reset token
    - **Expected**: 200 status, token valid
    - **Assertions**: Response indicates token validity

67. **TC6.3**: Complete password reset with valid token
    - **Input**: Valid reset token, new password
    - **Expected**: 200 status, password updated
    - **Assertions**: Password changed in database, old tokens invalidated

68. **TC6.4**: Attempt password reset with invalid token
    - **Input**: Invalid/expired reset token
    - **Expected**: 400 status, token invalid
    - **Assertions**: Error indicates invalid token

69. **TC6.5**: Attempt password reset with weak password
    - **Input**: Valid token, weak password
    - **Expected**: 400 status, password validation failed
    - **Assertions**: Error indicates password requirements

#### Email Verification
70. **TC6.6**: Send verification email
    - **Input**: User registration or manual trigger
    - **Expected**: 200 status, verification email sent
    - **Assertions**: Response indicates email sent, token in database

71. **TC6.7**: Verify email with valid token
    - **Input**: Valid verification token
    - **Expected**: 200 status, email verified
    - **Assertions**: User record updated with verified status

72. **TC6.8**: Verify email with invalid token
    - **Input**: Invalid verification token
    - **Expected**: 400 status, token invalid
    - **Assertions**: Error indicates invalid token

73. **TC6.9**: Resend verification email
    - **Input**: Registered email address
    - **Expected**: 200 status, new verification email sent
    - **Assertions**: Response indicates email sent, new token in database

#### Account Lockout
74. **TC6.10**: Account lockout after failed attempts
    - **Input**: Multiple failed login attempts
    - **Expected**: Account locked after threshold
    - **Assertions**: Login attempts rejected with lockout message

75. **TC6.11**: Account unlock after timeout
    - **Input**: Login after lockout period expired
    - **Expected**: 200 status, login successful
    - **Assertions**: Response contains JWT token, account unlocked

76. **TC6.12**: Manual account unlock
    - **Input**: Admin command to unlock account
    - **Expected**: Account unlocked successfully
    - **Assertions**: User can login immediately after unlock

#### Account Management
77. **TC6.13**: Change email address
    - **Input**: Valid JWT token, new email, current password
    - **Expected**: 200 status, email updated
    - **Assertions**: User record updated with new email

78. **TC6.14**: Change password
    - **Input**: Valid JWT token, current password, new password
    - **Expected**: 200 status, password updated
    - **Assertions**: Password updated in database

79. **TC6.15**: Delete account
    - **Input**: Valid JWT token, current password
    - **Expected**: 200 status, account deleted
    - **Assertions**: User record removed or marked deleted

#### Audit Logging
80. **TC6.16**: Check authentication audit logs
    - **Input**: Admin credentials, date range
    - **Expected**: List of authentication events
    - **Assertions**: Logs include login attempts, success/failure status

81. **TC6.17**: Check administrative action logs
    - **Input**: Admin credentials, date range
    - **Expected**: List of admin actions
    - **Assertions**: Logs include admin actions, actor, affected resources

82. **TC6.18**: Export audit logs
    - **Input**: Admin credentials, date range, format
    - **Expected**: Exported log file
    - **Assertions**: File contains comprehensive logs in specified format

## Integration Test Cases
83. **IT1**: Complete user journey: register → login → update profile
84. **IT2**: MFA journey: enable MFA → logout → login with MFA
85. **IT3**: OAuth journey: authorize → callback → access protected resource
86. **IT4**: Password reset journey: request reset → verify token → set new password
87. **IT5**: Admin journey: create user → promote to admin → demote user → delete user

## Performance Test Cases
88. **PT1**: Authentication throughput (logins per second)
89. **PT2**: Token validation performance
90. **PT3**: Database connection pool behavior under load
91. **PT4**: Rate limiting effectiveness
92. **PT5**: OAuth provider integration response times

## Security Test Cases
93. **ST1**: JWT token security analysis
94. **ST2**: Password storage security (hash algorithm, salt)
95. **ST3**: API endpoint access control testing
96. **ST4**: Session management security
97. **ST5**: Input sanitization and validation thoroughness

---

## Test Execution Plan

### Test Environment Setup
1. **Development**: Local Node.js, SQLite
2. **Testing**: Docker containers, PostgreSQL
3. **Staging**: Cloud deployment mirroring production
4. **Production**: Production environment with monitoring

### Test Data
- Create test users with various statuses and roles
- Prepare mock OAuth responses for testing
- Generate MFA test tokens and recovery codes

### Test Execution Sequence
1. Unit tests for core authentication functions
2. Integration tests for auth flows
3. Security testing of all endpoints
4. Performance testing with simulated load
5. Manual testing of admin tools
6. End-to-end testing of complete journeys

### Test Reporting
- Automated test results stored in CI/CD system
- Security test findings documented with severity
- Performance baselines established and monitored
- Bug tracking integrated with development workflow

---

## Acceptance Criteria

### Phase 1: Basic Authentication
- Users can register with email/password
- Users can login and receive valid JWT tokens
- Protected routes require valid authentication
- Token refresh flow works correctly
- User profiles can be retrieved and updated

### Phase 2: Security Hardening
- All endpoints protected against common attacks
- Rate limiting prevents abuse
- CSRF protection implemented for state-changing operations
- Security headers properly configured
- Input validation blocks malicious payloads

### Phase 3: Multi-Factor Authentication
- Users can enable/disable MFA
- Login flow properly requires MFA when enabled
- Recovery codes work as backup authentication
- MFA secrets securely stored and validated

### Phase 4: OAuth Integration
- Users can authenticate via Google and GitHub
- OAuth accounts can be linked to existing accounts
- OAuth error handling is robust and secure
- User profile information properly mapped from providers

### Phase 5: CLI Administration Tools
- Admins can manage users through CLI
- Role management works correctly
- Password resets and forced logouts function properly
- System reporting provides accurate information

### Phase 6: Extended Features
- Password reset flow works end-to-end
- Email verification flow works correctly
- Account lockout prevents brute force attacks
- Audit logging captures all important events
