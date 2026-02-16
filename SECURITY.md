# SpaceShare Backend Security Implementation Guide

## Overview

This document outlines the comprehensive security measures implemented in the SpaceShare backend to protect against data leaks, unauthorized access, and other security threats.

## Table of Contents

1. [Security Architecture](#security-architecture)
2. [Authentication & Authorization](#authentication--authorization)
3. [Data Protection](#data-protection)
4. [Network Security](#network-security)
5. [API Security](#api-security)
6. [Database Security](#database-security)
7. [Logging & Monitoring](#logging--monitoring)
8. [Deployment Security](#deployment-security)
9. [Incident Response](#incident-response)
10. [Compliance](#compliance)

---

## Security Architecture

### Defense in Depth Approach

The security implementation follows a multi-layered defense strategy:

```
┌─────────────────────────────────────────────────────────┐
│ 1. Network Level (HTTPS, CORS, Firewall)               │
├─────────────────────────────────────────────────────────┤
│ 2. Application Level (Helmet, Rate Limiting)            │
├─────────────────────────────────────────────────────────┤
│ 3. Validation Level (Input Validation, Sanitization)    │
├─────────────────────────────────────────────────────────┤
│ 4. Authentication Level (JWT, Token Verification)       │
├─────────────────────────────────────────────────────────┤
│ 5. Authorization Level (Role-based Access Control)      │
├─────────────────────────────────────────────────────────┤
│ 6. Data Level (Encryption, Hashing)                     │
├─────────────────────────────────────────────────────────┤
│ 7. Audit Level (Logging, Monitoring, Alerts)            │
└─────────────────────────────────────────────────────────┘
```

---

## Authentication & Authorization

### JWT Implementation

**File:** `middleware/auth.js`

#### Token Generation
- Uses HS256 algorithm (HMAC with SHA-256)
- Required fields: `userId`, `email`, `role`, `iat` (issued at)
- Configurable expiration (default: 7 days)
- Token age validation (max 30 days)

#### Token Verification
```javascript
const token = generateToken(userId, email, role);
// Returns signed JWT with embedded user claims
```

#### Key Security Features:
- ✅ Algorithm validation (prevent algorithm switching)
- ✅ Token age checking (prevent replay attacks)
- ✅ Signature verification (prevent tampering)
- ✅ Error differentiation (expired vs invalid)
- ✅ Secure storage on client side (HttpOnly cookies recommended)

### Role-Based Access Control (RBAC)

```javascript
// Middleware for role validation
authorizeUser('admin')  // Requires admin role
verifyResourceOwnership() // Verify user owns resource
```

**Role Hierarchy:**
- `admin` (Level 3): Full system access
- `moderator` (Level 2): Management access
- `user` (Level 1): Basic user access

---

## Data Protection

### Input Validation & Sanitization

**File:** `middleware/validation.js`

#### Validation Schemas
All inputs are validated against defined Joi schemas:
- Profile data
- Authentication credentials
- Listings
- Reviews
- Messages
- Pagination parameters

#### Sanitization Process
1. **NoSQL Injection Prevention** (`express-mongo-sanitize`)
   - Removes `$` and `.` from keys
   - Prevents MongoDB operator injection

2. **XSS Prevention** (`xss-clean`)
   - Removes dangerous HTML/JavaScript
   - Sanitizes user input automatically

3. **HTTP Parameter Pollution Prevention** (`hpp`)
   - Removes duplicate parameters
   - Prevents confusion in parameter parsing

### Encryption

**File:** `middleware/errors.js` - EncryptionService

#### Algorithm
- **AES-256-GCM** (Advanced Encryption Standard with Galois/Counter Mode)
- Provides both confidentiality and authenticity
- 256-bit key size

#### Implementation
```javascript
const encryption = new EncryptionService();

// Encrypt sensitive data
const encrypted = encryption.encrypt('sensitive_data');

// Decrypt when needed
const decrypted = encryption.decrypt(encrypted);
```

#### Key Management
- Keys stored in environment variables only
- Never hardcoded in source code
- Rotated periodically
- Access controlled via IAM

### Password Security

**Requirements:**
- Minimum length: 12 characters
- Must contain:
  - Uppercase letters (A-Z)
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Special characters (@$!%*?&)

**Hashing:**
```javascript
// Using bcryptjs for password hashing
const hash = await bcrypt.hash(password, 10);
// Using SHA-256 for sensitive data hashing
const hash = crypto.createHash('sha256').update(data).digest('hex');
```

---

## Network Security

### CORS (Cross-Origin Resource Sharing)

**File:** `middleware/security.js`

**Configuration:**
```javascript
{
  origin: ['https://yourdomain.com'],           // Whitelist specific origins
  credentials: true,                             // Allow credentials
  methods: ['GET', 'POST', 'PUT', 'PATCH'],    // Whitelist methods
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400                                  // Cache preflight for 24h
}
```

⚠️ **Production Rules:**
- ❌ Never use wildcard (`*`) in production
- ✅ Specify exact domain(s)
- ✅ Update on each domain addition
- ✅ Remove unused origins

### Security Headers (Helmet.js)

**File:** `middleware/security.js`

Implemented headers:

| Header | Purpose |
|--------|---------|
| `X-Content-Type-Options: nosniff` | Prevent MIME type sniffing |
| `X-Frame-Options: DENY` | Prevent clickjacking |
| `X-XSS-Protection: 1; mode=block` | Enable XSS protection |
| `Strict-Transport-Security` | Enforce HTTPS (1 year) |
| `Content-Security-Policy` | Restrict resource origins |
| `Referrer-Policy` | Control referrer information |
| `Permissions-Policy` | Restrict browser features |

### HTTPS Enforcement

**Production Requirements:**
1. Use TLS 1.2 or higher
2. Valid SSL certificate (not self-signed)
3. Strong cipher suites
4. HSTS header (max-age: 31536000)

**Configuration:**
```javascript
// Server should use HTTPS
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('path/to/key.pem'),
  cert: fs.readFileSync('path/to/cert.pem')
};

https.createServer(options, app).listen(443);
```

---

## API Security

### Rate Limiting

**File:** `middleware/security.js`

**Three-Tier Rate Limiting:**

1. **General API Rate Limiter**
   - Window: 15 minutes
   - Limit: 100 requests
   - Applies to: `/api/*`

2. **Authentication Rate Limiter**
   - Window: 15 minutes
   - Limit: 50 requests
   - Applies to: Login, registration, token refresh

3. **Strict Rate Limiter**
   - Window: 15 minutes
   - Limit: 5 requests
   - Applies to: Sensitive operations (password reset, account deletion)

**Exemptions:**
- `/health` endpoint (for monitoring)
- Database health checks

**Rate Limit Response:**
```javascript
{
  "success": false,
  "error": "Too many requests",
  "retryAfter": "2024-02-12T10:30:00Z"
}
```

### Request Size Limits

**Configuration:**
- Max body size: 10 MB
- Prevents DoS attacks via large payloads
- Configurable per environment

### Request Validation

**Validation Middleware:**
- Content-Type must be `application/json`
- Validates JSON structure
- Rejects malformed requests

---

## Database Security

### PostgreSQL Security

**Best Practices:**
1. **Connection Security**
   - SSL/TLS enabled (sslmode=require)
   - Connection pooling (2-20 connections)
   - Connection timeout: 30 seconds

2. **Credentials Management**
   - Separate database user (not superuser)
   - Minimal required permissions
   - Stored in environment variables

3. **Query Safety**
   ```javascript
   // ✅ SAFE: Parameterized queries
   const result = await pool.query(
     'SELECT * FROM users WHERE id = $1',
     [userId]
   );
   
   // ❌ UNSAFE: String concatenation
   const result = await pool.query(
     `SELECT * FROM users WHERE id = ${userId}`
   );
   ```

### MongoDB Security

**Best Practices:**
1. **Use MongoDB Atlas**
   - Managed service with built-in security
   - Automatic backups
   - IP whitelisting built-in

2. **Authentication**
   - Enable authentication (authSource=admin)
   - Use strong passwords (min 12 chars)
   - Rotate credentials regularly

3. **Connection String**
   ```
   mongodb+srv://username:password@cluster.mongodb.net/database?authSource=admin
   ```

### Firebase/Firestore Security

**File:** `firestore.rules` and `database.rules.json`

#### Firestore Rules
```javascript
// Only authenticated users can read their own data
match /users/{userId} {
  allow read: if isAuthenticated();
  allow create: if request.auth.uid == userId;
  allow update: if isOwner(userId);
  allow delete: if isAdmin();
}
```

#### Database Rules
```json
{
  "rules": {
    ".read": false,  // Deny all by default
    ".write": false  // Deny all by default
  }
}
```

**Principle:** Default deny, then grant specific permissions.

---

## Logging & Monitoring

### Secure Logging

**File:** `middleware/errors.js` - SecureLogger

#### Features:
1. **Sensitive Data Redaction**
   - Automatically hides:
     - Passwords
     - Tokens
     - API keys
     - Email addresses
     - Credit card numbers
     - SSN patterns
   - Controlled by `LOG_SENSITIVE_DATA` env var

2. **Log Levels**
   - `error`: Critical failures
   - `warn`: Security issues, warnings
   - `info`: General information
   - `debug`: Detailed debugging

3. **Log Types**
   - **Application Logs**: `info-YYYY-MM-DD.log`
   - **Error Logs**: `error-YYYY-MM-DD.log`
   - **Security Logs**: `security-YYYY-MM-DD.log`

#### Security Events Logged:
- Unauthorized access attempts
- Token validation failures
- Role-based access denials
- Rate limit triggers
- Data validation errors
- Unhandled exceptions
- Graceful shutdowns

### Request Logging

```javascript
// Logs include:
{
  timestamp: '2024-02-12T10:15:30.000Z',
  method: 'POST',
  path: '/api/profiles',
  statusCode: 201,
  userId: 'user123',
  duration: '45ms',
  ip: '192.168.1.1'
}
```

⚠️ **Sensitive Data Never Logged:**
- Request/response bodies (unless explicitly enabled)
- Password fields
- Token contents
- API keys
- Personal information

---

## Deployment Security

### Environment Configuration

**Development (.env.development):**
- NODE_ENV=development
- Less strict rate limiting
- Extended JWT expiration
- SQL query logging enabled

**Production (.env.production):**
- NODE_ENV=production
- Strict rate limiting
- Short JWT expiration
- Secure defaults enforced
- HTTPS required

### Environment Variables

**Required for Production:**
```bash
# Generate strong values
JWT_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -base64 32)
```

### Server Hardening

1. **Process-Level Security**
   ```javascript
   // Graceful shutdown handling
   process.on('SIGTERM', () => {
     server.close(() => process.exit(0));
   });

   // Exception handling
   process.on('uncaughtException', (error) => {
     logger.logSecurityEvent('uncaught_exception', error);
     process.exit(1);
   });
   ```

2. **Resource Limits**
   - Max body size: 10 MB
   - Request timeout: 30 seconds
   - Connection pool: 2-20
   - Database idle timeout: 15 minutes

3. **Health Checks**
   - `/health` - Basic status
   - `/health/detailed` - Full system status
   - Database connectivity checks

---

## Incident Response

### Monitoring & Alerting

Set up alerts for:
1. **Authentication Failures**
   - Multiple failed login attempts
   - Invalid token access

2. **Rate Limit Triggers**
   - Unusual traffic patterns
   - Potential DDoS

3. **Error Spikes**
   - Unexpected 5xx errors
   - Database connection failures

4. **Security Events**
   - Unauthorized access attempts
   - Validation errors

### Response Checklist

If breach is suspected:
1. ✅ Enable audit logging
2. ✅ Preserve logs (don't truncate)
3. ✅ Rotate JWT_SECRET
4. ✅ Revoke active sessions
5. ✅ Notify affected users
6. ✅ Patch vulnerabilities
7. ✅ Review access logs
8. ✅ Update security policies

---

## Compliance

### Supported Standards

1. **GDPR** (General Data Protection Regulation)
   - Data retention policies
   - Right to be forgotten
   - Audit logging enabled
   - Privacy by design

2. **CCPA** (California Consumer Privacy Act)
   - Data access controls
   - Deletion capabilities
   - Privacy notices

3. **HIPAA** (if handling health data)
   - Encryption at rest and in transit
   - Access controls
   - Audit trails

### Security Checklist

- [ ] Encryption enabled for all sensitive data
- [ ] HTTPS enforced in production
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] RBAC properly configured
- [ ] Audit logging enabled
- [ ] Database backups configured
- [ ] Security headers implemented
- [ ] CORS properly restricted
- [ ] Dependencies up to date
- [ ] Regular security audits scheduled
- [ ] Incident response plan in place

---

## Maintenance & Updates

### Dependency Updates

```bash
# Check for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

# Stay updated
npm outdated
```

### Security Updates

1. **Node.js**: Update to latest LTS
2. **Express**: Update minor/patch versions regularly
3. **Security Packages**: Update immediately on release

### Regular Tasks

- **Weekly**: Review error logs
- **Monthly**: Dependency updates, security audit
- **Quarterly**: Penetration testing, access review
- **Annually**: Full security assessment

---

## Contact & Support

For security issues, please follow responsible disclosure:

1. Do NOT create public GitHub issues
2. Email: security@spaceshare.dev
3. Include detailed description and steps to reproduce
4. Allow 48 hours for initial response

---

**Last Updated:** February 2024  
**Version:** 1.0.0  
**Status:** Production Ready
