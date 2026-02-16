const twoFactorAuth = require('../security/twoFactorAuth');
const ipWhitelist = require('../security/ipWhitelist');
const accountLockout = require('../security/accountLockout');
const passwordReset = require('../security/passwordReset');
const sessionManager = require('../security/sessionManager');
const dataEncryption = require('../security/dataEncryption');
const vulnerabilityScanner = require('../security/vulnerabilityScanner');
const sqlInjectionPrevention = require('../security/sqlInjectionPrevention');
const apiKeyManager = require('../security/apiKeyManager');
const antiDDoS = require('../security/antiDDoS');
const permissionValidator = require('../security/permissionValidator');
const tokenBlacklist = require('../security/tokenBlacklist');

// ════════════════════════════════════════════════════════════════
// SECURITY TESTS
// ════════════════════════════════════════════════════════════════

const tests = {
  // Two-Factor Authentication Tests
  '2FA': {
    generateSecret: () => {
      const result = twoFactorAuth.generateSecret('user-123');
      return result.secret && result.backupCodes && result.backupCodes.length === 8;
    },
    verifyTOTP: () => {
      const result = twoFactorAuth.generateSecret('user-456');
      const code = twoFactorAuth.generateTOTP(result.secret);
      return code.length === 6 && /^\d{6}$/.test(code);
    },
  },

  // IP Whitelist Tests
  ipWhitelist: {
    addAndVerify: () => {
      ipWhitelist.addIP('user-789', '192.168.1.1');
      return ipWhitelist.isIPWhitelisted('user-789', '192.168.1.1');
    },
    blockUnknownIP: () => {
      return !ipWhitelist.isIPWhitelisted('user-999', '10.0.0.1');
    },
  },

  // Account Lockout Tests
  accountLockout: {
    lockAfterAttempts: () => {
      const userId = 'user-lock-' + Date.now();
      for (let i = 0; i < 5; i++) {
        accountLockout.recordFailedAttempt(userId);
      }
      return accountLockout.isAccountLocked(userId);
    },
    unlock: () => {
      const userId = 'user-unlock-' + Date.now();
      accountLockout.recordFailedAttempt(userId);
      accountLockout.reset(userId);
      return !accountLockout.isAccountLocked(userId);
    },
  },

  // Password Reset Tests
  passwordReset: {
    generateToken: () => {
      const result = passwordReset.generateResetToken('user-reset', 'test@example.com');
      return result.success && result.token;
    },
    verifyToken: () => {
      const result = passwordReset.generateResetToken('user-verify', 'test@example.com');
      const validation = passwordReset.verifyResetToken(result.token);
      return validation.valid && validation.userId === 'user-verify';
    },
  },

  // Session Management Tests
  sessionManager: {
    createSession: () => {
      const sessionId = sessionManager.createSession('user-session', { ipAddress: '192.168.1.1' });
      return sessionId && sessionId.length > 0;
    },
    validateSession: () => {
      const sessionId = sessionManager.createSession('user-validate', { ipAddress: '192.168.1.1' });
      const validation = sessionManager.validateSession(sessionId);
      return validation.valid && validation.userId === 'user-validate';
    },
  },

  // Data Encryption Tests
  dataEncryption: {
    encryptDecrypt: () => {
      const original = 'sensitive-data-123';
      const encrypted = dataEncryption.encryptField(original);
      const decrypted = dataEncryption.decryptField(encrypted);
      return decrypted === original;
    },
    hashField: () => {
      const hash = dataEncryption.hashField('password');
      return hash && hash.length === 64; // SHA256
    },
  },

  // Vulnerability Scanning Tests
  vulnerable: {
    detectXSS: () => {
      return vulnerabilityScanner.scanForXSS('<script>alert("xss")</script>');
    },
    detectSQLInjection: () => {
      return vulnerabilityScanner.scanForSQLInjection("' UNION SELECT");
    },
    detectPathTraversal: () => {
      return vulnerabilityScanner.scanForPathTraversal('../../etc/passwd');
    },
  },

  // SQL Injection Prevention Tests
  sqlPrevention: {
    validateEmail: () => {
      return sqlInjectionPrevention.validateInput('test@example.com', 'email') &&
             !sqlInjectionPrevention.validateInput('invalid-email', 'email');
    },
    validatePhone: () => {
      return sqlInjectionPrevention.validateInput('+1234567890', 'phone') &&
             !sqlInjectionPrevention.validateInput('invalid-phone', 'phone');
    },
  },

  // API Key Management Tests
  apiKey: {
    generateAndVerify: () => {
      const key = apiKeyManager.generateAPIKey('user-api', ['read', 'write']);
      const verified = apiKeyManager.verifyAPIKey(key.key);
      return verified && verified.userId === 'user-api';
    },
    revokeKey: () => {
      const key = apiKeyManager.generateAPIKey('user-revoke', []);
      const keyId = key.id;
      apiKeyManager.revokeAPIKey(keyId);
      const verified = apiKeyManager.verifyAPIKey(key.key);
      return verified === null;
    },
  },

  // Anti-DDoS Tests
  antiDDoS: {
    trackRequests: () => {
      const count = antiDDoS.trackRequest('192.168.1.100');
      return count > 0;
    },
    blockIP: () => {
      antiDDoS.blockIP('192.168.1.200', 1000);
      return antiDDoS.isIPBlocked('192.168.1.200');
    },
  },

  // Permission Validator Tests
  permissions: {
    hasPermission: () => {
      const user = { role: 'admin' };
      return permissionValidator.hasPermission(user, 'read_users');
    },
    denyInsufficientRole: () => {
      const user = { role: 'user' };
      return !permissionValidator.hasPermission(user, 'manage_roles');
    },
  },

  // Token Blacklist Tests
  tokenBlacklist: {
    addAndCheck: () => {
      const token = 'fake-token-' + Date.now();
      tokenBlacklist.addToken(token);
      return tokenBlacklist.isBlacklisted(token);
    },
    removeToken: () => {
      const token = 'fake-token-remove-' + Date.now();
      tokenBlacklist.addToken(token);
      tokenBlacklist.removeToken(token);
      return !tokenBlacklist.isBlacklisted(token);
    },
  },
};

// ════════════════════════════════════════════════════════════════
// RUN TESTS
// ════════════════════════════════════════════════════════════════

const runTests = () => {
  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║              SPACESHARE SECURITY MODULE TESTS                    ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  let passed = 0;
  let failed = 0;

  for (const [category, testFns] of Object.entries(tests)) {
    console.log(`📋 ${category}`);

    for (const [testName, testFn] of Object.entries(testFns)) {
      try {
        const result = testFn();
        if (result) {
          console.log(`  ✅ ${testName}`);
          passed++;
        } else {
          console.log(`  ❌ ${testName}`);
          failed++;
        }
      } catch (error) {
        console.log(`  ❌ ${testName} (Error: ${error.message})`);
        failed++;
      }
    }
    console.log('');
  }

  console.log('════════════════════════════════════════════════════════════════');
  console.log(`✅ Passed: ${passed} | ❌ Failed: ${failed} | Total: ${passed + failed}`);
  console.log('════════════════════════════════════════════════════════════════\n');

  return failed === 0;
};

module.exports = { runTests };

// Run tests if executed directly
if (require.main === module) {
  const success = runTests();
  process.exit(success ? 0 : 1);
}
