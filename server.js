// server.js
console.log('Starting authentication server...');

const express = require('express');
const path = require('path');
console.log('Express loaded');

const { mountAuth } = require('./src/auth');
console.log('Auth module loaded');

const { sequelize } = require('./src/models');
console.log('Models loaded');

const { setupSecurityMiddleware, setupErrorHandling } = require('./src/auth/security');
console.log('Security module loaded');

const app = express();

// Security middleware first
setupSecurityMiddleware(app);
console.log('Security middleware configured');

app.use(express.json());
console.log('Body parser configured');

// Serve static files (for OAuth test page)
app.use(express.static(path.join(__dirname, '.')));

// Add health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Serve OAuth test page
app.get('/oauth-test', (req, res) => {
  res.sendFile(path.join(__dirname, 'oauth-test.html'));
});

mountAuth(app);
console.log('Auth routes mounted');

// Error handling last
setupErrorHandling(app);
console.log('Error handling configured');

const PORT = process.env.PORT || 8080;

sequelize.sync()
  .then(() => {
    console.log('Database synced successfully');
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.error('Error starting server:', err);
  });
