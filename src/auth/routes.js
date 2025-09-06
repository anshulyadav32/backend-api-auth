// src/auth/routes.js
const express = require('express');
const router = express.Router();
const { register, login, refresh, logout } = require('./controllers');
const { setupMfa, enableMfa, verifyMfa, disableMfa } = require('./mfa');
const { loginLimiter, csrfProtection } = require('./security');
const { handleOAuthSuccess, handleOAuthFailure } = require('./oauthControllers');
const passport = require('./passport');

// Basic auth routes
router.post('/register', register);
router.post('/login', loginLimiter, login);
router.post('/refresh', csrfProtection, refresh);
router.post('/logout', csrfProtection, logout);

// MFA routes
router.post('/mfa/setup', csrfProtection, setupMfa);
router.post('/mfa/enable', csrfProtection, enableMfa);
router.post('/mfa/verify', verifyMfa);
router.post('/mfa/disable', csrfProtection, disableMfa);

// OAuth routes
// Google OAuth
router.get('/oauth/google', 
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

router.get('/oauth/google/callback',
  passport.authenticate('google', { failureRedirect: '/auth/oauth/failure' }),
  handleOAuthSuccess
);

// GitHub OAuth
router.get('/oauth/github',
  passport.authenticate('github', { scope: ['user:email'] })
);

router.get('/oauth/github/callback',
  passport.authenticate('github', { failureRedirect: '/auth/oauth/failure' }),
  handleOAuthSuccess
);

// OAuth failure handler
router.get('/oauth/failure', handleOAuthFailure);

module.exports = router;
