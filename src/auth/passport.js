// src/auth/passport.js
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const GitHubStrategy = require('passport-github2').Strategy;
const { User, OAuthAccount } = require('../models');
const crypto = require('crypto');

// OAuth configuration from environment
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || 'your-google-client-id';
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || 'your-google-client-secret';
const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID || 'your-github-client-id';
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET || 'your-github-client-secret';
const BASE_URL = process.env.BASE_URL || 'http://localhost:8080';

// Serialize user for session
passport.serializeUser((user, done) => {
  done(null, user.id);
});

// Deserialize user from session
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findByPk(id);
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

// Google OAuth Strategy
passport.use(new GoogleStrategy({
  clientID: GOOGLE_CLIENT_ID,
  clientSecret: GOOGLE_CLIENT_SECRET,
  callbackURL: `${BASE_URL}/auth/oauth/google/callback`,
}, async (accessToken, refreshToken, profile, done) => {
  try {
    console.log('Google OAuth profile:', profile);
    
    // Check if OAuth account already exists
    let oauthAccount = await OAuthAccount.findOne({
      where: {
        provider: 'google',
        providerUserId: profile.id,
      },
      include: [User],
    });

    if (oauthAccount) {
      // OAuth account exists, return the linked user
      return done(null, oauthAccount.User);
    }

    // Check if user exists by email (for account linking)
    const email = profile.emails && profile.emails[0] ? profile.emails[0].value : null;
    let user = null;

    if (email) {
      user = await User.findOne({ where: { email } });
    }

    if (!user) {
      // Create new user
      const username = `google_${profile.id}`;
      const randomPassword = crypto.randomBytes(32).toString('hex');
      const argon2 = require('argon2');
      const passwordHash = await argon2.hash(randomPassword);

      user = await User.create({
        email: email || `google_${profile.id}@oauth.local`,
        username: username,
        passwordHash: passwordHash,
        role: 'user',
      });
    }

    // Create OAuth account link
    await OAuthAccount.create({
      provider: 'google',
      providerUserId: profile.id,
      email: email,
      displayName: profile.displayName,
      profilePicture: profile.photos && profile.photos[0] ? profile.photos[0].value : null,
      userId: user.id,
    });

    return done(null, user);
  } catch (error) {
    console.error('Google OAuth error:', error);
    return done(error, null);
  }
}));

// GitHub OAuth Strategy
passport.use(new GitHubStrategy({
  clientID: GITHUB_CLIENT_ID,
  clientSecret: GITHUB_CLIENT_SECRET,
  callbackURL: `${BASE_URL}/auth/oauth/github/callback`,
}, async (accessToken, refreshToken, profile, done) => {
  try {
    console.log('GitHub OAuth profile:', profile);
    
    // Check if OAuth account already exists
    let oauthAccount = await OAuthAccount.findOne({
      where: {
        provider: 'github',
        providerUserId: profile.id,
      },
      include: [User],
    });

    if (oauthAccount) {
      // OAuth account exists, return the linked user
      return done(null, oauthAccount.User);
    }

    // Check if user exists by email (for account linking)
    const email = profile.emails && profile.emails[0] ? profile.emails[0].value : null;
    let user = null;

    if (email) {
      user = await User.findOne({ where: { email } });
    }

    if (!user) {
      // Create new user
      const username = profile.username || `github_${profile.id}`;
      const randomPassword = crypto.randomBytes(32).toString('hex');
      const argon2 = require('argon2');
      const passwordHash = await argon2.hash(randomPassword);

      user = await User.create({
        email: email || `github_${profile.id}@oauth.local`,
        username: username,
        passwordHash: passwordHash,
        role: 'user',
      });
    }

    // Create OAuth account link
    await OAuthAccount.create({
      provider: 'github',
      providerUserId: profile.id,
      email: email,
      displayName: profile.displayName || profile.username,
      profilePicture: profile.photos && profile.photos[0] ? profile.photos[0].value : null,
      userId: user.id,
    });

    return done(null, user);
  } catch (error) {
    console.error('GitHub OAuth error:', error);
    return done(error, null);
  }
}));

module.exports = passport;
