// ════════════════════════════════════════════════════════════════
// DEPLOYMENT SECURITY CHECKLIST
// ════════════════════════════════════════════════════════════════

const securityChecklist = {
  // ════════════════════════════════════════════════════════════════
  // 1. ENVIRONMENT CONFIGURATION
  // ════════════════════════════════════════════════════════════════
  environmentSetup: {
    checkList: [
      {
        item: "NODE_ENV is set to 'production' in production",
        required: true,
        severity: "CRITICAL",
      },
      {
        item: "All .env files are in .gitignore",
        required: true,
        severity: "CRITICAL",
      },
      {
        item: "JWT_SECRET is a strong random string (min 32 chars)",
        required: true,
        severity: "CRITICAL",
      },
      {
        item: "Database passwords changed from default",
        required: true,
        severity: "CRITICAL",
      },
      {
        item: "ENCRYPTION_KEY is set and strong",
        required: true,
        severity: "CRITICAL",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 2. NETWORK SECURITY
  // ════════════════════════════════════════════════════════════════
  networkSecurity: {
    checkList: [
      {
        item: "HTTPS/TLS enabled in production (certificate from trusted CA)",
        required: true,
        severity: "CRITICAL",
      },
      {
        item: "CORS is properly configured (no wildcard origins in prod)",
        required: true,
        severity: "CRITICAL",
      },
      {
        item: "API runs behind reverse proxy (nginx/load balancer)",
        required: true,
        severity: "HIGH",
      },
      {
        item: "Firewall rules restrict non-essential ports",
        required: true,
        severity: "HIGH",
      },
      {
        item: "VPN configured for database access",
        required: true,
        severity: "HIGH",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 3. DATABASE SECURITY
  // ════════════════════════════════════════════════════════════════
  databaseSecurity: {
    postgresql: {
      checkList: [
        { item: "SSL/TLS connections enforced", severity: "CRITICAL" },
        { item: "Connection pooling configured", severity: "HIGH" },
        { item: "Row-level security (RLS) enabled", severity: "CRITICAL" },
        { item: "Default credentials changed", severity: "CRITICAL" },
        { item: "Automated backups configured", severity: "CRITICAL" },
      ],
    },
    mongodb: {
      checkList: [
        { item: "Authentication enabled", severity: "CRITICAL" },
        { item: "SSL/TLS connections enforced", severity: "CRITICAL" },
        { item: "Audit logging enabled", severity: "HIGH" },
        { item: "IP whitelist configured", severity: "HIGH" },
      ],
    },
    firebase: {
      checkList: [
        { item: "Firestore rules deployed", severity: "CRITICAL" },
        { item: "Storage rules restrict uploads", severity: "CRITICAL" },
        { item: "Real-time database rules deny by default", severity: "CRITICAL" },
      ],
    },
  },

  // ════════════════════════════════════════════════════════════════
  // 4. APPLICATION SECURITY
  // ════════════════════════════════════════════════════════════════
  applicationSecurity: {
    checkList: [
      {
        item: "Input validation on all endpoints",
        module: "inputValidation.js",
        severity: "CRITICAL",
      },
      {
        item: "Rate limiting enabled",
        module: "security.js",
        severity: "CRITICAL",
      },
      {
        item: "CSRF protection on state-changing operations",
        module: "csrf.js",
        severity: "CRITICAL",
      },
      {
        item: "Password hashing using strong algorithm",
        module: "encryption.js",
        severity: "CRITICAL",
      },
      {
        item: "JWT tokens with expiration",
        module: "auth.js",
        severity: "CRITICAL",
      },
      {
        item: "SQL/NoSQL injection prevention",
        module: "inputValidation.js",
        severity: "CRITICAL",
      },
      {
        item: "XSS protection via sanitization",
        module: "security.js",
        severity: "HIGH",
      },
      {
        item: "HSTS enabled (strict-transport-security)",
        module: "security.js",
        severity: "HIGH",
      },
      {
        item: "Content Security Policy configured",
        module: "contentSecurityPolicy.js",
        severity: "HIGH",
      },
      {
        item: "Helmet security headers enabled",
        module: "security.js",
        severity: "HIGH",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 5. AUTHENTICATION & AUTHORIZATION
  // ════════════════════════════════════════════════════════════════
  authenticationAuthorization: {
    checkList: [
      {
        item: "Multi-factor authentication (MFA) implemented or planned",
        severity: "HIGH",
      },
      {
        item: "Password requirements enforced (min 12 chars, special chars)",
        module: "inputValidation.js",
        severity: "HIGH",
      },
      {
        item: "Session timeouts configured",
        severity: "MEDIUM",
      },
      {
        item: "Refresh token rotation implemented",
        module: "auth.js",
        severity: "MEDIUM",
      },
      {
        item: "Role-based access control (RBAC) implemented",
        module: "auth.js",
        severity: "HIGH",
      },
      {
        item: "Resource ownership verified on all operations",
        module: "auth.js",
        severity: "CRITICAL",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 6. DATA PROTECTION
  // ════════════════════════════════════════════════════════════════
  dataProtection: {
    checkList: [
      {
        item: "Sensitive data encrypted at rest",
        module: "encryption.js",
        severity: "CRITICAL",
      },
      {
        item: "Sensitive data encrypted in transit (TLS)",
        severity: "CRITICAL",
      },
      {
        item: "Sensitive data redacted from logs",
        module: "dataRedaction.js",
        severity: "HIGH",
      },
      {
        item: "PII data access minimized",
        severity: "CRITICAL",
      },
      {
        item: "Data retention policies implemented",
        severity: "HIGH",
      },
      {
        item: "GDPR compliance verified",
        severity: "HIGH",
      },
      {
        item: "Data deletion/archival automated",
        severity: "MEDIUM",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 7. MONITORING & LOGGING
  // ════════════════════════════════════════════════════════════════
  monitoringLogging: {
    checkList: [
      {
        item: "Centralized logging configured",
        module: "auditLogger.js",
        severity: "CRITICAL",
      },
      {
        item: "Security events logged (failures, admin actions, etc)",
        module: "auditLogger.js",
        severity: "CRITICAL",
      },
      {
        item: "Audit trail maintained for 6+ months",
        severity: "HIGH",
      },
      {
        item: "Alerts configured for suspicious activities",
        severity: "HIGH",
      },
      {
        item: "Real-time monitoring of error rates",
        severity: "MEDIUM",
      },
      {
        item: "Database query logging enabled",
        severity: "MEDIUM",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 8. BACKUP & DISASTER RECOVERY
  // ════════════════════════════════════════════════════════════════
  backupRecovery: {
    checkList: [
      {
        item: "Automated backups configured (daily minimum)",
        severity: "CRITICAL",
      },
      {
        item: "Point-in-time recovery enabled",
        severity: "HIGH",
      },
      {
        item: "Backups stored in geographically separate location",
        severity: "HIGH",
      },
      {
        item: "Backup encryption configured",
        severity: "HIGH",
      },
      {
        item: "Disaster recovery plan documented and tested",
        severity: "CRITICAL",
      },
      {
        item: "RTO (Recovery Time Objective) defined",
        severity: "HIGH",
      },
      {
        item: "RPO (Recovery Point Objective) defined",
        severity: "HIGH",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 9. INCIDENT RESPONSE
  // ════════════════════════════════════════════════════════════════
  incidentResponse: {
    checkList: [
      {
        item: "Incident response plan documented",
        severity: "HIGH",
      },
      {
        item: "Security incident contacts established",
        severity: "HIGH",
      },
      {
        item: "Vulnerability reporting process established",
        severity: "MEDIUM",
      },
      {
        item: "Security patch process in place",
        severity: "CRITICAL",
      },
      {
        item: "Data breach notification procedures ready",
        severity: "CRITICAL",
      },
    ],
  },

  // ════════════════════════════════════════════════════════════════
  // 10. COMPLIANCE
  // ════════════════════════════════════════════════════════════════
  compliance: {
    checkList: [
      {
        item: "GDPR compliance verified (for EU users)",
        severity: "CRITICAL",
      },
      {
        item: "Privacy policy published and accessible",
        severity: "CRITICAL",
      },
      {
        item: "Terms of service established",
        severity: "MEDIUM",
      },
      {
        item: "Cookie consent management",
        severity: "HIGH",
      },
      {
        item: "Data processing agreements in place",
        severity: "HIGH",
      },
      {
        item: "Regular security audits scheduled",
        severity: "HIGH",
      },
    ],
  },
};

module.exports = securityChecklist;
