// src/auth/controllers.js
const { User, RefreshToken } = require('../../models');
const { z } = require('zod');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

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

const registerSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3),
  password: z.string().min(8),
});

async function register(req, res) {
  try {
    const { email, username, password } = registerSchema.parse(req.body);
    const exists = await User.findOne({ where: { email } });
    if (exists) return res.status(400).json({ error: 'Email already registered' });
    const passwordHash = await argon2.hash(password);
    const user = await User.create({ email, username, passwordHash, role: 'user' });
    res.status(201).json({ id: user.id, email: user.email, username: user.username });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

const loginSchema = z.object({
  emailOrUsername: z.string(),
  password: z.string(),
});

async function login(req, res) {
  try {
    const { emailOrUsername, password } = loginSchema.parse(req.body);
    const user = await User.findOne({
      where: {
        [User.sequelize.Op.or]: [
          { email: emailOrUsername },
          { username: emailOrUsername },
        ],
      },
    });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });
    // Create refresh token
    const tokenId = crypto.randomUUID();
    const refreshToken = signRefreshToken(user, tokenId);
    await RefreshToken.create({
      userId: user.id,
      tokenId,
      tokenHash: await argon2.hash(refreshToken),
      revoked: false,
    });
    res.cookie('refresh_token', refreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });
    res.json({ accessToken: signAccessToken(user) });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

async function refresh(req, res) {
  try {
    const token = req.cookies.refresh_token;
    if (!token) return res.status(401).json({ error: 'No refresh token' });
    let payload;
    try {
      payload = jwt.verify(token, REFRESH_TOKEN_SECRET);
    } catch {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }
    const dbToken = await RefreshToken.findOne({ where: { tokenId: payload.jti, userId: payload.sub } });
    if (!dbToken || dbToken.revoked) return res.status(401).json({ error: 'Token revoked' });
    const valid = await argon2.verify(dbToken.tokenHash, token);
    if (!valid) return res.status(401).json({ error: 'Token hash mismatch' });
    // Rotate: revoke old, issue new
    dbToken.revoked = true;
    await dbToken.save();
    const user = await User.findByPk(payload.sub);
    const newTokenId = crypto.randomUUID();
    const newRefreshToken = signRefreshToken(user, newTokenId);
    await RefreshToken.create({
      userId: user.id,
      tokenId: newTokenId,
      tokenHash: await argon2.hash(newRefreshToken),
      revoked: false,
    });
    res.cookie('refresh_token', newRefreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });
    res.json({ accessToken: signAccessToken(user) });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

async function logout(req, res) {
  try {
    const token = req.cookies.refresh_token;
    if (token) {
      let payload;
      try {
        payload = jwt.verify(token, REFRESH_TOKEN_SECRET);
      } catch {
        // ignore
      }
      if (payload) {
        const dbToken = await RefreshToken.findOne({ where: { tokenId: payload.jti, userId: payload.sub } });
        if (dbToken) {
          dbToken.revoked = true;
          await dbToken.save();
        }
      }
    }
    res.clearCookie('refresh_token');
    res.json({ success: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

module.exports = { register, login, refresh, logout };
