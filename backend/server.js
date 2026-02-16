require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const https = require('https');
const fs = require('fs');

// Import routes
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profiles');
const databaseRoutes = require('./routes/database');
const matchingRoutes = require('./routes/matching');
const messagingRoutes = require('./routes/messaging');
const paymentRoutes = require('./routes/payments');
const verificationRoutes = require('./routes/verification');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');
const disputeRoutes = require('./routes/disputes');
const userRoutes = require('./routes/users');

// Import middleware
const { migrate } = require('./migrations/migrate');
const { connectMongo } = require('./mongo');
const { initializeFirebase } = require('./firebase');
const { getUnifiedDatabase } = require('./services/unifiedDatabase');
const { createTimestampParser } = require('./middleware/timestampParser');
const {
  helmetConfig,
  corsConfig,
  apiLimiter,
  authLimiter,
  securityHeaders,
  validateRequest,
  dataSanitization,
} = require('./middleware/security');
const {
  SecureLogger,
  errorHandler,
  requestLogger,
} = require('./middleware/errors');
const { responseFormatter } = require('./middleware/responseFormatter');
const encryption = require('./middleware/encryption');
const { csrfProtection } = require('./middleware/csrf');
const { requestSigningMiddleware } = require('./middleware/requestSigning');
const { dataRedactionMiddleware } = require('./middleware/dataRedaction');
const auditLogger = require('./middleware/auditLogger');
const csp = require('./middleware/contentSecurityPolicy');
const secretsManager = require('./middleware/secretsManager');
const securityCore = require('./security/securityCore');
const ipWhitelist = require('./security/ipWhitelist');
const accountLockout = require('./security/accountLockout');
const sessionManager = require('./security/sessionManager');

const app = express();
const PORT = process.env.PORT || 8080;

// ═════════════════════════════════════════════════════════════════
// SECURITY INITIALIZATION
// ═════════════════════════════════════════════════════════════════

// Initialize Logger
const logger = new SecureLogger();

// Verify secrets are loaded
try {
  secretsManager.validateSecretStrength(process.env.JWT_SECRET);
  logger.info('✅ Secrets manager initialized');
} catch (err) {
  logger.error('❌ Secret validation failed', { error: err.message });
  process.exit(1);
}

// Validate environment variables
const validateEnvironment = () => {
  const requiredEnvs = [
    'JWT_SECRET',
    'NODE_ENV',
  ];

  // Add DATABASE_URL requirement only for production
  if (process.env.NODE_ENV === 'production') {
    requiredEnvs.push('DATABASE_URL');
  }

  const missing = requiredEnvs.filter((env) => !process.env[env]);

  if (missing.length > 0) {
    logger.error('Missing required environment variables', { missing });
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }

  // Validate JWT secret strength
  if (
    process.env.NODE_ENV === 'production' &&
    process.env.JWT_SECRET.length < 32
  ) {
    logger.warn('JWT_SECRET is too short (min 32 chars)', {
      actual: process.env.JWT_SECRET?.length,
    });
  }
};

validateEnvironment();

// ═════════════════════════════════════════════════════════════════
// GLOBAL MIDDLEWARE
// ═════════════════════════════════════════════════════════════════

// Security headers
app.use(helmetConfig);
app.use(csp.cspMiddleware());

// ═════════════════════════════════════════════════════════════════
// HEALTH CHECK ENDPOINTS (before CORS to bypass restrictions)
// ═════════════════════════════════════════════════════════════════

// Health check endpoint (no auth required)
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production',
    uptime: process.uptime(),
  });
});

// Health check with detailed status (no auth required)
app.get('/health/detailed', (req, res) => {
  res.json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    database: {
      postgresql: process.env.DATABASE_URL ? 'configured' : 'not configured',
      mongodb: process.env.MONGO_URI ? 'configured' : 'not configured',
      firebase: process.env.FIREBASE_DATABASE_URL ? 'configured' : 'not configured',
    },
  });
});

// CORS
app.use(cors(corsConfig));

// Body parsing with size limits and custom Timestamp handling
app.use(createTimestampParser());
app.use(bodyParser.urlencoded({
  limit: process.env.MAX_REQUEST_SIZE || '10mb',
  extended: true,
  parameterLimit: 50,
}));

// Response formatter - standardize all responses
app.use(responseFormatter);

// Custom security headers
app.use(securityHeaders);

// Request validation
app.use(validateRequest);

// Data sanitization
app.use(...dataSanitization);

// Data redaction (hide sensitive info in responses)
app.use(dataRedactionMiddleware);

// Request logging with audit trail
app.use(requestLogger(logger));

// CSRF Protection for state-changing operations
// Note: CSRF protection is disabled in development mode for easier testing
// In production, enable CSRF and ensure clients obtain tokens from GET /api/csrf-token endpoint
app.use((req, res, next) => {
  if (process.env.NODE_ENV === 'production') {
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
      return csrfProtection(req, res, next);
    }
  }
  next();
});

// Core security validation
app.use(securityCore.validateRequest.bind(securityCore));

// Session validation
app.use(securityCore.validateSession.bind(securityCore));

// Check account lockout
app.use(securityCore.checkAccountLockout.bind(securityCore));

// Request signing verification
if (process.env.ENABLE_REQUEST_SIGNING === 'true') {
  app.use(requestSigningMiddleware);
}

// Rate limiting - Apply to all API routes
app.use('/api/', apiLimiter);

// ═════════════════════════════════════════════════════════════════
// ROUTES
// ═════════════════════════════════════════════════════════════════

// API routes
app.use('/api/auth', authRoutes);
app.use('/api', profileRoutes);
app.use('/api/database', databaseRoutes);
app.use('/api/matching', matchingRoutes);
app.use('/api/messaging', messagingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/disputes', disputeRoutes);
app.use('/api/users', userRoutes);

// ═════════════════════════════════════════════════════════════════
// ERROR HANDLING
// ═════════════════════════════════════════════════════════════════

// 404 handler
app.use((req, res) => {
  logger.warn('Route not found', {
    method: req.method,
    path: req.path,
  });

  res.status(404).json({
    success: false,
    error: {
      message: 'Route not found',
      code: 'NOT_FOUND',
      path: req.path,
    },
  });
});

// Global error handler
app.use(errorHandler(logger));

// ═════════════════════════════════════════════════════════════════
// SERVER STARTUP
// ═════════════════════════════════════════════════════════════════

async function startServer() {
  try {
    // Initialize MongoDB connection
    try {
      await connectMongo();
      logger.info('✅ MongoDB initialized');
    } catch (mongoError) {
      logger.warn('⚠️ MongoDB not available', { error: mongoError.message });
    }

    // Initialize Firebase connection
    try {
      await initializeFirebase();
      logger.info('✅ Firebase initialized');
    } catch (firebaseError) {
      logger.warn('⚠️ Firebase not available', { error: firebaseError.message });
    }

    // Initialize Unified Database Service
    const unifiedDb = getUnifiedDatabase();
    logger.info('✅ Unified Database Service initialized');

    // Run migrations
    await migrate();

    // Start server
    const server = app.listen(PORT, () => {
      logger.info('✅ SpaceShare Backend Server started', {
        port: PORT,
        environment: process.env.NODE_ENV,
        nodeVersion: process.version,
      });
    });

    // ═════════════════════════════════════════════════════════════════
    // SECURITY EVENT HANDLERS
    // ═════════════════════════════════════════════════════════════════

    // Graceful shutdown
    process.on('SIGTERM', () => {
      logger.info('SIGTERM signal received: closing HTTP server');
      server.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      logger.info('SIGINT signal received: closing HTTP server');
      server.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
      });
    });

    // Unhandled rejection handler
    process.on('unhandledRejection', (reason, promise) => {
      logger.logSecurityEvent('unhandled_rejection', {
        reason: String(reason),
        promise: String(promise),
      });
    });

    // Uncaught exception handler
    process.on('uncaughtException', (error) => {
      logger.logSecurityEvent('uncaught_exception', {
        message: error.message,
        stack: error.stack?.split('\n').slice(0, 5).join(' | '),
      });
      process.exit(1);
    });

    // ═════════════════════════════════════════════════════════════════
    // SECURITY MONITORING
    // ═════════════════════════════════════════════════════════════════

    // Log startup security status
    logger.logSecurityEvent('server_startup', {
      environment: process.env.NODE_ENV,
      corsEnabled: true,
      helmetEnabled: true,
      rateLimitingEnabled: true,
      dataValidationEnabled: true,
    });
  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
}

// Start the server
startServer();

module.exports = app;

