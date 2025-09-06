// src/auth/middleware.js
const cookieParser = require('cookie-parser');
const express = require('express');

function setupAuthMiddleware(app) {
  app.use(express.json());
  app.use(cookieParser());
}

module.exports = { setupAuthMiddleware };
