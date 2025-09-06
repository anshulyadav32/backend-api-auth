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

// Add index route with all endpoints
app.get('/', (req, res) => {
  res.json({
    "service": "Enterprise Authentication System",
    "version": "1.0.0",
    "endpoints": {
      "health": "/health",
      "authentication": {
        "register": "/auth/register",
        "login": "/auth/login",
        "logout": "/auth/logout",
        "refresh": "/auth/refresh",
        "profile": "/auth/profile"
      },
      "mfa": {
        "setup": "/auth/mfa/setup",
        "verify": "/auth/mfa/verify",
        "disable": "/auth/mfa/disable"
      },
      "oauth": {
        "google": "/auth/google",
        "google_callback": "/auth/google/callback",
        "github": "/auth/github",
        "github_callback": "/auth/github/callback",
        "link_google": "/auth/link/google",
        "link_github": "/auth/link/github"
      },
      "admin": {
        "users": "/auth/admin/users",
        "promote": "/auth/admin/promote",
        "demote": "/auth/admin/demote",
        "revoke_sessions": "/auth/admin/revoke-sessions"
      },
      "testing": {
        "oauth_test_page": "/oauth-test"
      }
    }
  });
});

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
