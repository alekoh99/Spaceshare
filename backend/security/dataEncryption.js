const crypto = require('crypto');

class DataEncryption {
  constructor() {
    this.algorithm = 'aes-256-gcm';
    const secret = process.env.ENCRYPTION_KEY || process.env.JWT_SECRET || 'default-test-secret-key-min-32-chars';
    this.encryptionKey = this.deriveKey(secret);
  }

  deriveKey(secret) {
    return crypto.scryptSync(secret, 'salt', 32);
  }

  encryptField(value, fieldName = '') {
    if (value === null || value === undefined) return null;

    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.encryptionKey, iv);

    let encrypted = cipher.update(String(value), 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return JSON.stringify({
      encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex'),
      algorithm: this.algorithm,
    });
  }

  decryptField(encryptedData) {
    if (!encryptedData) return null;

    try {
      const data = JSON.parse(encryptedData);
      const decipher = crypto.createDecipheriv(
        data.algorithm,
        this.encryptionKey,
        Buffer.from(data.iv, 'hex')
      );

      decipher.setAuthTag(Buffer.from(data.authTag, 'hex'));

      let decrypted = decipher.update(data.encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return decrypted;
    } catch (error) {
      throw new Error('Failed to decrypt field');
    }
  }

  encryptObject(obj, fieldsToEncrypt = []) {
    const encrypted = { ...obj };

    fieldsToEncrypt.forEach((field) => {
      if (encrypted[field] !== undefined) {
        encrypted[field] = this.encryptField(encrypted[field], field);
      }
    });

    return encrypted;
  }

  decryptObject(obj, fieldsToDecrypt = []) {
    const decrypted = { ...obj };

    fieldsToDecrypt.forEach((field) => {
      if (decrypted[field] !== undefined) {
        decrypted[field] = this.decryptField(decrypted[field]);
      }
    });

    return decrypted;
  }

  generateDataKey() {
    return crypto.randomBytes(32).toString('hex');
  }

  hashField(value) {
    return crypto.createHash('sha256').update(String(value)).digest('hex');
  }

  verifyHashField(value, hash) {
    return this.hashField(value) === hash;
  }

  obscureValue(value, visibleChars = 4) {
    const str = String(value);
    const visible = str.slice(0, visibleChars);
    const hidden = '*'.repeat(Math.max(0, str.length - visibleChars));
    return visible + hidden;
  }
}

module.exports = new DataEncryption();
