// ════════════════════════════════════════════════════════════════
// CENTRALIZED SECURITY MODULE INTEGRATION
// ════════════════════════════════════════════════════════════════

// Middleware modules
const encryption = require('../middleware/encryption');
const csrf = require('../middleware/csrf');
const auditLogger = require('../middleware/auditLogger');
const dataRedaction = require('../middleware/dataRedaction');
const secretsManager = require('../middleware/secretsManager');
const contentSecurityPolicy = require('../middleware/contentSecurityPolicy');

// Security core modules
const twoFactorAuth = require('./twoFactorAuth');
const ipWhitelist = require('./ipWhitelist');
const accountLockout = require('./accountLockout');
const passwordReset = require('./passwordReset');
const sessionManager = require('./sessionManager');
const dataEncryption = require('./dataEncryption');
const sqlInjectionPrevention = require('./sqlInjectionPrevention');
const vulnerabilityScanner = require('./vulnerabilityScanner');
const tokenBlacklist = require('./tokenBlacklist');
const permissionValidator = require('./permissionValidator');
const antiDDoS = require('./antiDDoS');
const apiKeyManager = require('./apiKeyManager');

class SecurityCore {
  constructor() {
    this.encryption = encryption;
    this.csrf = csrf;
    this.auditLogger = auditLogger;
    this.dataRedaction = dataRedaction;
    this.secretsManager = secretsManager;
    this.contentSecurityPolicy = contentSecurityPolicy;
    this.twoFactorAuth = twoFactorAuth;
    this.ipWhitelist = ipWhitelist;
    this.accountLockout = accountLockout;
    this.passwordReset = passwordReset;
    this.sessionManager = sessionManager;
    this.dataEncryption = dataEncryption;
    this.sqlInjectionPrevention = sqlInjectionPrevention;
    this.vulnerabilityScanner = vulnerabilityScanner;
    this.tokenBlacklist = tokenBlacklist;
    this.permissionValidator = permissionValidator;
    this.antiDDoS = antiDDoS;
    this.apiKeyManager = apiKeyManager;
  }

  // Comprehensive security validation middleware
  validateRequest(req, res, next) {
    // Check IP blocking
    if (this.antiDDoS.isIPBlocked(req.ip)) {
      return res.status(429).json({
        success: false,
        error: 'IP address blocked due to excessive requests',
      });
    }

    // Check for suspicious requests
    if (this.antiDDoS.checkIfSuspicious(req.ip)) {
      this.auditLogger.logSecurityEvent({
        eventType: 'SUSPICIOUS_ACTIVITY',
        action: 'DDoS_DETECTED',
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });
    }

    // Scan for vulnerabilities
    const bodyString = JSON.stringify(req.body || {});
    const scanResult = this.vulnerabilityScanner.scanInput(bodyString);

    if (scanResult.vulnerable) {
      this.auditLogger.logSecurityEvent({
        eventType: 'SECURITY_THREAT',
        action: 'MALICIOUS_INPUT_DETECTED',
        vulnerabilities: scanResult.vulnerabilities,
        ipAddress: req.ip,
        userId: req.user?.userId,
      });

      return res.status(400).json({
        success: false,
        error: 'Invalid request detected',
        code: 'INVALID_INPUT',
      });
    }

    // Check token blacklist
    const token = req.headers.authorization?.split(' ')[1];
    if (token && this.tokenBlacklist.isBlacklisted(token)) {
      return res.status(401).json({
        success: false,
        error: 'Token has been revoked',
      });
    }

    next();
  }

  // Middleware to require 2FA
  require2FA(req, res, next) {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
      });
    }

    if (!this.twoFactorAuth.isEnabled(req.user.userId)) {
      return res.status(403).json({
        success: false,
        error: '2FA required for this operation',
        code: '2FA_REQUIRED',
      });
    }

    next();
  }

  // Middleware to verify IP whitelist
  requireWhitelistedIP(req, res, next) {
    if (process.env.ENABLE_IP_WHITELIST !== 'true') {
      return next();
    }

    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
      });
    }

    if (!this.ipWhitelist.isIPWhitelisted(req.user.userId, req.ip)) {
      this.auditLogger.logSecurityEvent({
        eventType: 'UNAUTHORIZED_IP',
        action: 'IP_NOT_WHITELISTED',
        userId: req.user.userId,
        ipAddress: req.ip,
      });

      return res.status(403).json({
        success: false,
        error: 'Access from this IP is not whitelisted',
      });
    }

    next();
  }

  // Middleware to check account lockout
  checkAccountLockout(req, res, next) {
    if (!req.user) {
      return next();
    }

    if (this.accountLockout.isAccountLocked(req.user.userId)) {
      const timeRemaining = this.accountLockout.getTimeUntilUnlock(
        req.user.userId
      );

      return res.status(403).json({
        success: false,
        error: 'Account is temporarily locked due to too many failed attempts',
        unlockTime: new Date(Date.now() + timeRemaining),
      });
    }

    next();
  }

  // Middleware to validate session
  validateSession(req, res, next) {
    const sessionId = req.cookies?.sessionId || req.headers['x-session-id'];

    if (!sessionId && !req.headers.authorization) {
      return next();
    }

    if (sessionId) {
      const validation = this.sessionManager.validateSession(sessionId);

      if (!validation.valid) {
        return res.status(401).json({
          success: false,
          error: validation.error,
        });
      }

      req.sessionId = sessionId;
    }

    next();
  }

  // Create all middleware
  createMiddleware() {
    return {
      validateRequest: this.validateRequest.bind(this),
      require2FA: this.require2FA.bind(this),
      requireWhitelistedIP: this.requireWhitelistedIP.bind(this),
      checkAccountLockout: this.checkAccountLockout.bind(this),
      validateSession: this.validateSession.bind(this),
    };
  }
}

module.exports = new SecurityCore();
