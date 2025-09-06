// src/auth/oauthControllers.js
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const argon2 = require('argon2');
const { RefreshToken } = require('../models');

const ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET || 'dev-access-secret';
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || 'dev-refresh-secret';
const ACCESS_TOKEN_EXPIRES_IN = '15m';
const REFRESH_TOKEN_EXPIRES_IN = '7d';

function signAccessToken(user) {
  return jwt.sign({
    sub: user.id,
    email: user.email,
    role: user.role,
  }, ACCESS_TOKEN_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRES_IN });
}

function signRefreshToken(user, tokenId) {
  return jwt.sign({
    sub: user.id,
    jti: tokenId,
  }, REFRESH_TOKEN_SECRET, { expiresIn: REFRESH_TOKEN_EXPIRES_IN });
}

// Handle OAuth callback success
async function handleOAuthSuccess(req, res) {
  try {
    const user = req.user;
    
    if (!user) {
      return res.status(401).json({ error: 'OAuth authentication failed' });
    }

    // Create refresh token (same as regular login)
    const tokenId = crypto.randomUUID();
    const refreshToken = signRefreshToken(user, tokenId);
    
    await RefreshToken.create({
      userId: user.id,
      tokenId,
      tokenHash: await argon2.hash(refreshToken),
      revoked: false,
    });

    // Set refresh token cookie
    res.cookie('refresh_token', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    });

    // For OAuth, we'll redirect to frontend with access token
    // In production, you'd redirect to your frontend app
    const accessToken = signAccessToken(user);
    
    // For testing, return JSON response
    res.json({
      success: true,
      message: 'OAuth login successful',
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('OAuth success handler error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

// Handle OAuth failure
function handleOAuthFailure(req, res) {
  res.status(401).json({ 
    error: 'OAuth authentication failed',
    message: 'Unable to authenticate with OAuth provider',
  });
}

module.exports = {
  handleOAuthSuccess,
  handleOAuthFailure,
};
