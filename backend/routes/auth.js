const express = require('express');
const router = express.Router();
const { admin } = require('../firebase');
const ProfileService = require('../services/profileService');
const { generateToken, verifyToken } = require('../middleware/auth');
const { sanitizeInput, sanitizeObject } = require('../middleware/validation');
const { responseFormatter } = require('../middleware/responseFormatter');
const pool = require('../db');

// Apply response formatter to all auth routes
router.use(responseFormatter);

/**
 * POST /auth/register
 * Create a new user account and profile
 * Expects Firebase ID token from client
 */
router.post('/register', async (req, res) => {
  try {
    const { firebaseToken, profileData } = req.body;

    // Validate input
    if (!firebaseToken || typeof firebaseToken !== 'string') {
      return res.failure('Firebase token is required', 400);
    }

    if (firebaseToken.trim().length === 0) {
      return res.failure('Firebase token cannot be empty', 400);
    }

    let firebaseUser;
    try {
      // Verify the Firebase token
      const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
      firebaseUser = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        name: decodedToken.name,
      };
    } catch (error) {
      return res.failure('Invalid or expired Firebase token', 401);
    }

    // Sanitize profile data
    const sanitizedProfile = sanitizeObject(profileData || {});

    // Check if user already exists
    try {
      const existingUser = await pool.query(
        'SELECT user_id, email FROM users WHERE user_id = $1',
        [firebaseUser.uid]
      );

      if (existingUser.rows.length > 0) {
        const token = generateToken(firebaseUser.uid, firebaseUser.email, 'user');
        return res.success(
          {
            userId: firebaseUser.uid,
            email: firebaseUser.email,
            token,
            isNewUser: false,
          },
          'User already registered',
          200
        );
      }
    } catch (error) {
      if (!error.message.includes('does not exist')) {
        throw error;
      }
    }

    // Create new user profile
    const newUserData = {
      userId: firebaseUser.uid,
      email: firebaseUser.email,
      name: sanitizeInput(sanitizedProfile.name || firebaseUser.name || 'User'),
      city: sanitizeInput(sanitizedProfile.city || ''),
      bio: sanitizeInput(sanitizedProfile.bio || ''),
      avatar: sanitizedProfile.avatar || null,
      verified: false,
      isActive: true,
      isSuspended: false,
      ...sanitizedProfile,
    };

    // Create profile
    const profile = await ProfileService.createProfile(newUserData);

    // Generate JWT token
    const token = generateToken(firebaseUser.uid, firebaseUser.email, 'user');

    res.success(
      {
        userId: firebaseUser.uid,
        email: firebaseUser.email,
        token,
        profile,
        isNewUser: true,
      },
      'User registered successfully',
      201
    );
  } catch (error) {
    console.error('Registration error:', error);
    res.failure(error.message || 'Registration failed', 500);
  }
});

/**
 * POST /auth/signin
 * Sign in user and return JWT token
 * Expects Firebase ID token from client
 */
router.post('/signin', async (req, res) => {
  try {
    const { firebaseToken } = req.body;

    // Validate input
    if (!firebaseToken || typeof firebaseToken !== 'string') {
      return res.failure('Firebase token is required', 400);
    }

    if (firebaseToken.trim().length === 0) {
      return res.failure('Firebase token cannot be empty', 400);
    }

    let firebaseUser;
    try {
      // Verify the Firebase token
      const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
      firebaseUser = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        name: decodedToken.name,
      };
    } catch (error) {
      return res.failure('Invalid or expired Firebase token', 401);
    }

    // Check if user exists in database
    let userProfile;
    try {
      userProfile = await ProfileService.getProfile(firebaseUser.uid);
    } catch (error) {
      if (error.message.includes('not found')) {
        // User not in database, create basic profile
        try {
          userProfile = await ProfileService.createProfile({
            userId: firebaseUser.uid,
            email: firebaseUser.email,
            name: firebaseUser.name || 'User',
            city: '',
          });
        } catch (createError) {
          console.warn('Could not create profile:', createError.message);
          userProfile = null;
        }
      } else {
        throw error;
      }
    }

    // Generate JWT token
    const token = generateToken(firebaseUser.uid, firebaseUser.email, 'user');

    // Update last login
    try {
      await pool.query(
        'UPDATE users SET updated_at = NOW() WHERE user_id = $1',
        [firebaseUser.uid]
      );
    } catch (error) {
      console.warn('Could not update last login:', error.message);
    }

    res.success(
      {
        userId: firebaseUser.uid,
        email: firebaseUser.email,
        token,
        profile: userProfile,
        hasProfile: !!userProfile,
      },
      'Sign in successful',
      200
    );
  } catch (error) {
    console.error('Sign in error:', error);
    res.failure(error.message || 'Sign in failed', 500);
  }
});

/**
 * POST /auth/refresh-token
 * Refresh JWT token using refresh token
 */
router.post('/refresh-token', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken || typeof refreshToken !== 'string') {
      return res.failure('Refresh token is required', 400);
    }

    try {
      const decoded = require('jsonwebtoken').verify(
        refreshToken,
        process.env.JWT_SECRET
      );

      if (decoded.type !== 'refresh') {
        throw new Error('Invalid token type');
      }

      // Get user info from database for new token
      const userResult = await pool.query(
        'SELECT email FROM users WHERE user_id = $1',
        [decoded.userId]
      );

      if (userResult.rows.length === 0) {
        return res.failure('User not found', 404);
      }

      const newToken = generateToken(
        decoded.userId,
        userResult.rows[0].email,
        'user'
      );

      res.success(
        { token: newToken },
        'Token refreshed successfully',
        200
      );
    } catch (error) {
      return res.failure('Invalid refresh token', 401);
    }
  } catch (error) {
    console.error('Token refresh error:', error);
    res.failure(error.message || 'Token refresh failed', 500);
  }
});

/**
 * POST /auth/logout
 * Handle logout - token is revoked on client side
 */
router.post('/logout', async (req, res) => {
  try {
    res.success({}, 'Logged out successfully', 200);
  } catch (error) {
    res.failure(error.message || 'Logout failed', 500);
  }
});

/**
 * GET /auth/user
 * Get current user info (requires valid JWT)
 */
router.get('/user', verifyToken, async (req, res) => {
  try {
    const { userId } = req.user;

    // Get user profile
    const profile = await ProfileService.getProfile(userId);

    res.success(
      {
        userId,
        email: req.user.email,
        ...profile,
      },
      'User info retrieved successfully',
      200
    );
  } catch (error) {
    console.error('Get user error:', error);
    res.failure(error.message || 'Failed to get user info', 500);
  }
});

module.exports = router;
