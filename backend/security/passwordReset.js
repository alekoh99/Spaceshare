const crypto = require('crypto');

class PasswordResetManager {
  constructor() {
    this.tokens = new Map();
    this.cooldown = new Map();
    this.tokenExpiry = 1 * 60 * 60 * 1000; // 1 hour
    this.cooldownDuration = 5 * 60 * 1000; // 5 minutes
  }

  generateResetToken(userId, email) {
    // Check cooldown
    const lastReset = this.cooldown.get(userId);
    if (lastReset && Date.now() - lastReset < this.cooldownDuration) {
      return {
        success: false,
        error: 'Too many reset requests. Please try again later.',
      };
    }

    const token = crypto.randomBytes(32).toString('hex');
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

    this.tokens.set(hashedToken, {
      userId,
      email,
      createdAt: Date.now(),
      expiresAt: Date.now() + this.tokenExpiry,
      used: false,
    });

    this.cooldown.set(userId, Date.now());

    return {
      success: true,
      token: token, // Only return once
    };
  }

  verifyResetToken(token) {
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const resetData = this.tokens.get(hashedToken);

    if (!resetData) {
      return {
        valid: false,
        error: 'Invalid or expired reset token',
      };
    }

    if (resetData.used) {
      return {
        valid: false,
        error: 'Reset token has already been used',
      };
    }

    if (Date.now() > resetData.expiresAt) {
      this.tokens.delete(hashedToken);
      return {
        valid: false,
        error: 'Reset token has expired',
      };
    }

    return {
      valid: true,
      userId: resetData.userId,
      email: resetData.email,
    };
  }

  completePasswordReset(token) {
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const resetData = this.tokens.get(hashedToken);

    if (!resetData) {
      return { success: false };
    }

    resetData.used = true;
    resetData.completedAt = Date.now();

    // Keep used token for audit trail
    setTimeout(() => {
      this.tokens.delete(hashedToken);
    }, 24 * 60 * 60 * 1000); // Delete after 24 hours

    return { success: true };
  }

  invalidateAllTokens(userId) {
    for (const [key, data] of this.tokens) {
      if (data.userId === userId) {
        this.tokens.delete(key);
      }
    }
    return true;
  }

  cleanupExpiredTokens() {
    const now = Date.now();
    const expiredTokens = [];

    for (const [key, data] of this.tokens) {
      if (data.expiresAt < now) {
        expiredTokens.push(key);
      }
    }

    expiredTokens.forEach((key) => this.tokens.delete(key));
    return expiredTokens.length;
  }
}

module.exports = new PasswordResetManager();
