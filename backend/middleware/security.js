const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const hpp = require('hpp');

/**
 * Security Headers Middleware using Helmet
 */
const helmetConfig = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      fontSrc: ["'self'", 'data:', 'https:'],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: process.env.NODE_ENV === 'production' ? [] : null,
    },
  },
  frameguard: {
    action: 'deny',
  },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: {
    policy: 'strict-origin-when-cross-origin',
  },
  hsts: {
    maxAge: 31536000, // 1 year in seconds
    includeSubDomains: true,
    preload: true,
  },
  permittedCrossDomainPolicies: false,
});

/**
 * CORS Middleware with strict configuration
 */
const corsConfig = {
  origin: function (origin, callback) {
    // Parse allowed origins and trim whitespace
    const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
      .split(',')
      .map(o => o.trim());
    
    // Allow requests with no origin (like mobile apps or curl requests)
    // Also allow if origin exactly matches or matches without trailing slash
    if (!origin) {
      callback(null, true);
    } else if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else if (allowedOrigins.includes(origin.replace(/\/$/, ''))) {
      // Allow if origin matches without trailing slash
      callback(null, true);
    } else if (process.env.NODE_ENV === 'development') {
      // In development, be more lenient with localhost origins
      const isLocalhost = origin.includes('localhost') || origin.includes('127.0.0.1');
      if (isLocalhost) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-User-ID'],
  maxAge: 86400, // 24 hours
  optionsSuccessStatus: 200,
};

/**
 * Rate Limiting Middlewares
 */
const createLimiter = (windowMs, maxRequests, message) => {
  return rateLimit({
    windowMs,
    max: maxRequests,
    message,
    standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
    legacyHeaders: false,
    skip: (req) => {
      // Skip rate limiting for health checks
      return req.path === '/health';
    },
    keyGenerator: (req) => {
      // Use IP address and user ID for rate limiting
      return `${req.ip}-${req.user?.userId || 'anonymous'}`;
    },
    handler: (req, res) => {
      res.status(429).json({
        success: false,
        error: 'Too many requests, please try again later.',
        retryAfter: req.rateLimit.resetTime,
      });
    },
  });
};

// General API rate limiter
const apiLimiter = createLimiter(
  parseInt(process.env.RATE_LIMIT_WINDOW_MS || 900000), // 15 minutes
  parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || 100),
  'Too many requests from this IP, please try again later.'
);

// Authentication endpoints rate limiter
const authLimiter = createLimiter(
  parseInt(process.env.RATE_LIMIT_WINDOW_MS || 900000), // 15 minutes
  parseInt(process.env.RATE_LIMIT_AUTH_MAX_REQUESTS || 50),
  'Too many authentication attempts, please try again later.'
);

// Strict rate limiter for sensitive endpoints
const strictLimiter = createLimiter(
  parseInt(process.env.RATE_LIMIT_WINDOW_MS || 900000), // 15 minutes
  parseInt(process.env.RATE_LIMIT_STRICT_MAX_REQUESTS || 5),
  'Too many requests to this endpoint, please try again later.'
);

/**
 * Data Sanitization Middlewares
 */
const dataSanitization = [
  mongoSanitize(), // Data sanitization against NoSQL injection
  xss(), // Clean data from XSS attacks
  hpp(), // Prevent HTTP Parameter Pollution
];

/**
 * Request Validation Middleware
 */
const validateRequest = (req, res, next) => {
  const contentType = req.get('content-type');
  
  if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
    if (!contentType || !contentType.includes('application/json')) {
      return res.status(400).json({
        success: false,
        error: 'Content-Type must be application/json',
      });
    }
  }
  
  // Validate JSON body size
  const maxSize = process.env.MAX_REQUEST_SIZE || '10mb';
  req.on('data', (chunk) => {
    if (req.headers['content-length'] > parseInt(maxSize)) {
      return res.status(413).json({
        success: false,
        error: 'Payload too large',
      });
    }
  });
  
  next();
};

/**
 * Security Headers Middleware (custom additions)
 */
const securityHeaders = (req, res, next) => {
  // Prevent MIME type sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // Enable XSS protection
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');
  
  // Referrer Policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Permissions Policy
  res.setHeader(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=(), payment=()'
  );
  
  // Remove Express signature
  res.removeHeader('X-Powered-By');
  
  // Disable caching for sensitive responses
  if (req.path.includes('auth') || req.path.includes('profile')) {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }
  
  next();
};

module.exports = {
  helmetConfig,
  corsConfig,
  apiLimiter,
  authLimiter,
  strictLimiter,
  dataSanitization,
  validateRequest,
  securityHeaders,
};
