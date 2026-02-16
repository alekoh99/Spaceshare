const crypto = require('crypto');

class AccountLockoutManager {
  constructor() {
    this.attempts = new Map();
    this.lockouts = new Map();
    this.maxAttempts = 5;
    this.lockoutDuration = 15 * 60 * 1000; // 15 minutes
    this.attemptWindow = 15 * 60 * 1000; // 15 minutes
  }

  recordFailedAttempt(userId) {
    const now = Date.now();
    let userAttempts = this.attempts.get(userId) || [];

    // Filter out old attempts outside the window
    userAttempts = userAttempts.filter((time) => now - time < this.attemptWindow);

    userAttempts.push(now);
    this.attempts.set(userId, userAttempts);

    if (userAttempts.length >= this.maxAttempts) {
      this.lockAccount(userId);
      return {
        locked: true,
        attempts: userAttempts.length,
      };
    }

    return {
      locked: false,
      attempts: userAttempts.length,
      remaining: this.maxAttempts - userAttempts.length,
    };
  }

  recordSuccessfulAttempt(userId) {
    this.attempts.delete(userId);
    this.unlockAccount(userId);
  }

  lockAccount(userId) {
    this.lockouts.set(userId, {
      lockedAt: Date.now(),
      expiresAt: Date.now() + this.lockoutDuration,
    });
  }

  unlockAccount(userId) {
    this.lockouts.delete(userId);
  }

  isAccountLocked(userId) {
    const lockout = this.lockouts.get(userId);
    if (!lockout) return false;

    if (Date.now() > lockout.expiresAt) {
      this.unlockAccount(userId);
      return false;
    }

    return true;
  }

  getTimeUntilUnlock(userId) {
    const lockout = this.lockouts.get(userId);
    if (!lockout) return null;

    const remaining = lockout.expiresAt - Date.now();
    return remaining > 0 ? remaining : 0;
  }

  getAttempts(userId) {
    const userAttempts = this.attempts.get(userId) || [];
    return userAttempts.length;
  }

  reset(userId) {
    this.attempts.delete(userId);
    this.unlockAccount(userId);
  }
}

module.exports = new AccountLockoutManager();
