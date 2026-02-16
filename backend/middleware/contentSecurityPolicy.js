const cryptoHash = require('crypto');

class ContentSecurityPolicy {
  constructor() {
    this.cspHeaders = this.generateCSP();
  }

  generateCSP() {
    return {
      'default-src': ["'self'"],
      'script-src': ["'self'", "'unsafe-inline'"], // Tighten in production
      'style-src': ["'self'", "'unsafe-inline'"],
      'img-src': ["'self'", 'data:', 'https:'],
      'font-src': ["'self'", 'data:', 'https:'],
      'connect-src': ["'self'"],
      'media-src': ["'self'"],
      'object-src': ["'none'"],
      'frame-src': ["'none'"],
      'base-uri': ["'self'"],
      'form-action': ["'self'"],
      'frame-ancestors': ["'none'"],
      'upgrade-insecure-requests': [],
      'block-all-mixed-content': [],
    };
  }

  getCSPHeader() {
    return Object.entries(this.cspHeaders)
      .map(([key, values]) => {
        if (values.length === 0) return key;
        return `${key} ${values.join(' ')}`;
      })
      .join('; ');
  }

  cspMiddleware() {
    return (req, res, next) => {
      res.setHeader('Content-Security-Policy', this.getCSPHeader());
      res.setHeader('X-Content-Security-Policy', this.getCSPHeader());
      next();
    };
  }

  validateNonce(nonce) {
    // Validate CSP nonce format
    return /^[a-zA-Z0-9+/=]{32,}$/.test(nonce);
  }
}

module.exports = new ContentSecurityPolicy();
