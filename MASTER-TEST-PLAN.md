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
- JWT Access Tokens: 15-minute expiration
- Refresh Tokens: 7-day expiration with rotation
- Password Hashing: Argon2 algorithm

### TC-P1-001: User Registration - Valid Data
**Objective**: Verify successful user registration with valid email and password
**Prerequisites**: Clean database state
**Test Data**: 
- Email: testuser@example.com
- Password: SecurePass123!
**Steps**:
1. Send POST to `/api/auth/register`
2. Include email and password in request body
3. Verify response status 201
4. Confirm user created in database
5. Check password is hashed (not plaintext)
**Expected Result**: User successfully registered, password securely hashed
**Priority**: Critical

### TC-P1-002: User Registration - Invalid Email Format
**Objective**: Verify system rejects invalid email formats
**Test Data**: 
- Email: invalid-email-format
- Password: SecurePass123!
**Steps**:
1. Send POST to `/api/auth/register`
2. Use invalid email format
3. Verify response status 400
4. Check error message mentions email validation
**Expected Result**: Registration rejected with appropriate error message
**Priority**: High

### TC-P1-003: User Registration - Weak Password
**Objective**: Verify password strength requirements enforced
**Test Data**: 
- Email: testuser@example.com
- Password: 123
**Steps**:
1. Send POST to `/api/auth/register`
2. Use weak password
3. Verify response status 400
4. Check error message mentions password requirements
**Expected Result**: Registration rejected due to weak password
**Priority**: High

### TC-P1-004: User Registration - Duplicate Email
**Objective**: Verify system prevents duplicate email registration
**Prerequisites**: User already exists with testuser@example.com
**Test Data**: 
- Email: testuser@example.com (existing)
- Password: SecurePass123!
**Steps**:
1. Register user with email
2. Attempt second registration with same email
3. Verify response status 409
4. Check error message indicates email already exists
**Expected Result**: Duplicate registration rejected
**Priority**: Critical

### TC-P1-005: User Login - Valid Credentials
**Objective**: Verify successful login with correct credentials
**Prerequisites**: User registered with testuser@example.com
**Test Data**: 
- Email: testuser@example.com
- Password: SecurePass123!
**Steps**:
1. Send POST to `/api/auth/login`
2. Include valid email and password
3. Verify response status 200
4. Check access token returned in response body
5. Verify refresh token set as httpOnly cookie
6. Confirm tokens have correct expiration times
**Expected Result**: Successful login with JWT tokens issued
**Priority**: Critical

### TC-P1-006: User Login - Invalid Email
**Objective**: Verify login rejection for non-existent email
**Test Data**: 
- Email: nonexistent@example.com
- Password: SecurePass123!
**Steps**:
1. Send POST to `/api/auth/login`
2. Use non-existent email
3. Verify response status 401
4. Check error message is generic (no user enumeration)
**Expected Result**: Login rejected without revealing user existence
**Priority**: High

### TC-P1-007: User Login - Invalid Password
**Objective**: Verify login rejection for incorrect password
**Prerequisites**: User registered with testuser@example.com
**Test Data**: 
- Email: testuser@example.com
- Password: WrongPassword123!
**Steps**:
1. Send POST to `/api/auth/login`
2. Use correct email but wrong password
3. Verify response status 401
4. Check error message is generic
**Expected Result**: Login rejected with generic error message
**Priority**: High

### TC-P1-008: Token Refresh - Valid Refresh Token
**Objective**: Verify access token refresh with valid refresh token
**Prerequisites**: User logged in with valid refresh token cookie
**Steps**:
1. Send POST to `/api/auth/refresh`
2. Include refresh token cookie from login
3. Verify response status 200
4. Check new access token returned
5. Verify new refresh token cookie set (rotation)
6. Confirm old refresh token invalidated
**Expected Result**: New tokens issued, old refresh token rotated
**Priority**: Critical

### TC-P1-009: Token Refresh - Invalid Refresh Token
**Objective**: Verify refresh rejection with invalid token
**Test Data**: Invalid or expired refresh token
**Steps**:
1. Send POST to `/api/auth/refresh`
2. Include invalid refresh token cookie
3. Verify response status 401
4. Check appropriate error message
**Expected Result**: Refresh rejected, no new tokens issued
**Priority**: High

### TC-P1-010: Token Refresh - Missing Refresh Token
**Objective**: Verify refresh rejection when no token provided
**Steps**:
1. Send POST to `/api/auth/refresh`
2. Do not include refresh token cookie
3. Verify response status 401
4. Check error message indicates missing token
**Expected Result**: Refresh rejected due to missing token
**Priority**: Medium

### TC-P1-011: Protected Route Access - Valid Token
**Objective**: Verify protected route access with valid JWT
**Prerequisites**: User logged in with valid access token
**Steps**:
1. Send GET to `/api/auth/protected`
2. Include valid access token in Authorization header
3. Verify response status 200
4. Check user information returned
**Expected Result**: Protected route accessible with valid token
**Priority**: Critical

### TC-P1-012: Protected Route Access - Invalid Token
**Objective**: Verify protected route rejection with invalid JWT
**Test Data**: Malformed or expired access token
**Steps**:
1. Send GET to `/api/auth/protected`
2. Include invalid access token
3. Verify response status 401
4. Check error message indicates invalid token
**Expected Result**: Protected route access denied
**Priority**: High

### TC-P1-013: Protected Route Access - Missing Token
**Objective**: Verify protected route rejection without token
**Steps**:
1. Send GET to `/api/auth/protected`
2. Do not include Authorization header
3. Verify response status 401
4. Check error message indicates missing token
**Expected Result**: Protected route access denied
**Priority**: Medium

### TC-P1-014: User Logout - Valid Session
**Objective**: Verify successful logout and token invalidation
**Prerequisites**: User logged in with valid tokens
**Steps**:
1. Send POST to `/api/auth/logout`
2. Include valid access token and refresh token cookie
3. Verify response status 200
4. Check refresh token invalidated in database
5. Confirm refresh token cookie cleared
**Expected Result**: Successful logout, tokens invalidated
**Priority**: Critical

### TC-P1-015: User Logout - Invalid Session
**Objective**: Verify logout handling with invalid tokens
**Test Data**: Invalid or missing tokens
**Steps**:
1. Send POST to `/api/auth/logout`
2. Use invalid or no tokens
3. Verify response status (should handle gracefully)
4. Check appropriate response message
**Expected Result**: Logout handled gracefully regardless of token state
**Priority**: Low

---

## PHASE 2: SECURITY HARDENING
### Security Enhancement Overview
- Helmet.js for security headers
- CSRF protection implementation
- Rate limiting on authentication endpoints
- HTTP Parameter Pollution (HPP) protection
- Enhanced error handling and logging

### TC-P2-001: Security Headers Validation
**Objective**: Verify all required security headers are present
**Steps**:
1. Send GET request to any endpoint
2. Examine response headers
3. Verify presence of security headers:
   - X-Content-Type-Options: nosniff
   - X-Frame-Options: DENY
   - X-XSS-Protection: 1; mode=block
   - Strict-Transport-Security (if HTTPS)
   - Content-Security-Policy
**Expected Result**: All security headers present and correctly configured
**Priority**: Critical

### TC-P2-002: CSRF Protection - Missing Token
**Objective**: Verify CSRF protection blocks requests without token
**Steps**:
1. Send POST to `/api/auth/login` without CSRF token
2. Verify response status 403
3. Check error message indicates CSRF token required
**Expected Result**: Request blocked due to missing CSRF token
**Priority**: High

### TC-P2-003: CSRF Protection - Invalid Token
**Objective**: Verify CSRF protection blocks requests with invalid token
**Test Data**: Malformed or incorrect CSRF token
**Steps**:
1. Get CSRF token from `/api/auth/csrf-token`
2. Modify token to make it invalid
3. Send POST to `/api/auth/login` with invalid token
4. Verify response status 403
**Expected Result**: Request blocked due to invalid CSRF token
**Priority**: High

### TC-P2-004: CSRF Protection - Valid Token
**Objective**: Verify legitimate requests pass with valid CSRF token
**Steps**:
1. Get CSRF token from `/api/auth/csrf-token`
2. Include valid token in request headers/body
3. Send POST to `/api/auth/login`
4. Verify request processes normally
**Expected Result**: Request succeeds with valid CSRF token
**Priority**: Critical

### TC-P2-005: Rate Limiting - Normal Usage
**Objective**: Verify normal requests are not rate limited
**Steps**:
1. Send 5 login requests within 15 minutes
2. Verify all requests process normally
3. Check response headers for rate limit info
**Expected Result**: Normal usage unaffected by rate limiting
**Priority**: Medium

### TC-P2-006: Rate Limiting - Excessive Requests
**Objective**: Verify rate limiting blocks excessive requests
**Steps**:
1. Send 20 rapid login requests from same IP
2. Verify rate limiting triggers (429 status)
3. Check error message indicates rate limit exceeded
4. Wait for rate limit reset
5. Verify requests resume normally
**Expected Result**: Excessive requests blocked, normal service resumes after reset
**Priority**: High

### TC-P2-007: HPP Protection - Parameter Pollution
**Objective**: Verify HTTP Parameter Pollution protection
**Test Data**: Duplicate parameters in request
**Steps**:
1. Send POST with duplicate 'email' parameters
2. Verify server handles gracefully
3. Check only one parameter value processed
**Expected Result**: Parameter pollution handled correctly
**Priority**: Medium

### TC-P2-008: Error Handling - Sensitive Information
**Objective**: Verify error messages don't leak sensitive information
**Steps**:
1. Trigger various error conditions
2. Examine error responses
3. Verify no database errors, file paths, or stack traces exposed
4. Check error messages are generic but helpful
**Expected Result**: Error messages secure and user-friendly
**Priority**: High

### TC-P2-009: Input Validation - SQL Injection Attempt
**Objective**: Verify protection against SQL injection
**Test Data**: Email with SQL injection payload
**Steps**:
1. Send login request with SQL injection in email field
2. Verify request handled safely
3. Check no database errors or unexpected behavior
**Expected Result**: SQL injection attempt blocked/sanitized
**Priority**: Critical

### TC-P2-010: Input Validation - XSS Attempt
**Objective**: Verify protection against Cross-Site Scripting
**Test Data**: Script tags in input fields
**Steps**:
1. Send registration with script tags in email/password
2. Verify input sanitized or rejected
3. Check no script execution occurs
**Expected Result**: XSS attempt prevented
**Priority**: High

---

## PHASE 3: MULTI-FACTOR AUTHENTICATION (MFA)
### MFA Implementation Overview
- TOTP (Time-based One-Time Password) using Speakeasy
- QR code generation for authenticator app setup
- Backup codes for account recovery
- MFA enforcement options

### TC-P3-001: MFA Setup Initiation
**Objective**: Verify MFA setup process initiation
**Prerequisites**: User logged in with valid session
**Steps**:
1. Send GET to `/api/auth/mfa/setup`
2. Include valid access token
3. Verify response status 200
4. Check response contains:
   - QR code data URI
   - Backup codes array
   - Setup instructions
**Expected Result**: MFA setup data returned successfully
**Priority**: Critical

### TC-P3-002: MFA QR Code Generation
**Objective**: Verify QR code contains correct TOTP configuration
**Prerequisites**: MFA setup initiated
**Steps**:
1. Decode QR code from setup response
2. Verify TOTP URL format: `otpauth://totp/App:user@example.com?secret=...&issuer=App`
3. Check secret key is base32 encoded
4. Verify issuer and account name are correct
**Expected Result**: QR code contains valid TOTP configuration
**Priority**: High

### TC-P3-003: MFA Backup Codes Generation
**Objective**: Verify backup codes are generated and stored securely
**Prerequisites**: MFA setup initiated
**Steps**:
1. Check backup codes in setup response
2. Verify 10 unique codes generated
3. Confirm codes are 8 characters alphanumeric
4. Check codes are hashed in database
**Expected Result**: Secure backup codes generated and stored
**Priority**: High

### TC-P3-004: MFA Enablement - Valid TOTP
**Objective**: Verify MFA can be enabled with correct TOTP code
**Prerequisites**: MFA setup completed, authenticator app configured
**Test Data**: Valid 6-digit TOTP code from authenticator
**Steps**:
1. Generate TOTP code from authenticator app
2. Send POST to `/api/auth/mfa/enable` with code
3. Verify response status 200
4. Check user MFA status updated in database
5. Confirm success message returned
**Expected Result**: MFA successfully enabled for user
**Priority**: Critical

### TC-P3-005: MFA Enablement - Invalid TOTP
**Objective**: Verify MFA enablement fails with incorrect TOTP
**Test Data**: Invalid 6-digit code (e.g., 000000)
**Steps**:
1. Send POST to `/api/auth/mfa/enable` with invalid code
2. Verify response status 400
3. Check error message indicates invalid code
4. Confirm MFA remains disabled
**Expected Result**: MFA enablement rejected with invalid code
**Priority**: High

### TC-P3-006: MFA Enablement - Expired TOTP
**Objective**: Verify MFA enablement fails with expired TOTP
**Test Data**: TOTP code from previous time window
**Steps**:
1. Wait for TOTP time window to expire
2. Use code from previous window
3. Send POST to `/api/auth/mfa/enable`
4. Verify response status 400
**Expected Result**: Expired TOTP code rejected
**Priority**: Medium

### TC-P3-007: Login with MFA - Valid TOTP
**Objective**: Verify login requires and accepts valid TOTP when MFA enabled
**Prerequisites**: User has MFA enabled
**Test Data**: 
- Email: testuser@example.com
- Password: SecurePass123!
- TOTP: Valid 6-digit code
**Steps**:
1. Send POST to `/api/auth/login` with email/password
2. Verify response indicates MFA required
3. Send POST to `/api/auth/mfa/verify` with TOTP
4. Verify response status 200
5. Check access and refresh tokens issued
**Expected Result**: Successful login after MFA verification
**Priority**: Critical

### TC-P3-008: Login with MFA - Invalid TOTP
**Objective**: Verify login fails with invalid TOTP when MFA enabled
**Prerequisites**: User has MFA enabled
**Test Data**: Invalid TOTP code
**Steps**:
1. Complete first step of login (email/password)
2. Send invalid TOTP to `/api/auth/mfa/verify`
3. Verify response status 400
4. Check no tokens issued
5. Confirm error message indicates invalid code
**Expected Result**: Login fails with invalid MFA code
**Priority**: High

### TC-P3-009: Login with MFA - Missing TOTP
**Objective**: Verify login fails when MFA required but not provided
**Prerequisites**: User has MFA enabled
**Steps**:
1. Send POST to `/api/auth/login` with only email/password
2. Verify partial login success (no tokens yet)
3. Attempt to access protected routes
4. Verify access denied until MFA completed
**Expected Result**: Login incomplete without MFA verification
**Priority**: High

### TC-P3-010: Backup Code Usage - Valid Code
**Objective**: Verify backup codes work for MFA verification
**Prerequisites**: User has MFA enabled with backup codes
**Test Data**: Valid unused backup code
**Steps**:
1. Complete first step of login
2. Send backup code to `/api/auth/mfa/verify`
3. Verify response status 200
4. Check tokens issued successfully
5. Confirm backup code marked as used
**Expected Result**: Successful login with backup code
**Priority**: Critical

### TC-P3-011: Backup Code Usage - Used Code
**Objective**: Verify used backup codes are rejected
**Prerequisites**: Backup code already used once
**Test Data**: Previously used backup code
**Steps**:
1. Attempt login with used backup code
2. Verify response status 400
3. Check error indicates code already used
4. Confirm no tokens issued
**Expected Result**: Used backup code rejected
**Priority**: High

### TC-P3-012: Backup Code Usage - Invalid Code
**Objective**: Verify invalid backup codes are rejected
**Test Data**: Non-existent backup code
**Steps**:
1. Complete first step of login
2. Send invalid backup code to MFA verify endpoint
3. Verify response status 400
4. Check error message indicates invalid code
**Expected Result**: Invalid backup code rejected
**Priority**: Medium

### TC-P3-013: MFA Disablement
**Objective**: Verify MFA can be disabled by authenticated user
**Prerequisites**: User logged in with MFA enabled
**Steps**:
1. Send POST to `/api/auth/mfa/disable`
2. Include valid access token
3. Verify response status 200
4. Check MFA disabled in database
5. Confirm backup codes cleared
**Expected Result**: MFA successfully disabled
**Priority**: High

### TC-P3-014: MFA Status Check
**Objective**: Verify MFA status can be checked
**Prerequisites**: User logged in
**Steps**:
1. Send GET to `/api/auth/mfa/status`
2. Include valid access token
3. Verify response contains MFA enabled/disabled status
4. Check backup codes count if applicable
**Expected Result**: Accurate MFA status returned
**Priority**: Medium

### TC-P3-015: Concurrent MFA Attempts
**Objective**: Verify system handles multiple MFA verification attempts
**Prerequisites**: User has MFA enabled
**Steps**:
1. Start multiple login sessions
2. Attempt MFA verification on multiple sessions
3. Verify each session handled independently
4. Check no interference between sessions
**Expected Result**: Multiple MFA sessions handled correctly
**Priority**: Low

---

## PHASE 4: OAUTH INTEGRATION
### OAuth Implementation Overview
- Google OAuth 2.0 integration using Passport.js
- GitHub OAuth integration using Passport.js
- Account linking for existing users
- Session management for OAuth flows

### TC-P4-001: Google OAuth Initiation
**Objective**: Verify Google OAuth login flow initiation
**Steps**:
1. Navigate to `/auth/google` endpoint
2. Verify redirect to Google OAuth authorization URL
3. Check URL contains correct client_id and scope parameters
4. Verify state parameter included for CSRF protection
**Expected Result**: Successful redirect to Google OAuth with correct parameters
**Priority**: Critical

### TC-P4-002: Google OAuth Callback - New User
**Objective**: Verify new user creation from successful Google OAuth
**Prerequisites**: Google account not previously registered
**Test Data**: Google account with email, name, profile picture
**Steps**:
1. Complete Google OAuth authorization
2. Verify callback to `/auth/google/callback`
3. Check new user created in database
4. Confirm OAuth account record created
5. Verify tokens issued (access + refresh)
6. Check redirect to success page
**Expected Result**: New user account created and authenticated
**Priority**: Critical

### TC-P4-003: Google OAuth Callback - Existing User
**Objective**: Verify existing user login via Google OAuth
**Prerequisites**: User previously registered with Google OAuth
**Steps**:
1. Complete Google OAuth authorization
2. Verify user found by OAuth account ID
3. Check no duplicate user created
4. Confirm fresh tokens issued
5. Verify successful authentication
**Expected Result**: Existing user authenticated without duplication
**Priority**: High

### TC-P4-004: Google OAuth Callback - Account Linking
**Objective**: Verify Google account linking to existing email user
**Prerequisites**: User registered with email, same email used in Google account
**Steps**:
1. Register user with email/password
2. Complete Google OAuth with same email
3. Verify OAuth account linked to existing user
4. Check no duplicate user created
5. Confirm user can use both login methods
**Expected Result**: Google account successfully linked to existing user
**Priority**: High

### TC-P4-005: Google OAuth Error Handling
**Objective**: Verify handling of Google OAuth errors
**Test Scenarios**: 
- User denies authorization
- Invalid state parameter
- Network errors during callback
**Steps**:
1. Trigger OAuth error conditions
2. Verify appropriate error handling
3. Check user redirected to error page
4. Confirm no partial account creation
**Expected Result**: OAuth errors handled gracefully with user feedback
**Priority**: Medium

### TC-P4-006: GitHub OAuth Initiation
**Objective**: Verify GitHub OAuth login flow initiation
**Steps**:
1. Navigate to `/auth/github` endpoint
2. Verify redirect to GitHub OAuth authorization URL
3. Check URL contains correct client_id and scope
4. Verify state parameter for security
**Expected Result**: Successful redirect to GitHub OAuth
**Priority**: Critical

### TC-P4-007: GitHub OAuth Callback - New User
**Objective**: Verify new user creation from GitHub OAuth
**Prerequisites**: GitHub account not previously registered
**Test Data**: GitHub account with username, email, avatar
**Steps**:
1. Complete GitHub OAuth authorization
2. Verify callback to `/auth/github/callback`
3. Check new user created with GitHub data
4. Confirm OAuth account record created
5. Verify authentication tokens issued
**Expected Result**: New user created and authenticated via GitHub
**Priority**: Critical

### TC-P4-008: GitHub OAuth Callback - Existing User
**Objective**: Verify existing GitHub user authentication
**Prerequisites**: User previously registered via GitHub
**Steps**:
1. Complete GitHub OAuth flow
2. Verify user matched by GitHub ID
3. Check authentication successful
4. Confirm fresh tokens issued
**Expected Result**: Existing GitHub user authenticated successfully
**Priority**: High

### TC-P4-009: GitHub OAuth Account Linking
**Objective**: Verify GitHub account linking to existing user
**Prerequisites**: User with matching email already exists
**Steps**:
1. Have existing user with email
2. Complete GitHub OAuth with same email
3. Verify accounts linked properly
4. Check user has both authentication methods
**Expected Result**: GitHub account linked to existing user
**Priority**: High

### TC-P4-010: Multiple OAuth Account Linking
**Objective**: Verify user can link multiple OAuth providers
**Prerequisites**: User registered with Google OAuth
**Steps**:
1. User authenticated with Google
2. Initiate GitHub OAuth linking process
3. Verify both OAuth accounts linked to same user
4. Test login with both providers
**Expected Result**: User can authenticate with multiple OAuth providers
**Priority**: Medium

### TC-P4-011: OAuth Session Management
**Objective**: Verify OAuth authentication creates proper sessions
**Prerequisites**: Successful OAuth login
**Steps**:
1. Complete OAuth authentication
2. Verify session cookie set correctly
3. Check access to protected routes
4. Test session persistence across requests
5. Verify logout clears OAuth session
**Expected Result**: OAuth sessions managed correctly
**Priority**: High

### TC-P4-012: OAuth Profile Data Handling
**Objective**: Verify OAuth profile data correctly stored
**Test Data**: Google/GitHub profile with name, email, avatar
**Steps**:
1. Complete OAuth with profile data
2. Verify user data stored in database
3. Check profile picture URL saved
4. Confirm display name updated
5. Test profile data retrieval
**Expected Result**: OAuth profile data correctly processed and stored
**Priority**: Medium

### TC-P4-013: OAuth State Parameter Security
**Objective**: Verify OAuth state parameter prevents CSRF
**Steps**:
1. Initiate OAuth flow and capture state parameter
2. Modify state parameter in callback URL
3. Verify OAuth callback rejects invalid state
4. Check error handling for state mismatch
**Expected Result**: Invalid state parameter blocks OAuth completion
**Priority**: High

### TC-P4-014: OAuth Account Unlinking
**Objective**: Verify OAuth accounts can be unlinked safely
**Prerequisites**: User with multiple authentication methods
**Steps**:
1. User has email/password + OAuth account
2. Remove OAuth account link
3. Verify user can still authenticate with email/password
4. Check OAuth account record removed
**Expected Result**: OAuth account safely unlinked without breaking access
**Priority**: Medium

### TC-P4-015: OAuth Provider Unavailable
**Objective**: Verify handling when OAuth provider is unavailable
**Test Scenarios**: OAuth provider server errors, timeouts
**Steps**:
1. Simulate OAuth provider unavailability
2. Attempt OAuth authentication
3. Verify appropriate error handling
4. Check fallback authentication methods still work
**Expected Result**: Graceful handling of OAuth provider issues
**Priority**: Low

---

## PHASE 5: CLI ADMINISTRATION TOOLS
### CLI Tool Overview
- Commander.js-based command-line interface
- User management operations (promote, demote, list)
- Session management (revoke user sessions)
- Database interaction for admin tasks

### TC-P5-001: CLI Tool Installation
**Objective**: Verify CLI tool can be installed and executed
**Prerequisites**: Node.js environment available
**Steps**:
1. Navigate to project directory
2. Verify `auth-admin-cli.js` exists
3. Test CLI execution: `node auth-admin-cli.js --help`
4. Check help menu displays available commands
5. Verify command structure and options shown
**Expected Result**: CLI tool executes and shows help information
**Priority**: Critical

### TC-P5-002: List Users Command
**Objective**: Verify user listing functionality
**Prerequisites**: Database with test users
**Test Command**: `node auth-admin-cli.js list-users`
**Steps**:
1. Execute list-users command
2. Verify output shows user information:
   - User ID
   - Email address
   - Registration date
   - MFA status
   - Admin status
3. Check output formatting is readable
4. Verify all users displayed
**Expected Result**: All users listed with complete information
**Priority**: High

### TC-P5-003: List Users with Filters
**Objective**: Verify user listing with filtering options
**Test Commands**: 
- `node auth-admin-cli.js list-users --admin-only`
- `node auth-admin-cli.js list-users --mfa-enabled`
**Steps**:
1. Execute commands with different filters
2. Verify only matching users displayed
3. Check filter logic works correctly
4. Confirm output shows filter criteria
**Expected Result**: Filtered user lists display correctly
**Priority**: Medium

### TC-P5-004: Promote User to Admin
**Objective**: Verify user can be promoted to admin status
**Prerequisites**: Non-admin user exists (testuser@example.com)
**Test Command**: `node auth-admin-cli.js promote testuser@example.com`
**Steps**:
1. Verify user is not admin initially
2. Execute promote command
3. Check success message displayed
4. Verify user admin status updated in database
5. Confirm user can access admin functions
**Expected Result**: User successfully promoted to admin
**Priority**: Critical

### TC-P5-005: Promote User - User Not Found
**Objective**: Verify promote command handles non-existent users
**Test Command**: `node auth-admin-cli.js promote nonexistent@example.com`
**Steps**:
1. Execute promote command with invalid email
2. Verify appropriate error message
3. Check command exits gracefully
4. Confirm no database changes made
**Expected Result**: Error message for non-existent user
**Priority**: Medium

### TC-P5-006: Promote User - Already Admin
**Objective**: Verify promote command handles users already admin
**Prerequisites**: User with admin status
**Test Command**: `node auth-admin-cli.js promote admin@example.com`
**Steps**:
1. Execute promote on existing admin user
2. Verify appropriate message displayed
3. Check no errors occur
4. Confirm admin status unchanged
**Expected Result**: Graceful handling of already-admin user
**Priority**: Low

### TC-P5-007: Demote User from Admin
**Objective**: Verify admin user can be demoted to regular user
**Prerequisites**: Admin user exists
**Test Command**: `node auth-admin-cli.js demote admin@example.com`
**Steps**:
1. Verify user has admin status initially
2. Execute demote command
3. Check success message displayed
4. Verify admin status removed in database
5. Confirm user loses admin privileges
**Expected Result**: Admin user successfully demoted
**Priority**: Critical

### TC-P5-008: Demote User - User Not Found
**Objective**: Verify demote command handles non-existent users
**Test Command**: `node auth-admin-cli.js demote nonexistent@example.com`
**Steps**:
1. Execute demote command with invalid email
2. Verify error message for non-existent user
3. Check command exits gracefully
**Expected Result**: Appropriate error for non-existent user
**Priority**: Medium

### TC-P5-009: Demote User - Not Admin
**Objective**: Verify demote command handles non-admin users
**Prerequisites**: Regular user (not admin)
**Test Command**: `node auth-admin-cli.js demote regular@example.com`
**Steps**:
1. Execute demote on non-admin user
2. Verify appropriate message displayed
3. Check no errors occur
4. Confirm user status unchanged
**Expected Result**: Graceful handling of non-admin user
**Priority**: Low

### TC-P5-010: Revoke User Sessions
**Objective**: Verify user sessions can be revoked via CLI
**Prerequisites**: User with active sessions/refresh tokens
**Test Command**: `node auth-admin-cli.js revoke-sessions testuser@example.com`
**Steps**:
1. Verify user has active refresh tokens
2. Execute revoke-sessions command
3. Check success message displayed
4. Verify all user refresh tokens invalidated
5. Confirm user must re-authenticate
**Expected Result**: All user sessions successfully revoked
**Priority**: Critical

### TC-P5-011: Revoke Sessions - User Not Found
**Objective**: Verify session revocation handles non-existent users
**Test Command**: `node auth-admin-cli.js revoke-sessions nonexistent@example.com`
**Steps**:
1. Execute revoke-sessions with invalid email
2. Verify error message for non-existent user
3. Check command exits gracefully
**Expected Result**: Error message for non-existent user
**Priority**: Medium

### TC-P5-012: Revoke Sessions - No Active Sessions
**Objective**: Verify session revocation handles users with no sessions
**Prerequisites**: User with no active refresh tokens
**Test Command**: `node auth-admin-cli.js revoke-sessions newsuer@example.com`
**Steps**:
1. Execute revoke-sessions on user with no sessions
2. Verify appropriate message displayed
3. Check no errors occur
**Expected Result**: Graceful handling of users with no sessions
**Priority**: Low

### TC-P5-013: CLI Database Connection
**Objective**: Verify CLI tool connects to database correctly
**Prerequisites**: Database running and accessible
**Steps**:
1. Execute any CLI command
2. Verify database connection established
3. Check operations complete successfully
4. Confirm connection closed properly
**Expected Result**: Successful database operations
**Priority**: High

### TC-P5-014: CLI Error Handling
**Objective**: Verify CLI tool handles errors gracefully
**Test Scenarios**: 
- Database unavailable
- Invalid command arguments
- Network connectivity issues
**Steps**:
1. Trigger various error conditions
2. Verify appropriate error messages
3. Check CLI doesn't crash unexpectedly
4. Confirm helpful error information provided
**Expected Result**: Robust error handling with user-friendly messages
**Priority**: Medium

### TC-P5-015: CLI Command Validation
**Objective**: Verify CLI validates command arguments
**Test Commands**: Invalid command usage
**Steps**:
1. Execute commands with missing arguments
2. Execute commands with invalid options
3. Verify validation error messages
4. Check help information displayed when appropriate
**Expected Result**: Command validation with helpful feedback
**Priority**: Medium

---

## PHASE 6: EXTENDED FEATURES
### Extended Features Overview
- Password reset functionality with secure token generation
- Email verification system for new registrations
- Comprehensive audit logging for security events
- Enhanced account security features

### TC-P6-001: Password Reset Request
**Objective**: Verify password reset can be initiated with valid email
**Prerequisites**: User registered with testuser@example.com
**Test Data**: Email: testuser@example.com
**Steps**:
1. Send POST to `/api/auth/password-reset/request`
2. Include user email in request body
3. Verify response status 200
4. Check success message (generic for security)
5. Verify reset token generated and stored in database
6. Check token expiration set (15 minutes)
7. Confirm email would be sent (check logs/mock)
**Expected Result**: Password reset initiated, secure token generated
**Priority**: Critical

### TC-P6-002: Password Reset Request - Invalid Email
**Objective**: Verify password reset handles non-existent email securely
**Test Data**: Email: nonexistent@example.com
**Steps**:
1. Send POST to `/api/auth/password-reset/request`
2. Use non-existent email address
3. Verify response status 200 (same as valid)
4. Check generic success message (no user enumeration)
5. Confirm no reset token created
6. Verify no email sent
**Expected Result**: Generic response prevents user enumeration
**Priority**: High

### TC-P6-003: Password Reset Request - Rate Limiting
**Objective**: Verify password reset requests are rate limited
**Prerequisites**: User email testuser@example.com
**Steps**:
1. Send multiple password reset requests rapidly
2. Verify rate limiting triggers after threshold
3. Check appropriate error message (429 status)
4. Wait for rate limit reset
5. Verify requests resume normally
**Expected Result**: Password reset requests properly rate limited
**Priority**: High

### TC-P6-004: Password Reset Token Validation
**Objective**: Verify password reset token can be validated
**Prerequisites**: Valid reset token generated for user
**Test Data**: Valid reset token from database
**Steps**:
1. Send GET to `/api/auth/password-reset/validate/{token}`
2. Use valid, unexpired reset token
3. Verify response status 200
4. Check token validation success message
5. Confirm token not consumed by validation
**Expected Result**: Valid token confirmed without consumption
**Priority**: High

### TC-P6-005: Password Reset Token Validation - Invalid Token
**Objective**: Verify invalid reset tokens are rejected
**Test Data**: Malformed or non-existent token
**Steps**:
1. Send GET to `/api/auth/password-reset/validate/{invalid-token}`
2. Use invalid reset token
3. Verify response status 400
4. Check error message indicates invalid token
**Expected Result**: Invalid token rejected with appropriate error
**Priority**: High

### TC-P6-006: Password Reset Token Validation - Expired Token
**Objective**: Verify expired reset tokens are rejected
**Prerequisites**: Expired reset token in database
**Steps**:
1. Wait for reset token to expire (15+ minutes)
2. Send GET to validate expired token
3. Verify response status 400
4. Check error message indicates token expired
5. Confirm expired token removed from database
**Expected Result**: Expired token rejected and cleaned up
**Priority**: High

### TC-P6-007: Password Reset Completion
**Objective**: Verify password can be reset with valid token
**Prerequisites**: Valid reset token and new password
**Test Data**: 
- Token: valid reset token
- New Password: NewSecurePass123!
**Steps**:
1. Send POST to `/api/auth/password-reset/complete`
2. Include valid token and new password
3. Verify response status 200
4. Check success message returned
5. Verify password updated in database (hashed)
6. Confirm reset token consumed/deleted
7. Test login with new password works
8. Verify old password no longer works
**Expected Result**: Password successfully reset, token consumed
**Priority**: Critical

### TC-P6-008: Password Reset Completion - Invalid Token
**Objective**: Verify password reset fails with invalid token
**Test Data**: Invalid token, new password
**Steps**:
1. Send POST to password reset complete endpoint
2. Use invalid or expired token
3. Verify response status 400
4. Check error message indicates invalid token
5. Confirm password not changed
**Expected Result**: Password reset rejected with invalid token
**Priority**: High

### TC-P6-009: Password Reset Completion - Weak Password
**Objective**: Verify password reset enforces password strength
**Test Data**: Valid token, weak password (123)
**Steps**:
1. Send POST to password reset complete endpoint
2. Use valid token but weak new password
3. Verify response status 400
4. Check error message indicates password requirements
5. Confirm password not changed
6. Verify token remains valid for retry
**Expected Result**: Weak password rejected, token preserved
**Priority**: High

### TC-P6-010: Email Verification - New Registration
**Objective**: Verify email verification required for new users
**Test Data**: New user registration
**Steps**:
1. Register new user account
2. Verify account created but marked unverified
3. Check verification token generated
4. Confirm verification email would be sent
5. Verify login blocked until email verified
**Expected Result**: New account requires email verification
**Priority**: Critical

### TC-P6-011: Email Verification Token Validation
**Objective**: Verify email verification tokens can be validated
**Prerequisites**: Unverified user with verification token
**Test Data**: Valid verification token
**Steps**:
1. Send GET to `/api/auth/email/verify/{token}`
2. Use valid verification token
3. Verify response status 200
4. Check user marked as verified in database
5. Confirm verification token consumed
6. Verify user can now login normally
**Expected Result**: Email successfully verified, account activated
**Priority**: Critical

### TC-P6-012: Email Verification - Invalid Token
**Objective**: Verify invalid verification tokens are rejected
**Test Data**: Invalid or malformed token
**Steps**:
1. Send GET to email verification endpoint
2. Use invalid verification token
3. Verify response status 400
4. Check error message indicates invalid token
5. Confirm user remains unverified
**Expected Result**: Invalid verification token rejected
**Priority**: High

### TC-P6-013: Email Verification - Expired Token
**Objective**: Verify expired verification tokens are handled
**Prerequisites**: Expired verification token
**Steps**:
1. Attempt verification with expired token
2. Verify response status 400
3. Check error message indicates expiration
4. Confirm option to resend verification
**Expected Result**: Expired token rejected with resend option
**Priority**: Medium

### TC-P6-014: Email Verification Resend
**Objective**: Verify verification email can be resent
**Prerequisites**: Unverified user account
**Test Data**: User email address
**Steps**:
1. Send POST to `/api/auth/email/resend-verification`
2. Include user email in request
3. Verify response status 200
4. Check new verification token generated
5. Confirm old token invalidated
6. Verify rate limiting applied
**Expected Result**: New verification email sent, old token invalidated
**Priority**: High

### TC-P6-015: Audit Logging - Authentication Events
**Objective**: Verify authentication events are logged for audit
**Test Scenarios**: Login, logout, failed login attempts
**Steps**:
1. Perform various authentication actions
2. Check audit logs created in database/files
3. Verify log entries contain:
   - Timestamp
   - User identifier
   - Action performed
   - IP address
   - User agent
   - Success/failure status
**Expected Result**: Comprehensive audit trail maintained
**Priority**: High

### TC-P6-016: Audit Logging - Administrative Actions
**Objective**: Verify admin actions are logged
**Test Scenarios**: User promotion, session revocation, password resets
**Steps**:
1. Perform administrative actions via CLI/API
2. Check audit logs for admin events
3. Verify admin user identified in logs
4. Confirm target user/action details recorded
**Expected Result**: Administrative actions fully audited
**Priority**: Medium

### TC-P6-017: Audit Logging - Security Events
**Objective**: Verify security events are logged
**Test Scenarios**: 
- Failed MFA attempts
- Rate limiting triggers
- Invalid token usage
- Password reset requests
**Steps**:
1. Trigger various security events
2. Check security audit logs
3. Verify threat indicators captured
4. Confirm log retention policies
**Expected Result**: Security events comprehensively logged
**Priority**: High

### TC-P6-018: Account Lockout - Failed Login Attempts
**Objective**: Verify account lockout after repeated failed logins
**Prerequisites**: User account for testing
**Steps**:
1. Attempt login with wrong password multiple times
2. Verify account locked after threshold (5 attempts)
3. Check lockout duration enforced (30 minutes)
4. Verify legitimate user cannot login during lockout
5. Confirm lockout expires and access restores
**Expected Result**: Account lockout protects against brute force
**Priority**: High

### TC-P6-019: Account Lockout - Lockout Notification
**Objective**: Verify user notified of account lockout
**Prerequisites**: Account lockout triggered
**Steps**:
1. Trigger account lockout condition
2. Verify lockout notification sent to user
3. Check notification includes:
   - Lockout reason
   - Lockout duration
   - Security recommendations
   - Support contact information
**Expected Result**: User properly notified of security lockout
**Priority**: Medium

### TC-P6-020: Password History - Prevent Reuse
**Objective**: Verify users cannot reuse recent passwords
**Prerequisites**: User with password history
**Steps**:
1. Change user password multiple times
2. Attempt to reuse previous password
3. Verify password reuse rejected
4. Check error message explains policy
5. Confirm password history maintained (last 5)
**Expected Result**: Password reuse prevented per security policy
**Priority**: Medium

---

## INTEGRATION TESTING SCENARIOS

### IT-001: Complete Authentication Flow
**Objective**: Verify end-to-end authentication workflow
**Steps**:
1. Register new user account
2. Verify email address
3. Login with email/password
4. Setup and enable MFA
5. Logout and re-login with MFA
6. Access protected resources
7. Refresh tokens
8. Logout securely
**Expected Result**: Complete authentication lifecycle works seamlessly

### IT-002: OAuth + MFA Integration
**Objective**: Verify OAuth accounts can use MFA
**Steps**:
1. Register via Google OAuth
2. Setup MFA for OAuth account
3. Logout and re-login via OAuth
4. Verify MFA required for OAuth login
5. Complete MFA verification
**Expected Result**: OAuth and MFA work together correctly

### IT-003: Account Linking Scenarios
**Objective**: Verify multiple authentication methods work together
**Steps**:
1. Register with email/password
2. Enable MFA
3. Link Google OAuth account
4. Link GitHub OAuth account
5. Test login with all methods
6. Verify consistent user profile
**Expected Result**: Multiple auth methods linked to single account

### IT-004: Admin Management Integration
**Objective**: Verify CLI admin tools work with all user types
**Steps**:
1. Create users via different registration methods
2. Use CLI to promote/demote users
3. Revoke sessions for various user types
4. Verify admin actions affect all user types
**Expected Result**: CLI tools work regardless of registration method

### IT-005: Security Hardening Integration
**Objective**: Verify all security measures work together
**Steps**:
1. Test CSRF protection on all endpoints
2. Verify rate limiting across user actions
3. Check security headers on all responses
4. Test input validation on all forms
5. Verify audit logging captures all events
**Expected Result**: Comprehensive security coverage

---

## PERFORMANCE TESTING SCENARIOS

### PT-001: Authentication Endpoint Load
**Objective**: Verify authentication endpoints handle concurrent users
**Test Parameters**:
- Concurrent Users: 100
- Test Duration: 5 minutes
- Actions: Login, refresh, logout
**Success Criteria**:
- Response time < 500ms (95th percentile)
- No authentication failures
- Database connections stable

### PT-002: OAuth Flow Performance
**Objective**: Verify OAuth flows perform under load
**Test Parameters**:
- Concurrent OAuth flows: 50
- Providers: Google and GitHub
**Success Criteria**:
- OAuth callback processing < 2 seconds
- No dropped OAuth sessions
- Proper error handling

### PT-003: MFA Performance Testing
**Objective**: Verify MFA operations perform adequately
**Test Parameters**:
- TOTP verifications: 200/minute
- QR code generations: 50/minute
**Success Criteria**:
- TOTP verification < 200ms
- QR generation < 1 second
- No false negatives

---

## SECURITY TESTING SCENARIOS

### ST-001: JWT Token Security
**Objective**: Verify JWT implementation is secure
**Test Cases**:
- Token signature validation
- Token expiration enforcement
- Token payload integrity
- Algorithm confusion attacks
**Success Criteria**: All attacks properly mitigated

### ST-002: OAuth Security Testing
**Objective**: Verify OAuth implementation security
**Test Cases**:
- State parameter validation
- Redirect URI validation
- Authorization code reuse
- Cross-site request forgery
**Success Criteria**: OAuth vulnerabilities properly addressed

### ST-003: Input Validation Security
**Objective**: Verify comprehensive input validation
**Test Cases**:
- SQL injection attempts
- XSS payload injection
- Command injection
- Path traversal attacks
**Success Criteria**: All injection attacks blocked

---

## COMPATIBILITY TESTING

### CT-001: Browser Compatibility
**Objective**: Verify authentication works across browsers
**Test Browsers**: Chrome, Firefox, Safari, Edge
**Test Areas**:
- Cookie handling
- OAuth redirects
- JavaScript execution
- Local storage usage

### CT-002: Mobile Compatibility
**Objective**: Verify mobile authentication experience
**Test Devices**: iOS Safari, Android Chrome
**Test Areas**:
- Touch interface compatibility
- OAuth app switching
- MFA QR code scanning
- Responsive design

---

## REGRESSION TESTING CHECKLIST

### Phase 1 Regression
- [ ] User registration validates email format
- [ ] Password strength requirements enforced
- [ ] JWT tokens issued correctly
- [ ] Refresh token rotation works
- [ ] Protected routes secured

### Phase 2 Regression
- [ ] Security headers present
- [ ] CSRF protection active
- [ ] Rate limiting functional
- [ ] Input validation working
- [ ] Error handling secure

### Phase 3 Regression
- [ ] MFA setup generates QR codes
- [ ] TOTP verification works
- [ ] Backup codes functional
- [ ] MFA required for protected access
- [ ] MFA can be disabled

### Phase 4 Regression
- [ ] Google OAuth flow complete
- [ ] GitHub OAuth flow complete
- [ ] Account linking works
- [ ] OAuth session management
- [ ] Multiple provider support

### Phase 5 Regression
- [ ] CLI tool executes
- [ ] User promotion/demotion
- [ ] Session revocation works
- [ ] User listing accurate
- [ ] Database operations successful

### Phase 6 Regression
- [ ] Password reset flow complete
- [ ] Email verification works
- [ ] Audit logging captures events
- [ ] Account lockout functional
- [ ] Password history enforced

---

## TEST DATA MANAGEMENT

### Test User Accounts
```
Regular User:
- Email: testuser@example.com
- Password: SecurePass123!
- MFA: Disabled initially

Admin User:
- Email: admin@example.com  
- Password: AdminPass123!
- Role: Administrator
- MFA: Enabled

OAuth Test Users:
- Google: Use test Google account
- GitHub: Use test GitHub account
- Ensure same email for linking tests
```

### Test Environment Setup
```bash
# Database setup
npm run db:migrate
npm run db:seed

# Environment variables
NODE_ENV=test
JWT_SECRET=test-secret-key
DATABASE_URL=sqlite:memory:
GOOGLE_CLIENT_ID=test-client-id
GITHUB_CLIENT_ID=test-client-id

# Server startup
npm start
```

### Test Data Cleanup
```bash
# Reset database between test suites
npm run db:reset

# Clear Redis cache if used
redis-cli FLUSHALL

# Reset rate limiting counters
# Clear audit logs if needed
```

---

## DEFECT TRACKING TEMPLATE

### Defect Report Format
```
Defect ID: DEF-YYYY-MM-DD-001
Phase: [1-6]
Test Case: TC-P#-###
Severity: Critical/High/Medium/Low
Priority: P1/P2/P3/P4

Summary: Brief description of issue

Steps to Reproduce:
1. Step one
2. Step two
3. Step three

Expected Result: What should happen
Actual Result: What actually happened

Environment:
- OS: Windows/Linux/macOS
- Browser: Chrome/Firefox/Safari
- Node.js Version: x.x.x
- Database: PostgreSQL/SQLite

Additional Information:
- Screenshots/logs if applicable
- Error messages
- Stack traces
```

---

## DEPLOYMENT VERIFICATION

### Pre-Deployment Checklist
- [ ] All critical test cases pass
- [ ] Security tests completed
- [ ] Performance benchmarks met
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] SSL certificates valid
- [ ] Monitoring configured
- [ ] Backup procedures verified

### Post-Deployment Verification
- [ ] Health check endpoints respond
- [ ] Authentication flows work in production
- [ ] OAuth providers configured correctly
- [ ] Database connections stable
- [ ] Logging and monitoring active
- [ ] Performance metrics within range
- [ ] Security headers present
- [ ] Rate limiting functional

---

## MAINTENANCE PROCEDURES

### Regular Security Audits
- Weekly: Review failed authentication attempts
- Monthly: Analyze audit logs for anomalies
- Quarterly: Update dependencies and security patches
- Annually: Comprehensive security penetration testing

### Database Maintenance
- Daily: Monitor database performance
- Weekly: Clean up expired tokens
- Monthly: Optimize database queries
- Quarterly: Review and archive audit logs

### Documentation Updates
- Update test cases when features change
- Maintain environment setup procedures
- Document known issues and workarounds
- Keep security procedures current

---

## APPENDICES

### Appendix A: API Endpoint Reference
```
Authentication Endpoints:
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/refresh
GET    /api/auth/protected

MFA Endpoints:
GET    /api/auth/mfa/setup
POST   /api/auth/mfa/enable
POST   /api/auth/mfa/disable
POST   /api/auth/mfa/verify
GET    /api/auth/mfa/status

OAuth Endpoints:
GET    /auth/google
GET    /auth/google/callback
GET    /auth/github
GET    /auth/github/callback

Password Reset Endpoints:
POST   /api/auth/password-reset/request
GET    /api/auth/password-reset/validate/:token
POST   /api/auth/password-reset/complete

Email Verification Endpoints:
GET    /api/auth/email/verify/:token
POST   /api/auth/email/resend-verification
```

### Appendix B: Error Code Reference
```
400 - Bad Request (validation errors)
401 - Unauthorized (authentication required)
403 - Forbidden (access denied)
404 - Not Found (resource not found)
409 - Conflict (duplicate resource)
429 - Too Many Requests (rate limited)
500 - Internal Server Error (system error)
```

### Appendix C: CLI Command Reference
```
node auth-admin-cli.js list-users [--admin-only] [--mfa-enabled]
node auth-admin-cli.js promote <email>
node auth-admin-cli.js demote <email>
node auth-admin-cli.js revoke-sessions <email>
node auth-admin-cli.js --help
```

---

## DOCUMENT CONTROL

**Document Version**: 1.0  
**Last Updated**: September 7, 2025  
**Next Review Date**: October 7, 2025  
**Approved By**: Development Team Lead  
**Distribution**: QA Team, Development Team, DevOps Team

---

*This master test plan serves as the comprehensive testing guide for the authentication system. All test cases should be executed as part of the quality assurance process before deployment. Regular updates to this document ensure continued accuracy and relevance.*
