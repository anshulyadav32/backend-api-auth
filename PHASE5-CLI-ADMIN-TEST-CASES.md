# 🧪 Phase 5 – CLI Admin Tool Test Cases

| **Test Case ID** | **Description**           | **Steps**                                                                                                                                                                                | **Expected Result**                                                                                                   | **Checkpoint**                        |
| ---------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| **TC-5.1**       | List Users                | 1. Run `auth-admin list-users --limit 5`.<br>2. Observe console output.                                                                                                                  | Displays up to 5 most recent users with `id, email, username, role, mfa`.                                             | CLI can query & list users.           |
| **TC-5.2**       | Promote User to Admin     | 1. Run `auth-admin promote --email alice@example.com`.<br>2. Query DB `SELECT role FROM users WHERE email='alice@example.com';`.                                                         | CLI outputs: `Promoted alice@example.com to admin`.<br>DB shows role=`admin`.                                         | Promotion works, permissions updated. |
| **TC-5.3**       | Demote Admin to User      | 1. Run `auth-admin demote --email alice@example.com`.<br>2. Query DB.                                                                                                                    | CLI outputs: `Demoted alice@example.com to user`.<br>DB shows role=`user`.                                            | Demotion works.                       |
| **TC-5.4**       | Revoke All Sessions       | 1. Login as `alice@example.com` and store refresh token cookie.<br>2. Run `auth-admin revoke-sessions --email alice@example.com`.<br>3. Try calling `/auth/refresh` with cookie.         | CLI outputs: `Revoked X refresh tokens for alice@example.com`.<br>Refresh request fails with `401 Invalid refresh`.   | All sessions revoked.                 |
| **TC-5.5**       | Disable User (Soft Block) | 1. Run `auth-admin disable-user --email alice@example.com`.<br>2. Query DB to confirm sessions revoked.                                                                                  | CLI outputs: `Disabled alice@example.com (sessions revoked)`.<br>User cannot login or refresh.                        | User effectively blocked.             |
| **TC-5.6**       | Reset Password            | 1. Run `auth-admin set-password --email alice@example.com --password "NewPass#123"`. <br>2. Try logging in with old password → fails.<br>3. Try logging in with new password → succeeds. | CLI outputs: `Password updated and sessions revoked for alice@example.com`.<br>Old creds invalid.<br>New creds valid. | Password reset works securely.        |

---

# 🔎 DB Validation Queries

Run after each test to confirm changes:

```sql
-- Check user role
SELECT email, role FROM users WHERE email='alice@example.com';

-- Check if refresh tokens revoked
SELECT id, revoked FROM refresh_tokens WHERE userId='<user-uuid>';

-- Confirm password hash updated
SELECT passwordHash FROM users WHERE email='alice@example.com';
```

---

# ✅ Phase 5 Complete If:

* TC-5.1: List users works.
* TC-5.2 / TC-5.3: Promote/Demote updates role in DB.
* TC-5.4: Revoking sessions invalidates refresh tokens.
* TC-5.5: Disable user blocks further access.
* TC-5.6: Reset password works and revokes sessions.

---

## 🎯 CLI Admin Tool Architecture

### Commands Specification:
- `auth-admin list-users [--limit N]` - List users with pagination
- `auth-admin promote --email <email>` - Promote user to admin role
- `auth-admin demote --email <email>` - Demote admin to user role
- `auth-admin revoke-sessions --email <email>` - Revoke all refresh tokens
- `auth-admin disable-user --email <email>` - Disable user account (soft block)
- `auth-admin set-password --email <email> --password <password>` - Reset password

### Security Requirements:
- CLI tool must validate admin permissions before executing commands
- All operations should log to audit trail
- Password operations must hash with argon2
- Session revocation must invalidate all refresh tokens
- User disable should prevent login without deleting account data

### Error Handling:
- User not found: Clear error message
- Invalid permissions: Access denied message
- Database errors: Graceful failure with error logging
- Invalid arguments: Help text display

---

## 📋 Implementation Checklist

- [ ] Create `auth-admin.js` CLI script with commander.js
- [ ] Implement user listing with pagination
- [ ] Implement promote/demote role management
- [ ] Implement session revocation functionality
- [ ] Implement user disable/enable functionality
- [ ] Implement secure password reset
- [ ] Add comprehensive error handling
- [ ] Add audit logging for all operations
- [ ] Create automated test script (test-phase5.sh)
- [ ] Validate all test cases pass
