// src/auth/security.js
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const hpp = require('hpp');
const crypto = require('crypto');

// Rate limiting for login attempts
const loginLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 20, // limit each IP to 20 requests per windowMs
  message: {
    error: 'Too many login attempts, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// CORS configuration
const corsOptions = {
  origin: ['http://localhost:3000', 'http://localhost:8080'], // Add your frontend URLs
  credentials: true,
  optionsSuccessStatus: 200
};

// CSRF token generation and validation
function generateCSRFToken() {
  return crypto.randomBytes(32).toString('hex');
}

function csrfProtection(req, res, next) {
  if (req.method === 'GET') {
    return next();
  }

  const tokenFromHeader = req.headers['x-csrf-token'];
  const tokenFromCookie = req.cookies.csrf;

  if (!tokenFromHeader || !tokenFromCookie || tokenFromHeader !== tokenFromCookie) {
    return res.status(403).json({ error: 'CSRF check failed' });
  }

  next();
}

// Setup all security middleware
function setupSecurityMiddleware(app) {
  // Helmet for security headers
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
    referrerPolicy: { policy: 'no-referrer' }
  }));

  // Remove X-Powered-By header
  app.disable('x-powered-by');

  // CORS
  app.use(cors(corsOptions));

  // HTTP Parameter Pollution protection
  app.use(hpp());

  // CSRF token endpoint
  app.get('/auth/csrf', (req, res) => {
    const token = generateCSRFToken();
    res.cookie('csrf', token, {
      httpOnly: false, // Client needs to read this for header
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    });
    res.json({ csrfToken: token });
  });
}

// Error handling middleware
function setupErrorHandling(app) {
  // 404 handler
  app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
  });

  // Global error handler
  app.use((err, req, res, next) => {
    console.error('Error:', err);
    
    // Don't leak error details in production
    const message = process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : err.message;
    
    res.status(err.status || 500).json({ error: message });
  });
}

module.exports = {
  setupSecurityMiddleware,
  setupErrorHandling,
  loginLimiter,
  csrfProtection
};
