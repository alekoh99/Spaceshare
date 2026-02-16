const { runTests } = require('./security/tests');

console.log('\n🔒 Running SpaceShare Security Tests...\n');

const success = runTests();

if (success) {
  console.log('✅ All security modules verified successfully!');
  console.log('\nYour application is protected by:');
  console.log('  ✓ Two-Factor Authentication (2FA)');
  console.log('  ✓ IP Whitelist Management');
  console.log('  ✓ Account Lockout Protection');
  console.log('  ✓ Password Reset Security');
  console.log('  ✓ Session Management');
  console.log('  ✓ Data Encryption (AES-256-GCM)');
  console.log('  ✓ Vulnerability Scanning (XSS, SQL Injection, etc)');
  console.log('  ✓ SQL Injection Prevention');
  console.log('  ✓ API Key Management & Rotation');
  console.log('  ✓ Anti-DDoS Protection');
  console.log('  ✓ Role-Based Access Control');
  console.log('  ✓ Token Blacklist Management');
  console.log('  ✓ Rate Limiting');
  console.log('  ✓ CSRF Protection');
  console.log('  ✓ Security Headers (Helmet, CSP)');
  console.log('  ✓ Input Validation & Sanitization');
  console.log('  ✓ Audit Logging');
  console.log('  ✓ Data Redaction');
  console.log('\n🚀 Ready for production deployment!\n');
  process.exit(0);
} else {
  console.log('❌ Some security tests failed. Review the errors above.');
  process.exit(1);
}
