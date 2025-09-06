// src/auth/index.js
const express = require('express');
const { setupAuthMiddleware } = require('./middleware');
const authRoutes = require('./routes');

function mountAuth(app) {
  setupAuthMiddleware(app);
  app.use('/auth', authRoutes);
}

module.exports = { mountAuth };
