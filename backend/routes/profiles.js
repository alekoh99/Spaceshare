const express = require('express');
const ProfileService = require('../services/profileService');
const SyncService = require('../services/syncService');
const { verifyToken } = require('../middleware/auth');
const { isMongConnected } = require('../mongo');
const pool = require('../db');

const router = express.Router();

// Health check
router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Database status endpoint
router.get('/status', async (req, res) => {
  try {
    const pgConnected = await testPostgresConnection();
    const mongoConnected = await isMongConnected();
    
    res.json({
      postgresql: pgConnected ? 'connected' : 'disconnected',
      mongodb: mongoConnected ? 'connected' : 'disconnected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Sync all data endpoint
router.post('/sync-all', verifyToken, async (req, res) => {
  try {
    const result = await SyncService.syncAll();
    res.json({
      message: 'Sync completed',
      syncedCount: result.syncedCount,
      totalCount: result.totalCount
    });
  } catch (error) {
    console.error('Sync all error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create profile
router.post('/profiles', verifyToken, async (req, res) => {
  try {
    const { userId } = req.user;
    
    // Validate input
    if (!req.body) {
      return res.status(400).json({ error: 'Request body is empty' });
    }

    // Ensure all date strings are actually strings (not objects)
    const profileData = { ...req.body, userId };
    
    // Normalize date fields - convert any Timestamp objects to ISO strings
    const dateFields = ['createdAt', 'lastActiveAt', 'moveInDate', 'backgroundCheckDate'];
    for (const field of dateFields) {
      if (profileData[field]) {
        if (profileData[field].toDate && typeof profileData[field].toDate === 'function') {
          // It's a Firestore Timestamp
          profileData[field] = profileData[field].toDate().toISOString();
        } else if (profileData[field] instanceof Date) {
          profileData[field] = profileData[field].toISOString();
        } else if (typeof profileData[field] !== 'string') {
          // Try to convert to ISO string
          try {
            profileData[field] = new Date(profileData[field]).toISOString();
          } catch (e) {
            console.warn(`Warning: Could not normalize date field ${field}:`, profileData[field]);
          }
        }
      }
    }

    // Validate required fields
    if (!profileData.city || profileData.city.trim() === '') {
      return res.status(400).json({ 
        error: 'City is required',
        code: 'VALIDATION_ERROR'
      });
    }

    const profile = await ProfileService.createProfile(profileData);
    res.status(201).json(profile);
  } catch (error) {
    console.error('Create profile error:', error);
    
    // Handle specific error types
    if (error.message && error.message.includes('Timestamp')) {
      return res.status(400).json({
        error: 'Invalid data format: Timestamp objects cannot be sent directly. Use ISO8601 date strings.',
        code: 'SERIALIZATION_ERROR',
        details: error.message
      });
    }
    
    if (error.message && error.message.includes('Failed to write to any database')) {
      return res.status(503).json({
        error: 'Database service unavailable',
        code: 'SERVICE_UNAVAILABLE',
        details: 'Could not write profile to any available database. Please try again.'
      });
    }

    res.status(500).json({ 
      error: error.message || 'Failed to create profile',
      code: 'INTERNAL_ERROR'
    });
  }
});

// Get profile
router.get('/profiles/:userId', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`Fetching profile for user: ${userId}`);
    const profile = await ProfileService.getProfile(userId);
    res.json(profile);
  } catch (error) {
    console.error('Get profile error:', error.message);
    if (error.message.includes('not found')) {
      return res.status(404).json({ 
        error: 'Profile not found',
        userId: req.params.userId,
        message: 'User profile does not exist in database. Please create a profile first.'
      });
    }
    res.status(500).json({ error: error.message });
  }
});

// Update profile
router.patch('/profiles/:userId', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { userId: tokenUserId } = req.user;

    // Only allow users to update their own profile
    if (userId !== tokenUserId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const profile = await ProfileService.updateProfile(userId, req.body);
    res.json(profile);
  } catch (error) {
    console.error('Update profile error:', error);
    if (error.message.includes('not found')) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    res.status(500).json({ error: error.message });
  }
});

// Delete profile
router.delete('/profiles/:userId', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { userId: tokenUserId } = req.user;

    // Only allow users to delete their own profile
    if (userId !== tokenUserId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const profile = await ProfileService.deleteProfile(userId);
    res.json({ message: 'Profile deleted successfully', profile });
  } catch (error) {
    console.error('Delete profile error:', error);
    if (error.message.includes('not found')) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    res.status(500).json({ error: error.message });
  }
});

// Get all profiles (paginated)
router.get('/profiles', verifyToken, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const offset = parseInt(req.query.offset) || 0;

    const profiles = await ProfileService.getAllProfiles(limit, offset);
    res.json({ count: profiles.length, profiles });
  } catch (error) {
    console.error('Get profiles error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get intelligent swipe feed for a user
router.get('/profiles/:userId/intelligent-feed', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    
    console.log(`Fetching intelligent feed for user: ${userId}, limit: ${limit}`);
    const profiles = await ProfileService.getIntelligentSwipeFeed(userId, limit);
    
    if (!profiles || profiles.length === 0) {
      return res.json([]);
    }
    
    res.json(profiles);
  } catch (error) {
    console.error('Get intelligent feed error:', error.message);
    if (error.message.includes('not found')) {
      return res.status(404).json({ 
        error: 'Profile not found',
        userId: req.params.userId
      });
    }
    res.status(500).json({ error: error.message });
  }
});

// Get paginated swipe feed for a user
router.get('/profiles/:userId/feed', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = Math.max(parseInt(req.query.offset) || 0, 0);
    const minScore = parseFloat(req.query.minScore) || 65;
    
    console.log(`Fetching paginated feed for user: ${userId}, limit: ${limit}, offset: ${offset}`);
    const profiles = await ProfileService.getIntelligentSwipeFeed(userId, limit);
    
    if (!profiles || profiles.length === 0) {
      return res.json([]);
    }
    
    // Return profiles, applying offset/limit for this response
    const paginatedProfiles = profiles.slice(offset, offset + limit);
    res.json(paginatedProfiles);
  } catch (error) {
    console.error('Get feed error:', error.message);
    if (error.message.includes('not found')) {
      return res.status(404).json({ 
        error: 'Profile not found',
        userId: req.params.userId
      });
    }
    res.status(500).json({ error: error.message });
  }
});

// Helper function to test PostgreSQL connection
async function testPostgresConnection() {
  try {
    await pool.query('SELECT 1');
    return true;
  } catch (error) {
    console.error('PostgreSQL connection test failed:', error.message);
    return false;
  }
}

module.exports = router;
