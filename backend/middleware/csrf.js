const crypto = require('crypto');

const csrfTokens = new Map();

const generateCSRFToken = (sessionId) => {
  const token = crypto.randomBytes(32).toString('hex');
  csrfTokens.set(sessionId, {
    token,
    createdAt: Date.now(),
    expiresAt: Date.now() + 3600000, // 1 hour
  });
  return token;
};

const validateCSRFToken = (sessionId, token) => {
  const storedToken = csrfTokens.get(sessionId);
  
  if (!storedToken) {
    return false;
  }

  if (storedToken.expiresAt < Date.now()) {
    csrfTokens.delete(sessionId);
    return false;
  }

  return crypto.timingSafeEqual(
    Buffer.from(storedToken.token),
    Buffer.from(token)
  );
};

const csrfProtection = (req, res, next) => {
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
    return next();
  }

  const sessionId = req.user?.userId || req.ip;
  const csrfToken = req.headers['x-csrf-token'] || req.body?.csrfToken;

  if (!csrfToken || !validateCSRFToken(sessionId, csrfToken)) {
    return res.status(403).json({
      success: false,
      error: 'CSRF token validation failed',
      code: 'CSRF_INVALID',
    });
  }

  next();
};

module.exports = {
  generateCSRFToken,
  validateCSRFToken,
  csrfProtection,
};
