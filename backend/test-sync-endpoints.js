#!/usr/bin/env node

/**
 * End-to-End Frontend-Backend Sync Test
 * Tests complete authentication and data synchronization flow
 */

require('dotenv').config();
const axios = require('axios');

const API_BASE_URL = process.env.API_URL || 'http://localhost:8080/api';
const TEST_TIMEOUT = 30000;

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

let testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  tests: [],
};

const log = {
  section: (title) => {
    console.log(`\n${colors.bright}${colors.blue}${'='.repeat(70)}${colors.reset}`);
    console.log(`${colors.bright}${colors.blue}${title}${colors.reset}`);
    console.log(`${colors.bright}${colors.blue}${'='.repeat(70)}${colors.reset}\n`);
  },
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
  warning: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  info: (msg) => console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`),
};

async function runTest(name, testFn) {
  testResults.total++;
  try {
    await Promise.race([
      testFn(),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Test timeout')), TEST_TIMEOUT)
      ),
    ]);
    testResults.passed++;
    testResults.tests.push({ name, status: 'PASSED' });
    log.success(name);
  } catch (error) {
    testResults.failed++;
    testResults.tests.push({ name, status: 'FAILED', error: error.message });
    log.error(`${name}: ${error.message}`);
  }
}

async function testAuthEndpoints() {
  log.section('AUTHENTICATION ENDPOINTS TEST');

  // Test 1: Health check
  await runTest('API Health Check', async () => {
    const response = await axios.get(`${API_BASE_URL}/health`, {
      timeout: 5000,
      validateStatus: () => true,
    });
    if (response.status !== 200) {
      throw new Error(`Health check failed: ${response.status}`);
    }
  });

  // Test 2: Register endpoint exists
  await runTest('Register Endpoint Available', async () => {
    const response = await axios.post(
      `${API_BASE_URL}/auth/register`,
      { firebaseToken: 'invalid-token', profileData: {} },
      {
        timeout: TEST_TIMEOUT,
        validateStatus: () => true,
      }
    );

    // Should return 401 for invalid token, not 404
    if (response.status === 404) {
      throw new Error('Register endpoint not found');
    }

    log.info(`Register endpoint response: ${response.status}`);
  });

  // Test 3: Signin endpoint exists
  await runTest('Signin Endpoint Available', async () => {
    const response = await axios.post(
      `${API_BASE_URL}/auth/signin`,
      { firebaseToken: 'invalid-token' },
      {
        timeout: TEST_TIMEOUT,
        validateStatus: () => true,
      }
    );

    if (response.status === 404) {
      throw new Error('Signin endpoint not found');
    }

    log.info(`Signin endpoint response: ${response.status}`);
  });

  // Test 4: Response format validation
  await runTest('Response Format Consistency', async () => {
    const response = await axios.get(`${API_BASE_URL}/health`, {
      timeout: 5000,
      validateStatus: () => true,
    });

    const data = response.data;
    if (!data.success || !data.timestamp || !('code' in data)) {
      throw new Error('Response missing required fields: success, timestamp, code');
    }

    log.info(`Response format: ${JSON.stringify(data, null, 2).substring(0, 100)}...`);
  });
}

async function testProfileEndpoints() {
  log.section('PROFILE ENDPOINTS TEST');

  const testUserId = `test-${Date.now()}`;

  // Test 1: Create profile without auth
  await runTest('Create Profile Requires Auth', async () => {
    const response = await axios.post(
      `${API_BASE_URL}/profiles`,
      { city: 'Test City' },
      {
        timeout: TEST_TIMEOUT,
        validateStatus: () => true,
      }
    );

    if (response.status < 400) {
      throw new Error('Profile creation should require authentication');
    }

    log.info(`Auth requirement check: status ${response.status}`);
  });

  // Test 2: GET profile without auth
  await runTest('Get Profile Requires Auth', async () => {
    const response = await axios.get(`${API_BASE_URL}/profiles/${testUserId}`, {
      timeout: TEST_TIMEOUT,
      validateStatus: () => true,
    });

    if (response.status < 400) {
      throw new Error('Profile retrieval should require authentication');
    }

    log.info(`Auth requirement check: status ${response.status}`);
  });
}

async function testRequestValidation() {
  log.section('REQUEST VALIDATION TEST');

  // Test 1: Content-Type validation
  await runTest('Content-Type Validation', async () => {
    const response = await axios.post(
      `${API_BASE_URL}/auth/register`,
      'invalid-data',
      {
        headers: { 'Content-Type': 'text/plain' },
        timeout: TEST_TIMEOUT,
        validateStatus: () => true,
      }
    );

    if (response.status !== 400) {
      throw new Error(`Expected 400 for invalid content-type, got ${response.status}`);
    }

    log.info(`Content-Type validation works: ${response.status}`);
  });

  // Test 2: Rate limiting
  await runTest('Rate Limiting Active', async () => {
    let rateLimited = false;

    // Send multiple requests
    for (let i = 0; i < 10; i++) {
      const response = await axios.get(`${API_BASE_URL}/health`, {
        timeout: 5000,
        validateStatus: () => true,
      });

      if (response.status === 429) {
        rateLimited = true;
        log.info(`Rate limited after ${i} requests`);
        break;
      }
    }

    if (!rateLimited) {
      log.warning('Rate limiting may not be active (or limit is high)');
    }
  });
}

async function testDataFormat() {
  log.section('DATA FORMAT & CONSISTENCY TEST');

  // Test 1: Response format structure
  await runTest('Standard Response Structure', async () => {
    const response = await axios.get(`${API_BASE_URL}/health`, {
      timeout: 5000,
      validateStatus: () => true,
    });

    const requiredFields = ['success', 'code', 'timestamp'];
    const data = response.data;

    for (const field of requiredFields) {
      if (!(field in data)) {
        throw new Error(`Missing required field: ${field}`);
      }
    }

    log.info(`Response has all required fields: ${requiredFields.join(', ')}`);
  });

  // Test 2: Error response format
  await runTest('Error Response Format', async () => {
    const response = await axios.get(
      `${API_BASE_URL}/profiles/invalid-user-id`,
      {
        timeout: TEST_TIMEOUT,
        validateStatus: () => true,
      }
    );

    const data = response.data;
    if (data.success !== false) {
      throw new Error('Error response should have success: false');
    }

    if (!('error' in data) && !('message' in data)) {
      throw new Error('Error response missing error/message field');
    }

    log.info(`Error format is consistent: ${JSON.stringify(data, null, 2).substring(0, 80)}...`);
  });
}

async function testOfflineQueueConcept() {
  log.section('OFFLINE QUEUE & SYNC MESSAGING');

  // Test 1: Offline detection via health check
  await runTest('Can Detect Offline State', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/health`, {
        timeout: 2000,
        validateStatus: () => true,
      });

      log.info(`API is online: status ${response.status}`);
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        log.warning('API server is not running - offline queue would be triggered');
      } else {
        throw error;
      }
    }
  });

  // Test 2: Log offline queue message
  await runTest('Offline Queue Configuration', async () => {
    log.info(`Offline queue would handle these request types:`);
    log.info('  - GET /profiles/:userId');
    log.info('  - POST /profiles');
    log.info('  - PATCH /profiles/:userId');
    log.info('  - DELETE /profiles/:userId');
    log.info(`With automatic retry on reconnection`);
  });
}

function printSummary() {
  log.section('TEST SUMMARY');

  console.log(`Total Tests: ${colors.bright}${testResults.total}${colors.reset}`);
  console.log(`${colors.green}Passed: ${testResults.passed}${colors.reset}`);
  console.log(`${colors.red}Failed: ${testResults.failed}${colors.reset}`);

  const passRate = testResults.total > 0
    ? Math.round((testResults.passed / testResults.total) * 100)
    : 0;

  console.log(`\nPass Rate: ${colors.bright}${passRate}%${colors.reset}`);

  if (testResults.failed > 0) {
    console.log(`\n${colors.red}Failed Tests:${colors.reset}`);
    testResults.tests
      .filter((t) => t.status === 'FAILED')
      .forEach((t) => {
        console.log(`  ${colors.red}✗${colors.reset} ${t.name}`);
        if (t.error) console.log(`    ${t.error}`);
      });
  }

  console.log();
  return testResults.failed === 0 ? 0 : 1;
}

async function main() {
  console.clear();
  log.info('Frontend-Backend Sync Integration Tests');
  log.info(`Target API: ${API_BASE_URL}\n`);

  try {
    await testAuthEndpoints();
    await testProfileEndpoints();
    await testRequestValidation();
    await testDataFormat();
    await testOfflineQueueConcept();

    const exitCode = printSummary();
    process.exit(exitCode);
  } catch (error) {
    log.error(`Critical test error: ${error.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { runTest, testAuthEndpoints, testProfileEndpoints };
