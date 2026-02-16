class AntiDDoSProtection {
  constructor() {
    this.requestCounts = new Map();
    this.blocklist = new Set();
    this.thresholds = {
      requestsPerMinute: 60,
      uniqueUrlsPerMinute: 20,
      connectionLimit: 100,
    };
  }

  trackRequest(ipAddress) {
    const now = Date.now();
    const key = ipAddress;

    if (!this.requestCounts.has(key)) {
      this.requestCounts.set(key, []);
    }

    const timestamps = this.requestCounts.get(key);

    // Remove timestamps older than 1 minute
    const oneMinuteAgo = now - 60000;
    const recentRequests = timestamps.filter((t) => t > oneMinuteAgo);

    recentRequests.push(now);
    this.requestCounts.set(key, recentRequests);

    return recentRequests.length;
  }

  isIPBlocked(ipAddress) {
    return this.blocklist.has(ipAddress);
  }

  checkIfSuspicious(ipAddress) {
    const requestCount = this.trackRequest(ipAddress);

    if (requestCount > this.thresholds.requestsPerMinute) {
      this.blockIP(ipAddress, 15 * 60 * 1000); // 15 minute block
      return true;
    }

    return false;
  }

  blockIP(ipAddress, duration = 60 * 60 * 1000) {
    this.blocklist.add(ipAddress);

    setTimeout(() => {
      this.blocklist.delete(ipAddress);
      this.requestCounts.delete(ipAddress);
    }, duration);

    return true;
  }

  unblockIP(ipAddress) {
    this.blocklist.delete(ipAddress);
    return true;
  }

  getBlockedIPs() {
    return Array.from(this.blocklist);
  }

  cleanup() {
    this.requestCounts.clear();
    this.blocklist.clear();
  }
}

module.exports = new AntiDDoSProtection();
