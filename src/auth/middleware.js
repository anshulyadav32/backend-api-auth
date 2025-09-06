// src/auth/middleware.js
const cookieParser = require('cookie-parser');
const express = require('express');
const session = require('express-session');
const passport = require('./passport');

function setupAuthMiddleware(app) {
  app.use(express.json());
  app.use(cookieParser());
  
  // Session configuration for OAuth
  app.use(session({
    secret: process.env.SESSION_SECRET || 'dev-session-secret',
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      maxAge: 1000 * 60 * 15, // 15 minutes for OAuth flow
    },
  }));
  
  // Initialize Passport
  app.use(passport.initialize());
  app.use(passport.session());
}

module.exports = { setupAuthMiddleware };
