const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

/**
 * Secure Logging Utility
 */
class SecureLogger {
  constructor() {
    this.logDir = path.join(__dirname, '../logs');
    this.ensureLogDirectory();
    this.sensitivePatterns = [
      /password['":\s]*[=:]\s*['"]?([^'"}\n]+)/gi,
      /secret['":\s]*[=:]\s*['"]?([^'"}\n]+)/gi,
      /token['":\s]*[=:]\s*['"]?([^'"}\n]+)/gi,
      /api[_-]?key['":\s]*[=:]\s*['"]?([^'"}\n]+)/gi,
      /authorization['":\s]*[=:]\s*['"]?([^'"}\n]+)/gi,
      /bearer\s+([a-z0-9.]+)/gi,
      /mongodb[+]?srv[=:]+([^\s]+)/gi,
      /\b(?:\d{4}[- ]?){3}\d{4}\b/g, // Credit card numbers
      /\b\d{3}-\d{2}-\d{4}\b/g, // SSN
      /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g, // Email addresses
    ];
  }

  ensureLogDirectory() {
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
  }

  sanitize(text) {
    if (typeof text !== 'string' || process.env.LOG_SENSITIVE_DATA === 'true') {
      return text;
    }

    let sanitized = text;
    this.sensitivePatterns.forEach((pattern) => {
      sanitized = sanitized.replace(pattern, '[REDACTED]');
    });

    return sanitized;
  }

  formatLog(level, message, meta = {}) {
    return {
      timestamp: new Date().toISOString(),
      level,
      message: this.sanitize(message),
      meta: this.sanitizeObject(meta),
      nodeEnv: process.env.NODE_ENV,
      processId: process.pid,
    };
  }

  sanitizeObject(obj) {
    if (!obj || typeof obj !== 'object') {
      return obj;
    }

    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string') {
        sanitized[key] = this.sanitize(value);
      } else if (typeof value === 'object') {
        sanitized[key] = this.sanitizeObject(value);
      } else {
        sanitized[key] = value;
      }
    }
    return sanitized;
  }

  log(level, message, meta = {}) {
    const logEntry = this.formatLog(level, message, meta);

    // Console output
    const prefix = `[${logEntry.timestamp}] [${level}]`;
    if (level === 'error') {
      console.error(prefix, message, this.sanitizeObject(meta));
    } else if (level === 'warn') {
      console.warn(prefix, message, this.sanitizeObject(meta));
    } else if (level === 'info') {
      console.log(prefix, message, this.sanitizeObject(meta));
    } else if (level === 'debug' && process.env.LOG_LEVEL === 'debug') {
      console.log(prefix, message, this.sanitizeObject(meta));
    }

    // File output
    this.writeToFile(logEntry);
  }

  writeToFile(logEntry) {
    const fileName = `${logEntry.level}-${new Date().toISOString().split('T')[0]}.log`;
    const filePath = path.join(this.logDir, fileName);

    const logLine = JSON.stringify(logEntry) + '\n';
    fs.appendFileSync(filePath, logLine, (err) => {
      if (err && process.env.NODE_ENV !== 'test') {
        console.error('Failed to write to log file:', err);
      }
    });
  }

  error(message, meta) {
    this.log('error', message, meta);
  }

  warn(message, meta) {
    this.log('warn', message, meta);
  }

  info(message, meta) {
    this.log('info', message, meta);
  }

  debug(message, meta) {
    this.log('debug', message, meta);
  }

  logRequest(req) {
    const requestMeta = {
      method: req.method,
      path: req.path,
      ip: req.ip,
      userAgent: req.get('user-agent'),
      userId: req.user?.userId || 'anonymous',
    };

    if (process.env.LOG_REQUEST_BODY === 'true' && req.body) {
      requestMeta.body = this.sanitizeObject(req.body);
    }

    this.info('Incoming request', requestMeta);
  }

  logResponse(req, res, duration) {
    const responseMeta = {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userId: req.user?.userId || 'anonymous',
    };

    this.info('Response sent', responseMeta);
  }

  logError(error, req = null) {
    const errorMeta = {
      message: error.message,
      code: error.code,
      stack: error.stack?.split('\n').slice(0, 5).join(' | '),
    };

    if (req) {
      errorMeta.method = req.method;
      errorMeta.path = req.path;
      errorMeta.userId = req.user?.userId || 'anonymous';
    }

    this.error('Error occurred', errorMeta);
  }

  logSecurityEvent(eventType, details) {
    const securityMeta = {
      eventType,
      details: this.sanitizeObject(details),
      timestamp: new Date().toISOString(),
    };

    // Always log security events
    const fileName = `security-${new Date().toISOString().split('T')[0]}.log`;
    const filePath = path.join(this.logDir, fileName);
    const logLine = JSON.stringify(securityMeta) + '\n';

    fs.appendFileSync(filePath, logLine, (err) => {
      if (err && process.env.NODE_ENV !== 'test') {
        console.error('Failed to write security log:', err);
      }
    });

    this.warn(`Security event: ${eventType}`, details);
  }
}

/**
 * Custom Error Class
 */
class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.timestamp = new Date().toISOString();
  }
}

/**
 * Global Error Handler Middleware
 */
const errorHandler = (logger) => {
  return (err, req, res, next) => {
    const isDevelopment = process.env.NODE_ENV !== 'production';

    // Log the error
    logger.logError(err, req);

    // Log security event if suspicious
    if (err.statusCode === 401 || err.statusCode === 403) {
      logger.logSecurityEvent('unauthorized_access', {
        path: req.path,
        method: req.method,
        userId: req.user?.userId || 'anonymous',
        ip: req.ip,
      });
    }

    // Format error response
    const errorResponse = {
      success: false,
      error: {
        message: err.message || 'Internal server error',
        code: err.code || 'INTERNAL_ERROR',
        statusCode: err.statusCode || 500,
      },
    };

    // Include stack trace only in development
    if (isDevelopment) {
      errorResponse.error.stack = err.stack;
    }

    // Send response
    res.status(err.statusCode || 500).json(errorResponse);
  };
};

/**
 * Request Logging Middleware
 */
const requestLogger = (logger) => {
  return (req, res, next) => {
    const startTime = Date.now();

    // Log incoming request
    logger.logRequest(req);

    // Intercept response finish
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      logger.logResponse(req, res, duration);
    });

    next();
  };
};

/**
 * Encryption Utilities
 */
class EncryptionService {
  constructor() {
    this.algorithm = process.env.ENCRYPTION_ALGORITHM || 'aes-256-gcm';
    // Ensure keys are proper length
    this.encryptionKey = Buffer.from(
      process.env.ENCRYPTION_KEY || 'CHANGE_ME_GENERATE_KEY_32_BYTES'.padEnd(32, '0'),
      'utf8'
    ).slice(0, 32); // Ensure 32 bytes for AES-256
  }

  encrypt(text) {
    if (!text) return null;

    try {
      const iv = crypto.randomBytes(16);
      const cipher = crypto.createCipheriv(this.algorithm, this.encryptionKey, iv);

      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      const authTag = cipher.getAuthTag();

      return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
    } catch (error) {
      console.error('Encryption error:', error);
      return text; // Fallback to plaintext if encryption fails
    }
  }

  decrypt(encryptedText) {
    if (!encryptedText || !encryptedText.includes(':')) return null;

    try {
      const [ivHex, authTagHex, encrypted] = encryptedText.split(':');
      const iv = Buffer.from(ivHex, 'hex');
      const authTag = Buffer.from(authTagHex, 'hex');

      const decipher = crypto.createDecipheriv(this.algorithm, this.encryptionKey, iv);
      decipher.setAuthTag(authTag);

      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return decrypted;
    } catch (error) {
      console.error('Decryption error:', error);
      return encryptedText; // Return encrypted text if decryption fails
    }
  }

  hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
  }

  generateSecureToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
  }
}

module.exports = {
  SecureLogger,
  AppError,
  errorHandler,
  requestLogger,
  EncryptionService,
};
