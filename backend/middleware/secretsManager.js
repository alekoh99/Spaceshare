require('dotenv').config();
const crypto = require('crypto');

class SecretsManager {
  constructor() {
    this.secrets = new Map();
    this.rotation = new Map();
    this.loadSecrets();
  }

  loadSecrets() {
    const secretKeys = [
      'JWT_SECRET',
      'ENCRYPTION_KEY',
      'REQUEST_SIGNING_KEY',
      'DATABASE_PASSWORD',
      'FIREBASE_PRIVATE_KEY',
    ];

    secretKeys.forEach((key) => {
      const value = process.env[key];
      if (!value) {
        // Use a default test value if not set (for development/testing)
        const defaultValue = `default-${key.toLowerCase()}-min-32-chars`;
        this.secrets.set(key, defaultValue);
      } else {
        this.secrets.set(key, value);
      }
      this.rotation.set(key, {
        rotatedAt: new Date(),
        version: 1,
      });
    });
  }

  getSecret(key) {
    if (!this.secrets.has(key)) {
      throw new Error(`Secret not found: ${key}`);
    }
    return this.secrets.get(key);
  }

  rotateSecret(key, newValue) {
    const rotation = this.rotation.get(key);
    if (!rotation) {
      throw new Error(`Cannot rotate unknown secret: ${key}`);
    }

    rotation.previousValue = this.secrets.get(key);
    rotation.version += 1;
    rotation.rotatedAt = new Date();
    rotation.rotatedBy = process.env.ADMIN_USER || 'system';

    this.secrets.set(key, newValue);

    console.log(`🔄 Secret rotated: ${key} (v${rotation.version})`);
    return true;
  }

  validateSecretStrength(secret) {
    if (!secret || secret.length < 32) {
      throw new Error('Secret must be at least 32 characters long');
    }

    const hasUpperCase = /[A-Z]/.test(secret);
    const hasLowerCase = /[a-z]/.test(secret);
    const hasNumbers = /\d/.test(secret);
    const hasSpecialChar = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(secret);

    if (!hasUpperCase || !hasLowerCase || !hasNumbers) {
      throw new Error('Secret must contain uppercase, lowercase, and numbers');
    }

    return true;
  }

  generateSecureSecret(length = 64) {
    return crypto.randomBytes(length).toString('base64');
  }

  maskSecret(secret, visibleChars = 4) {
    const visible = secret.slice(0, visibleChars);
    const hidden = '*'.repeat(Math.max(0, secret.length - visibleChars));
    return visible + hidden;
  }
}

module.exports = new SecretsManager();
