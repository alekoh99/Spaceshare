require('dotenv').config();

// ════════════════════════════════════════════════════════════════
// API KEY & SECRET ROTATION MANAGEMENT
// ════════════════════════════════════════════════════════════════

const crypto = require('crypto');

class APIKeyManager {
  constructor() {
    this.keys = new Map();
    this.rotationLog = [];
  }

  generateAPIKey(userId, permissions = []) {
    const key = crypto.randomBytes(32).toString('hex');
    const hash = crypto.createHash('sha256').update(key).digest('hex');

    const apiKey = {
      id: crypto.randomUUID(),
      userId,
      key: hash,
      plainKey: key, // Only returned once
      permissions,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year
      lastUsed: null,
      active: true,
    };

    this.keys.set(hash, apiKey);

    return {
      id: apiKey.id,
      key: key, // Only returned during creation
      expiresAt: apiKey.expiresAt,
    };
  }

  verifyAPIKey(key) {
    const hash = crypto.createHash('sha256').update(key).digest('hex');
    const apiKey = this.keys.get(hash);

    if (!apiKey || !apiKey.active) {
      return null;
    }

    if (apiKey.expiresAt < new Date()) {
      apiKey.active = false;
      return null;
    }

    apiKey.lastUsed = new Date();
    return {
      id: apiKey.id,
      userId: apiKey.userId,
      permissions: apiKey.permissions,
    };
  }

  revokeAPIKey(keyId) {
    for (const [, key] of this.keys) {
      if (key.id === keyId) {
        key.active = false;
        this.logRotation('revoke', keyId);
        return true;
      }
    }
    return false;
  }

  rotateAPIKey(oldKeyId, userId) {
    // Find old key
    let oldKey = null;
    for (const [, key] of this.keys) {
      if (key.id === oldKeyId) {
        oldKey = key;
        break;
      }
    }

    if (!oldKey || oldKey.userId !== userId) {
      throw new Error('Invalid API key');
    }

    // Generate new key with same permissions
    const newKeyData = this.generateAPIKey(userId, oldKey.permissions);

    // Deactivate old key
    oldKey.active = false;

    this.logRotation('rotate', oldKeyId);

    return newKeyData;
  }

  logRotation(action, keyId) {
    this.rotationLog.push({
      timestamp: new Date(),
      action,
      keyId,
    });
  }

  getRotationHistory(days = 90) {
    const cutoffDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    return this.rotationLog.filter((log) => log.timestamp >= cutoffDate);
  }

  getActiveKeys(userId) {
    const keys = [];
    for (const [, key] of this.keys) {
      if (key.userId === userId && key.active) {
        keys.push({
          id: key.id,
          createdAt: key.createdAt,
          expiresAt: key.expiresAt,
          lastUsed: key.lastUsed,
          permissions: key.permissions,
        });
      }
    }
    return keys;
  }
}

module.exports = new APIKeyManager();
