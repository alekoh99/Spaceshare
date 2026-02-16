const crypto = require('crypto');

class IPWhitelistManager {
  constructor() {
    this.whitelists = new Map();
    this.accessLog = [];
  }

  addIP(userId, ipAddress, label = '') {
    if (!this.whitelists.has(userId)) {
      this.whitelists.set(userId, []);
    }

    const list = this.whitelists.get(userId);
    const exists = list.some((entry) => entry.ip === ipAddress);

    if (!exists) {
      list.push({
        ip: ipAddress,
        label,
        addedAt: new Date(),
        lastUsed: null,
      });
    }

    return true;
  }

  removeIP(userId, ipAddress) {
    const list = this.whitelists.get(userId);
    if (!list) return false;

    const index = list.findIndex((entry) => entry.ip === ipAddress);
    if (index === -1) return false;

    list.splice(index, 1);
    return true;
  }

  isIPWhitelisted(userId, ipAddress) {
    const list = this.whitelists.get(userId);
    if (!list || list.length === 0) return false;

    const entry = list.find((e) => e.ip === ipAddress);
    if (entry) {
      entry.lastUsed = new Date();
      return true;
    }

    return false;
  }

  getWhitelist(userId) {
    const list = this.whitelists.get(userId) || [];
    return list.map((entry) => ({
      ip: entry.ip,
      label: entry.label,
      addedAt: entry.addedAt,
      lastUsed: entry.lastUsed,
    }));
  }

  clearWhitelist(userId) {
    this.whitelists.delete(userId);
    return true;
  }

  logAccess(userId, ipAddress, allowed) {
    this.accessLog.push({
      timestamp: new Date(),
      userId,
      ipAddress,
      allowed,
    });

    // Keep only last 30 days of logs
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    this.accessLog = this.accessLog.filter((log) => log.timestamp >= thirtyDaysAgo);
  }

  getAccessLog(userId, days = 30) {
    const cutoffDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    return this.accessLog.filter(
      (log) => log.userId === userId && log.timestamp >= cutoffDate
    );
  }
}

module.exports = new IPWhitelistManager();
