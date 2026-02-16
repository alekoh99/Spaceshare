const crypto = require('crypto');

class RequestSigner {
  constructor() {
    this.signingKey = process.env.REQUEST_SIGNING_KEY || crypto.randomBytes(32).toString('hex');
  }

  signRequest(method, path, body = null) {
    const timestamp = Math.floor(Date.now() / 1000);
    const content = `${method}:${path}:${timestamp}:${JSON.stringify(body || {})}`;
    
    const signature = crypto
      .createHmac('sha256', this.signingKey)
      .update(content)
      .digest('hex');

    return {
      signature,
      timestamp,
    };
  }

  verifySignature(req) {
    const signature = req.headers['x-signature'];
    const timestamp = parseInt(req.headers['x-timestamp']);

    if (!signature || !timestamp) {
      return false;
    }

    // Check timestamp is within 5 minutes
    const currentTime = Math.floor(Date.now() / 1000);
    if (Math.abs(currentTime - timestamp) > 300) {
      return false;
    }

    const content = `${req.method}:${req.path}:${timestamp}:${JSON.stringify(req.body || {})}`;
    const expectedSignature = crypto
      .createHmac('sha256', this.signingKey)
      .update(content)
      .digest('hex');

    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  }
}

const signer = new RequestSigner();

const requestSigningMiddleware = (req, res, next) => {
  // Skip for public endpoints
  if (req.path === '/health' || req.path.startsWith('/api/public')) {
    return next();
  }

  if (!signer.verifySignature(req)) {
    return res.status(401).json({
      success: false,
      error: 'Invalid request signature',
      code: 'INVALID_SIGNATURE',
    });
  }

  next();
};

module.exports = {
  signer,
  requestSigningMiddleware,
};
