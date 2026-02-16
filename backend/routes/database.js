const express = require('express');
const router = express.Router();
const { getUnifiedDatabase } = require('../services/unifiedDatabase');
const SyncService = require('../services/syncService');

/**
 * GET /health
 * Get unified database status
 */
router.get('/health', (req, res) => {
  try {
    const unifiedDb = getUnifiedDatabase();
    const status = unifiedDb.getStatus();
    res.json({
      success: true,
      status,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /sync-all
 * Sync all users across all databases
 */
router.post('/sync-all', async (req, res) => {
  try {
    console.log('Starting full database sync...');
    const result = await SyncService.syncAll();
    res.json({
      success: true,
      message: 'Sync completed',
      result,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /sync-user/:userId
 * Sync a specific user across all databases
 */
router.post('/sync-user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const unifiedDb = getUnifiedDatabase();
    
    // Get user from primary database
    const userData = await unifiedDb.getUserProfile(userId);
    if (!userData) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Sync to all other databases
    await unifiedDb.syncUserToOtherDatabases(userId, userData);
    
    res.json({
      success: true,
      message: `User ${userId} synced across all databases`,
      data: userData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /failover-test
 * Test database failover mechanism
 */
router.post('/failover-test', async (req, res) => {
  try {
    const unifiedDb = getUnifiedDatabase();
    
    // Simulate loading data through unified database
    const testUsers = [];
    for (let i = 0; i < 3; i++) {
      try {
        const testUserId = `test-user-${i}`;
        // This will trigger failover if needed
        const user = await unifiedDb.getUserProfile(testUserId).catch(() => null);
        if (user) testUsers.push(user);
      } catch (error) {
        console.warn(`Test user ${i} failed:`, error.message);
      }
    }

    res.json({
      success: true,
      message: 'Failover test completed',
      databaseStatus: unifiedDb.getStatus(),
      testResults: {
        usersRetrieved: testUsers.length,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
