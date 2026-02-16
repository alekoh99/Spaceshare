const crypto = require('crypto');

class TwoFactorAuthManager {
  constructor() {
    this.sessions = new Map();
    this.backupCodes = new Map();
  }

  generateSecret(userId) {
    const secret = crypto.randomBytes(32).toString('hex');
    const backupCodes = this.generateBackupCodes(8);

    this.sessions.set(userId, {
      secret,
      backupCodes,
      createdAt: new Date(),
      verified: false,
    });

    return {
      secret,
      backupCodes,
    };
  }

  generateBackupCodes(count = 8) {
    const codes = [];
    for (let i = 0; i < count; i++) {
      codes.push(crypto.randomBytes(4).toString('hex').toUpperCase());
    }
    return codes;
  }

  generateTOTP(secret) {
    let time = Math.floor(Date.now() / 1000 / 30);
    const timeBytes = Buffer.alloc(8);
    for (let i = 7; i >= 0; i--) {
      timeBytes[i] = time & 0xff;
      time >>= 8;
    }

    const hmac = crypto.createHmac('sha1', Buffer.from(secret, 'hex'));
    hmac.update(timeBytes);
    const digest = hmac.digest();

    const offset = digest[digest.length - 1] & 0xf;
    const code = (
      ((digest[offset] & 0x7f) << 24) |
      ((digest[offset + 1] & 0xff) << 16) |
      ((digest[offset + 2] & 0xff) << 8) |
      (digest[offset + 3] & 0xff)
    ) % 1000000;

    return String(code).padStart(6, '0');
  }

  verifyTOTP(userId, code) {
    const session = this.sessions.get(userId);
    if (!session) return false;

    const currentCode = this.generateTOTP(session.secret);
    return code === currentCode;
  }

  verifyBackupCode(userId, code) {
    const session = this.sessions.get(userId);
    if (!session) return false;

    const index = session.backupCodes.indexOf(code.toUpperCase());
    if (index === -1) return false;

    session.backupCodes.splice(index, 1);
    return true;
  }

  enableTwoFactor(userId) {
    const session = this.sessions.get(userId);
    if (session) {
      session.verified = true;
      session.enabledAt = new Date();
      return true;
    }
    return false;
  }

  disableTwoFactor(userId) {
    this.sessions.delete(userId);
    return true;
  }

  isEnabled(userId) {
    const session = this.sessions.get(userId);
    return session && session.verified;
  }
}

module.exports = new TwoFactorAuthManager();
