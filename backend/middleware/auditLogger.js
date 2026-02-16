const crypto = require('crypto');

class AuditLogger {
  constructor() {
    this.events = [];
    this.sensitiveFields = ['password', 'token', 'secret', 'apiKey', 'creditCard'];
  }

  log(event) {
    const auditEntry = {
      timestamp: new Date().toISOString(),
      eventType: event.type,
      userId: event.userId || 'anonymous',
      action: event.action,
      resource: event.resource,
      status: event.status || 'success',
      ipAddress: this.hashIp(event.ipAddress),
      userAgent: event.userAgent,
      changes: this.redactSensitiveData(event.changes),
      result: event.result,
      error: event.error,
    };

    this.events.push(auditEntry);
    this.writeToLog(auditEntry);

    return auditEntry;
  }

  logSecurityEvent(event) {
    return this.log({
      type: 'SECURITY_EVENT',
      ...event,
    });
  }

  logAccessEvent(event) {
    return this.log({
      type: 'ACCESS_EVENT',
      ...event,
    });
  }

  logDataModification(event) {
    return this.log({
      type: 'DATA_MODIFICATION',
      ...event,
    });
  }

  redactSensitiveData(obj) {
    if (!obj) return obj;

    if (Array.isArray(obj)) {
      return obj.map((item) => this.redactSensitiveData(item));
    }

    if (typeof obj === 'object') {
      const redacted = {};
      for (const key in obj) {
        if (this.sensitiveFields.some((field) => key.toLowerCase().includes(field))) {
          redacted[key] = '[REDACTED]';
        } else {
          redacted[key] = this.redactSensitiveData(obj[key]);
        }
      }
      return redacted;
    }

    return obj;
  }

  hashIp(ipAddress) {
    if (!ipAddress) return 'unknown';
    return crypto.createHash('sha256').update(ipAddress).digest('hex').slice(0, 16);
  }

  writeToLog(entry) {
    // In production, send to centralized logging service
    // For now, just console.log (replace with actual implementation)
    if (process.env.NODE_ENV === 'production') {
      // Send to CloudLogging, DataDog, Splunk, etc.
      console.log(JSON.stringify(entry));
    }
  }

  getAuditTrail(filters = {}) {
    let filtered = this.events;

    if (filters.userId) {
      filtered = filtered.filter((e) => e.userId === filters.userId);
    }

    if (filters.eventType) {
      filtered = filtered.filter((e) => e.eventType === filters.eventType);
    }

    if (filters.startDate) {
      filtered = filtered.filter((e) => new Date(e.timestamp) >= filters.startDate);
    }

    if (filters.endDate) {
      filtered = filtered.filter((e) => new Date(e.timestamp) <= filters.endDate);
    }

    return filtered;
  }
}

module.exports = new AuditLogger();
