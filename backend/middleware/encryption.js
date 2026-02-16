const crypto = require('crypto');

class EncryptionManager {
  constructor() {
    this.algorithm = 'aes-256-gcm';
    const secret = process.env.ENCRYPTION_KEY || process.env.JWT_SECRET || 'default-test-secret-key-min-32-chars';
    this.encryptionKey = this.deriveKey(secret);
  }

  deriveKey(secret) {
    return crypto.scryptSync(secret, 'salt', 32);
  }

  encrypt(data) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.encryptionKey, iv);
    
    let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      iv: iv.toString('hex'),
      encrypted,
      authTag: authTag.toString('hex'),
    };
  }

  decrypt(encryptedData) {
    const decipher = crypto.createDecipheriv(
      this.algorithm,
      this.encryptionKey,
      Buffer.from(encryptedData.iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
    
    let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return JSON.parse(decrypted);
  }

  hashPassword(password) {
    const bcrypt = require('bcryptjs');
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512');
    return `${salt}$${hash.toString('hex')}`;
  }

  verifyPassword(password, hash) {
    const bcrypt = require('bcryptjs');
    const [salt, originalHash] = hash.split('$');
    const newHash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512');
    return newHash.toString('hex') === originalHash;
  }

  generateSecureToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
  }

  signData(data) {
    const hmac = crypto.createHmac('sha256', this.encryptionKey);
    hmac.update(JSON.stringify(data));
    return hmac.digest('hex');
  }

  verifySignature(data, signature) {
    const expectedSignature = this.signData(data);
    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  }
}

module.exports = new EncryptionManager();
