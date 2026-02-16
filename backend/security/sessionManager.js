const crypto = require('crypto');

class SessionManager {
  constructor() {
    this.sessions = new Map();
    this.sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours
    this.inactivityTimeout = 30 * 60 * 1000; // 30 minutes
  }

  createSession(userId, metadata = {}) {
    const sessionId = crypto.randomBytes(32).toString('hex');

    this.sessions.set(sessionId, {
      userId,
      sessionId,
      createdAt: Date.now(),
      expiresAt: Date.now() + this.sessionTimeout,
      lastActivity: Date.now(),
      ipAddress: metadata.ipAddress,
      userAgent: metadata.userAgent,
      deviceId: metadata.deviceId,
      active: true,
    });

    return sessionId;
  }

  validateSession(sessionId) {
    const session = this.sessions.get(sessionId);

    if (!session) {
      return { valid: false, error: 'Session not found' };
    }

    if (!session.active) {
      return { valid: false, error: 'Session is inactive' };
    }

    const now = Date.now();

    // Check session expiry
    if (now > session.expiresAt) {
      session.active = false;
      return { valid: false, error: 'Session expired' };
    }

    // Check inactivity timeout
    if (now - session.lastActivity > this.inactivityTimeout) {
      session.active = false;
      return { valid: false, error: 'Session inactive' };
    }

    session.lastActivity = now;

    return {
      valid: true,
      userId: session.userId,
      sessionId: session.sessionId,
    };
  }

  invalidateSession(sessionId) {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.active = false;
      return true;
    }
    return false;
  }

  invalidateAllSessions(userId) {
    let count = 0;
    for (const [, session] of this.sessions) {
      if (session.userId === userId) {
        session.active = false;
        count++;
      }
    }
    return count;
  }

  getActiveSessions(userId) {
    const sessions = [];
    for (const [, session] of this.sessions) {
      if (session.userId === userId && session.active) {
        sessions.push({
          sessionId: session.sessionId,
          createdAt: new Date(session.createdAt),
          lastActivity: new Date(session.lastActivity),
          ipAddress: session.ipAddress,
          userAgent: session.userAgent,
          deviceId: session.deviceId,
        });
      }
    }
    return sessions;
  }

  extendSession(sessionId, additionalTime = this.sessionTimeout) {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.expiresAt = Date.now() + additionalTime;
      return true;
    }
    return false;
  }

  cleanupExpiredSessions() {
    const now = Date.now();
    let count = 0;

    for (const [key, session] of this.sessions) {
      if (session.expiresAt < now || !session.active) {
        this.sessions.delete(key);
        count++;
      }
    }

    return count;
  }
}

module.exports = new SessionManager();
