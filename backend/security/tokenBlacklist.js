const jwt = require('jsonwebtoken');
const crypto = require('crypto');

class TokenBlacklist {
  constructor() {
    this.blacklist = new Set();
    this.cleanupInterval = 60 * 60 * 1000; // 1 hour
    this.startCleanup();
  }

  addToken(token) {
    this.blacklist.add(token);
  }

  isBlacklisted(token) {
    return this.blacklist.has(token);
  }

  removeToken(token) {
    this.blacklist.delete(token);
  }

  clear() {
    this.blacklist.clear();
  }

  startCleanup() {
    setInterval(() => {
      // Verify and clean expired tokens
      const toRemove = [];
      for (const token of this.blacklist) {
        try {
          jwt.verify(token, process.env.JWT_SECRET);
        } catch (err) {
          if (err.name === 'TokenExpiredError') {
            toRemove.push(token);
          }
        }
      }

      toRemove.forEach((token) => this.removeToken(token));
    }, this.cleanupInterval);
  }

  size() {
    return this.blacklist.size;
  }
}

module.exports = new TokenBlacklist();
