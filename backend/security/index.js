// ════════════════════════════════════════════════════════════════
// EXPORT ALL SECURITY MODULES
// ════════════════════════════════════════════════════════════════

module.exports = {
  // Core security
  securityCore: require('./securityCore'),

  // Authentication & Authorization
  auth: {
    twoFactorAuth: require('./twoFactorAuth'),
    sessionManager: require('./sessionManager'),
    tokenBlacklist: require('./tokenBlacklist'),
    permissionValidator: require('./permissionValidator'),
    passwordReset: require('./passwordReset'),
    accountLockout: require('./accountLockout'),
  },

  // Encryption & Data Protection
  encryption: {
    encryption: require('./encryption'),
    dataEncryption: require('./dataEncryption'),
  },

  // Input & Output Validation
  validation: {
    sqlInjectionPrevention: require('./sqlInjectionPrevention'),
    vulnerabilityScanner: require('./vulnerabilityScanner'),
    inputValidation: require('../middleware/inputValidation'),
  },

  // Access Control
  accessControl: {
    ipWhitelist: require('./ipWhitelist'),
    antiDDoS: require('./antiDDoS'),
    apiKeyManager: require('./apiKeyManager'),
  },

  // Audit & Logging
  audit: {
    auditLogger: require('./auditLogger'),
    dataRedaction: require('../middleware/dataRedaction'),
  },

  // Configuration Management
  config: {
    secretsManager: require('./secretsManager'),
    contentSecurityPolicy: require('./contentSecurityPolicy'),
    csrf: require('../middleware/csrf'),
  },

  // Middleware Helper
  createMiddleware: () => {
    const core = require('./securityCore');
    return core.createMiddleware();
  },

  // Security Status Check
  healthCheck: () => ({
    twoFactorAuth: require('./twoFactorAuth').isEnabled ? 'enabled' : 'disabled',
    ipWhitelist: process.env.ENABLE_IP_WHITELIST === 'true' ? 'enabled' : 'disabled',
    encryption: 'enabled',
    auditLogging: 'enabled',
    csrfProtection: 'enabled',
  }),
};
