const jwt = require('jsonwebtoken');
const crypto = require('crypto');

/**
 * Enhanced Token Verification with Security Checks
 * Supports both JWT tokens and Firebase ID tokens for flexibility during auth flow
 */
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  // In production, authentication is mandatory
  if (!token) {
    if (process.env.NODE_ENV === 'production') {
      return res.status(401).json({
        success: false,
        error: 'Authentication required. No token provided.',
        code: 'NO_TOKEN',
      });
    }

    // Development mode: allow with Firebase UID or anonymous
    const firebaseUid = req.headers['x-user-id'];
    if (firebaseUid && isValidUserId(firebaseUid)) {
      req.user = { userId: firebaseUid, role: 'user', isAuthenticated: false };
      return next();
    }

    return res.status(401).json({
      success: false,
      error: 'No valid user identification provided.',
    });
  }

  try {
    // Try to verify as JWT first
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: [process.env.JWT_ALGORITHM || 'HS256'],
    });

    // Additional security checks
    if (!decoded.userId || !decoded.iat) {
      return res.status(401).json({
        success: false,
        error: 'Invalid token structure.',
        code: 'INVALID_TOKEN',
      });
    }

    // Check token age (prevent old tokens)
    const tokenAge = Math.floor(Date.now() / 1000) - decoded.iat;
    const maxAge = 30 * 24 * 60 * 60; // 30 days
    if (tokenAge > maxAge) {
      return res.status(401).json({
        success: false,
        error: 'Token has expired.',
        code: 'TOKEN_EXPIRED',
      });
    }

    // Attach user info to request
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role || 'user',
      isAuthenticated: true,
      issuedAt: new Date(decoded.iat * 1000),
      isJWT: true,
    };

    // Store token for potential revocation checks
    req.token = token;

    next();
  } catch (error) {
    // Distinguish between different JWT errors
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token has expired.',
        code: 'TOKEN_EXPIRED',
        expiredAt: error.expiredAt,
      });
    }

    // Try Firebase token verification as fallback
    if (error.name === 'JsonWebTokenError') {
      // Only try Firebase verification if we have Firebase SDK available
      try {
        const { admin } = require('../firebase');
        if (!admin) {
          return res.status(401).json({
            success: false,
            error: 'Invalid token.',
            code: 'INVALID_TOKEN',
          });
        }

        // Try to verify as Firebase ID token
        admin
          .auth()
          .verifyIdToken(token)
          .then((decodedToken) => {
            // Firebase token is valid, attach user info
            req.user = {
              userId: decodedToken.uid,
              email: decodedToken.email,
              role: 'user',
              isAuthenticated: true,
              isFirebaseToken: true,
            };
            req.token = token;
            next();
          })
          .catch(() => {
            // Both JWT and Firebase verification failed
            return res.status(401).json({
              success: false,
              error: 'Invalid token.',
              code: 'INVALID_TOKEN',
            });
          });
        return; // Exit early since Firebase verification is async
      } catch (firebaseError) {
        return res.status(401).json({
          success: false,
          error: 'Invalid token.',
          code: 'INVALID_TOKEN',
        });
      }
    }

    res.status(401).json({
      success: false,
      error: 'Authentication failed.',
      code: 'AUTH_FAILED',
    });
  }
};

/**
 * Validate User Authorization for Specific Resources
 */
const authorizeUser = (requiredRole = 'user') => {
  return (req, res, next) => {
    if (!req.user || !req.user.isAuthenticated) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required.',
      });
    }

    const roleHierarchy = {
      admin: 3,
      moderator: 2,
      user: 1,
    };

    const userLevel = roleHierarchy[req.user.role] || 0;
    const requiredLevel = roleHierarchy[requiredRole] || 1;

    if (userLevel < requiredLevel) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions.',
        code: 'FORBIDDEN',
      });
    }

    next();
  };
};

/**
 * Verify User Ownership of Resource
 */
const verifyResourceOwnership = (paramName = 'userId') => {
  return (req, res, next) => {
    if (!req.user || !req.user.isAuthenticated) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required.',
      });
    }

    const resourceOwnerId = req.params[paramName];

    // Admins can access any resource
    if (req.user.role === 'admin') {
      return next();
    }

    // Users can only access their own resources
    if (req.user.userId !== resourceOwnerId) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to access this resource.',
        code: 'FORBIDDEN',
      });
    }

    next();
  };
};

/**
 * Generate Secure JWT Token
 */
const generateToken = (userId, email, role = 'user') => {
  if (!userId || !email) {
    throw new Error('userId and email are required to generate token');
  }

  const payload = {
    userId,
    email,
    role,
    iat: Math.floor(Date.now() / 1000),
  };

  const token = jwt.sign(payload, process.env.JWT_SECRET, {
    algorithm: process.env.JWT_ALGORITHM || 'HS256',
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });

  return token;
};

/**
 * Generate Refresh Token
 */
const generateRefreshToken = (userId) => {
  const payload = {
    userId,
    type: 'refresh',
    iat: Math.floor(Date.now() / 1000),
  };

  const token = jwt.sign(payload, process.env.JWT_SECRET, {
    algorithm: process.env.JWT_ALGORITHM || 'HS256',
    expiresIn: process.env.JWT_REFRESH_EXPIRE || '30d',
  });

  return token;
};

/**
 * Validate User ID Format
 */
const isValidUserId = (userId) => {
  if (!userId || typeof userId !== 'string') {
    return false;
  }

  // Firebase UIDs are typically 28 characters
  // Allow email format as well
  const firebaseUidRegex = /^[a-zA-Z0-9_-]{20,}$/;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  return firebaseUidRegex.test(userId) || emailRegex.test(userId);
};

/**
 * Hash Sensitive Data
 */
const hashSensitiveData = (data) => {
  return crypto.createHash('sha256').update(data).digest('hex');
};

module.exports = {
  verifyToken,
  authorizeUser,
  verifyResourceOwnership,
  generateToken,
  generateRefreshToken,
  isValidUserId,
  hashSensitiveData,
};
