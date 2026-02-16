require('dotenv').config();
const crypto = require('crypto');

// ════════════════════════════════════════════════════════════════
// ENVIRONMENT VALIDATION
// ════════════════════════════════════════════════════════════════

const validateEnvironment = () => {
  const errors = [];
  const warnings = [];

  // Critical environment variables
  const criticalVars = [
    'JWT_SECRET',
    'NODE_ENV',
    'DATABASE_URL',
  ];

  criticalVars.forEach((variable) => {
    if (!process.env[variable]) {
      errors.push(`Missing critical environment variable: ${variable}`);
    }
  });

  // Optional but recommended variables
  const recommendedVars = [
    'ENCRYPTION_KEY',
    'FIREBASE_SERVICE_ACCOUNT_PATH',
    'CORS_ORIGIN',
  ];

  recommendedVars.forEach((variable) => {
    if (!process.env[variable]) {
      warnings.push(`Missing recommended environment variable: ${variable}`);
    }
  });

  // Production-specific checks
  if (process.env.NODE_ENV === 'production') {
    // JWT Secret strength
    if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
      errors.push('JWT_SECRET must be at least 32 characters long');
    }

    // CORS configuration
    if (
      process.env.CORS_ORIGIN &&
      process.env.CORS_ORIGIN.includes('*')
    ) {
      errors.push('CORS_ORIGIN cannot use wildcard (*) in production');
    }

    // HTTPS enforcement
    if (process.env.TRUST_PROXY !== 'true') {
      warnings.push('TRUST_PROXY should be true if behind reverse proxy');
    }
  }

  // Encryption key validation
  if (process.env.ENCRYPTION_KEY && process.env.ENCRYPTION_KEY.length < 32) {
    warnings.push('ENCRYPTION_KEY should be at least 32 characters long');
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings,
  };
};

// ════════════════════════════════════════════════════════════════
// SECRET STRENGTH VALIDATION
// ════════════════════════════════════════════════════════════════

const validateSecretStrength = (secret, minLength = 32) => {
  const issues = [];

  if (!secret) {
    return { valid: false, issues: ['Secret is empty'] };
  }

  if (secret.length < minLength) {
    issues.push(
      `Secret length (${secret.length}) is less than minimum (${minLength})`
    );
  }

  if (!/[a-z]/.test(secret)) {
    issues.push('Secret must contain lowercase letters');
  }

  if (!/[A-Z]/.test(secret)) {
    issues.push('Secret must contain uppercase letters');
  }

  if (!/\d/.test(secret)) {
    issues.push('Secret must contain numbers');
  }

  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(secret)) {
    issues.push('Secret must contain special characters');
  }

  return {
    valid: issues.length === 0,
    issues,
    entropy: calculateEntropy(secret),
  };
};

// ════════════════════════════════════════════════════════════════
// ENTROPY CALCULATION
// ════════════════════════════════════════════════════════════════

const calculateEntropy = (str) => {
  const len = str.length;
  const frequencies = {};

  for (let i = 0; i < len; i++) {
    const char = str[i];
    frequencies[char] = (frequencies[char] || 0) + 1;
  }

  let entropy = 0;
  for (const freq of Object.values(frequencies)) {
    const p = freq / len;
    entropy -= p * Math.log2(p);
  }

  return Math.round(entropy * 100) / 100; // bits per character
};

// ════════════════════════════════════════════════════════════════
// FILE PERMISSIONS CHECK
// ════════════════════════════════════════════════════════════════

const checkFilePermissions = () => {
  const fs = require('fs');
  const path = require('path');

  const files = [
    '.env',
    'serviceAccountKey.json',
    '.env.local',
  ];

  const issues = [];

  files.forEach((file) => {
    const filePath = path.join(process.cwd(), file);
    try {
      const stats = fs.statSync(filePath);
      const mode = stats.mode & parseInt('777', 8);

      // Should be readable only by owner (400 or 600)
      if ((mode & parseInt('077', 8)) !== 0) {
        issues.push(
          `${file} has insecure permissions: ${mode.toString(8)}. Should be 400 or 600`
        );
      }
    } catch (err) {
      // File doesn't exist, skip
    }
  });

  return {
    secure: issues.length === 0,
    issues,
  };
};

// ════════════════════════════════════════════════════════════════
// SECURITY AUDIT
// ════════════════════════════════════════════════════════════════

const runSecurityAudit = () => {
  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║          SPACESHARE SECURITY CONFIGURATION AUDIT               ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  // Environment validation
  console.log('📋 ENVIRONMENT VALIDATION');
  const envValidation = validateEnvironment();
  if (envValidation.isValid) {
    console.log('   ✅ All critical environment variables are set');
  } else {
    console.log('   ❌ ERRORS:');
    envValidation.errors.forEach((error) => console.log(`      - ${error}`));
  }

  if (envValidation.warnings.length > 0) {
    console.log('   ⚠️  WARNINGS:');
    envValidation.warnings.forEach((warning) =>
      console.log(`      - ${warning}`)
    );
  }

  // Secret strength validation
  console.log('\n🔐 SECRET STRENGTH VALIDATION');
  const jwtValidation = validateSecretStrength(
    process.env.JWT_SECRET,
    32
  );
  console.log(`   JWT_SECRET: ${jwtValidation.valid ? '✅' : '❌'}`);
  if (jwtValidation.issues.length > 0) {
    jwtValidation.issues.forEach((issue) => console.log(`      - ${issue}`));
  }
  console.log(`   Entropy: ${jwtValidation.entropy} bits/char (Target: 4.0+)`);

  // File permissions
  console.log('\n📁 FILE PERMISSIONS');
  const filePerms = checkFilePermissions();
  if (filePerms.secure) {
    console.log('   ✅ All sensitive files have secure permissions');
  } else {
    console.log('   ❌ ISSUES:');
    filePerms.issues.forEach((issue) => console.log(`      - ${issue}`));
  }

  // Node environment
  console.log(`\n🌍 ENVIRONMENT: ${process.env.NODE_ENV || 'not set'}`);
  if (process.env.NODE_ENV === 'production') {
    console.log('   ⚠️  Production mode active - ensure all security measures are in place');
  }

  console.log('\n════════════════════════════════════════════════════════════════\n');

  return {
    environment: envValidation,
    secrets: jwtValidation,
    filePermissions: filePerms,
  };
};

module.exports = {
  validateEnvironment,
  validateSecretStrength,
  calculateEntropy,
  checkFilePermissions,
  runSecurityAudit,
};
