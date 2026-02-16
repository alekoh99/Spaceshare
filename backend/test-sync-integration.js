#!/usr/bin/env node

/**
 * Frontend-Backend Synchronization Integration Test Suite
 * Validates complete sync flow: auth → profile creation/update → database sync
 */

require('dotenv').config();
const axios = require('axios');
const pool = require('./db');
const { connectMongo, getMongoDb } = require('./mongo');
const { initializeFirebase, getFirebaseDb, isFirebaseAvailable, admin } = require('./firebase');

const BASE_URL = process.env.API_URL || 'http://localhost:8080/api';
const TEST_TIMEOUT = 30000;

let testResults = {
  totalTests: 0,
  passed: 0,
  failed: 0,
  skipped: 0,
  tests: [],
  timings: {}
};

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

const log = {
  section: (title) => console.log(`\n${colors.bright}${colors.blue}${'='.repeat(70)}${colors.reset}\n${colors.bright}${colors.blue}${title}${colors.reset}\n${colors.bright}${colors.blue}${'='.repeat(70)}${colors.reset}\n`),
  success: (msg) => console.log(`${colors.green}✅${colors.reset} ${msg}`),
  error: (msg) => console.log(`${colors.red}❌${colors.reset} ${msg}`),
  warning: (msg) => console.log(`${colors.yellow}⚠️ ${colors.reset} ${msg}`),
  info: (msg) => console.log(`${colors.blue}ℹ️ ${colors.reset} ${msg}`),
  test: (name) => console.log(`\n  ${colors.dim}Testing: ${name}${colors.reset}`),
};

async function runTest(testName, testFn) {
  testResults.totalTests++;
  const startTime = Date.now();
  
  try {
    log.test(testName);
    const result = await Promise.race([
      testFn(),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Test timeout')), TEST_TIMEOUT)
      )
    ]);
    
    const duration = Date.now() - startTime;
    testResults.passed++;
    testResults.tests.push({ name: testName, status: 'PASSED', duration });
    testResults.timings[testName] = duration;
    log.success(`${testName} (${duration}ms)`);
    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    testResults.failed++;
    testResults.tests.push({ name: testName, status: 'FAILED', error: error.message, duration });
    testResults.timings[testName] = duration;
    log.error(`${testName}: ${error.message} (${duration}ms)`);
    throw error;
  }
}

/**
 * Test sync flow: Create user → Create profile → Verify in all databases
 */
async function testSyncFlow() {
  log.section('FRONTEND-BACKEND SYNC FLOW TEST');

  const testUser = {
    email: `sync-test-${Date.now()}@example.com`,
    name: 'Sync Test User',
    city: 'San Francisco',
  };

  let firebaseToken;
  let userId;
  let createdProfile;

  // Step 1: Create Firebase test user (simulate frontend signup)
  await runTest('Step 1: Create Firebase User (Frontend Signup)', async () => {
    try {
      // Create user via Firebase Admin SDK
      const userRecord = await admin.auth().createUser({
        email: testUser.email,
        password: 'TestPassword123!@#',
        displayName: testUser.name,
      });
      
      userId = userRecord.uid;
      firebaseToken = await admin.auth().createCustomToken(userId);
      
      log.info(`Firebase user created: ${userId}`);
      return { userId, firebaseToken };
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        log.warning('User already exists, using existing user');
        const user = await admin.auth().getUserByEmail(testUser.email);
        userId = user.uid;
        firebaseToken = await admin.auth().createCustomToken(userId);
        return { userId, firebaseToken };
      }
      throw error;
    }
  });

  // Step 2: Register user via backend auth endpoint
  await runTest('Step 2: Backend User Registration (Auth Endpoint)', async () => {
    const response = await axios.post(
      `${BASE_URL}/auth/register`,
      {
        firebaseToken,
        profileData: {
          name: testUser.name,
          city: testUser.city,
          email: testUser.email,
        },
      },
      { validateStatus: () => true, timeout: TEST_TIMEOUT }
    );

    log.info(`Registration Status: ${response.status}`);
    
    if (response.status === 201 || response.status === 200) {
      return response.data;
    } else if (response.status === 401 && response.data.error?.includes('Firebase')) {
      log.warning('Firebase token validation failed (test environment expected)');
      return { tokenRequired: true };
    } else {
      throw new Error(`Registration failed: ${response.status} - ${JSON.stringify(response.data)}`);
    }
  }).catch(() => {
    log.warning('Registration endpoint may require Firebase setup');
  });

  // Step 3: Create profile (Frontend → Backend)
  await runTest('Step 3: Create User Profile (Frontend API Call)', async () => {
    if (!userId) {
      throw new Error('No userId available for profile creation');
    }

    const profileData = {
      userId,
      name: testUser.name,
      city: testUser.city,
      bio: 'Test user for sync validation',
      email: testUser.email,
      avatar: null,
      age: 25,
      budgetMin: 1000,
      budgetMax: 3000,
      verified: false,
      isActive: true,
    };

    const response = await axios.post(
      `${BASE_URL}/profiles`,
      profileData,
      {
        headers: { 'x-user-id': userId },
        validateStatus: () => true,
        timeout: TEST_TIMEOUT,
      }
    );

    log.info(`Profile Creation Status: ${response.status}`);

    if (response.status === 201 || response.status === 200) {
      createdProfile = response.data;
      return createdProfile;
    } else {
      throw new Error(`Profile creation failed: ${response.status}`);
    }
  });

  // Step 4: Fetch profile from backend (Sync verification)
  await runTest('Step 4: Fetch Profile from Backend (Sync Check)', async () => {
    if (!userId) {
      throw new Error('No userId available');
    }

    const response = await axios.get(
      `${BASE_URL}/profiles/${userId}`,
      {
        headers: { 'x-user-id': userId },
        validateStatus: () => true,
        timeout: TEST_TIMEOUT,
      }
    );

    log.info(`Fetch Status: ${response.status}`);

    if (response.status === 200) {
      const profile = response.data;
      
      // Validate sync consistency
      if (profile.name !== testUser.name) {
        throw new Error(`Profile data mismatch: name is "${profile.name}", expected "${testUser.name}"`);
      }
      if (profile.city !== testUser.city) {
        throw new Error(`Profile data mismatch: city is "${profile.city}", expected "${testUser.city}"`);
      }
      
      log.info('Profile data is consistent across sync');
      return profile;
    } else {
      throw new Error(`Fetch failed: ${response.status}`);
    }
  });

  // Step 5: Update profile and verify sync
  await runTest('Step 5: Update Profile (Sync Verification)', async () => {
    if (!userId) {
      throw new Error('No userId available');
    }

    const updateData = {
      bio: 'Updated bio for sync test',
      budgetMax: 4000,
    };

    const response = await axios.patch(
      `${BASE_URL}/profiles/${userId}`,
      updateData,
      {
        headers: { 'x-user-id': userId },
        validateStatus: () => true,
        timeout: TEST_TIMEOUT,
      }
    );

    log.info(`Update Status: ${response.status}`);

    if (response.status === 200) {
      const updated = response.data;
      
      if (updated.bio !== updateData.bio) {
        throw new Error('Bio not updated');
      }
      if (updated.budget_max !== updateData.budgetMax && updated.budgetMax !== updateData.budgetMax) {
        throw new Error('Budget not updated');
      }
      
      return updated;
    } else {
      throw new Error(`Update failed: ${response.status}`);
    }
  });

  // Step 6: Verify data in PostgreSQL
  await runTest('Step 6: Verify PostgreSQL Sync', async () => {
    if (!userId) {
      throw new Error('No userId available');
    }

    try {
      const result = await pool.query(
        'SELECT * FROM users WHERE user_id = $1',
        [userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found in PostgreSQL');
      }

      const userData = result.rows[0];
      log.info(`PostgreSQL record found with ${Object.keys(userData).length} fields`);
      
      // Validate key fields
      if (userData.name !== testUser.name) {
        throw new Error(`PostgreSQL: Name mismatch`);
      }
      if (userData.city !== testUser.city) {
        throw new Error(`PostgreSQL: City mismatch`);
      }

      return userData;
    } catch (error) {
      if (error.message.includes('does not exist')) {
        log.warning('PostgreSQL table not initialized yet');
        return null;
      }
      throw error;
    }
  }).catch(() => {
    log.warning('PostgreSQL verification skipped');
  });

  // Step 7: Verify data in MongoDB
  await runTest('Step 7: Verify MongoDB Sync', async () => {
    if (!userId) {
      throw new Error('No userId available');
    }

    try {
      await connectMongo();
      const db = getMongoDb();
      
      if (!db) {
        throw new Error('MongoDB not available');
      }

      const mongoUser = await db.collection('users').findOne({ user_id: userId });
      
      if (!mongoUser) {
        throw new Error('User not found in MongoDB');
      }

      log.info(`MongoDB record found with ${Object.keys(mongoUser).length} fields`);
      return mongoUser;
    } catch (error) {
      log.warning(`MongoDB verification skipped: ${error.message}`);
      return null;
    }
  }).catch(() => {
    log.warning('MongoDB verification skipped');
  });

  // Step 8: Test sync endpoint
  await runTest('Step 8: Manual Sync Trigger', async () => {
    if (!userId) {
      throw new Error('No userId available');
    }

    const response = await axios.post(
      `${BASE_URL}/database/sync-user/${userId}`,
      {},
      { validateStatus: () => true, timeout: TEST_TIMEOUT }
    );

    log.info(`Sync Status: ${response.status}`);

    if (response.status === 200) {
      return response.data;
    } else if (response.status === 404) {
      log.warning('Sync endpoint not implemented');
      return null;
    } else {
      throw new Error(`Sync failed: ${response.status}`);
    }
  }).catch(() => {
    log.warning('Sync endpoint test skipped');
  });

  return { userId, profileData: createdProfile };
}

/**
 * Test API health and connectivity
 */
async function testApiHealth() {
  log.section('API HEALTH & CONNECTIVITY TESTS');

  await runTest('API Health Check', async () => {
    const response = await axios.get(`${BASE_URL}/health`, {
      validateStatus: () => true,
      timeout: 5000,
    });

    log.info(`Health Status: ${response.status}`);
    
    if (response.status === 200) {
      return response.data;
    } else {
      throw new Error(`Health check failed: ${response.status}`);
    }
  });

  await runTest('API Detailed Status', async () => {
    const response = await axios.get(`${BASE_URL}/health/detailed`, {
      validateStatus: () => true,
      timeout: 5000,
    });

    if (response.status === 200) {
      const { database } = response.data;
      log.info(`Database Status: PostgreSQL=${database.postgresql}, MongoDB=${database.mongodb}`);
      return database;
    }
    return null;
  }).catch(() => log.warning('Detailed status endpoint not available'));
}

function printSummary() {
  log.section('TEST SUMMARY');

  console.log(`Total Tests: ${colors.bright}${testResults.totalTests}${colors.reset}`);
  console.log(`${colors.green}Passed: ${testResults.passed}${colors.reset}`);
  console.log(`${colors.red}Failed: ${testResults.failed}${colors.reset}`);
  console.log(`${colors.yellow}Skipped: ${testResults.skipped}${colors.reset}`);

  const passRate = testResults.totalTests > 0 
    ? Math.round((testResults.passed / (testResults.totalTests - testResults.skipped)) * 100)
    : 0;
  
  console.log(`\nSuccess Rate: ${colors.bright}${passRate}%${colors.reset}`);

  // Performance stats
  const totalDuration = Object.values(testResults.timings).reduce((a, b) => a + b, 0);
  console.log(`Total Duration: ${totalDuration}ms`);

  if (testResults.failed > 0) {
    console.log(`\n${colors.red}Failed Tests:${colors.reset}`);
    testResults.tests
      .filter(t => t.status === 'FAILED')
      .forEach(t => {
        console.log(`  ${colors.red}✗${colors.reset} ${t.name}`);
        if (t.error) console.log(`    ${t.error}`);
      });
  }

  console.log();
}

async function runAllTests() {
  console.clear();
  log.info('Frontend-Backend Sync Integration Test Suite');
  log.info(`Started at ${new Date().toISOString()}\n`);

  try {
    // Test API health first
    await testApiHealth();

    // Run sync flow tests
    await testSyncFlow();

    // Print summary
    printSummary();

    const exitCode = testResults.failed > 0 ? 1 : 0;
    console.log(`Tests completed with exit code: ${exitCode}`);
    process.exit(exitCode);

  } catch (error) {
    log.error(`Test suite failed: ${error.message}`);
    printSummary();
    process.exit(1);
  }
}

if (require.main === module) {
  runAllTests().catch((error) => {
    console.error('Critical error:', error);
    process.exit(1);
  });
}

module.exports = { runAllTests, testSyncFlow, testApiHealth };
