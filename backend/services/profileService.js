const pool = require('../db');
const SyncService = require('./syncService');
const { getUnifiedDatabase } = require('./unifiedDatabase');

class ProfileService {
  static async createProfile(profileData) {
    const unifiedDb = getUnifiedDatabase();
    
    const userData = {
      user_id: profileData.userId,
      name: profileData.name,
      age: profileData.age || 0,
      email: profileData.email || null,
      phone: profileData.phone || '',
      phone_verified: profileData.phoneVerified || false,
      email_verified: profileData.emailVerified || false,
      city: profileData.city,
      state: profileData.state || '',
      bio: profileData.bio || '',
      avatar: profileData.avatar || null,
      move_in_date: profileData.moveInDate ? new Date(profileData.moveInDate) : new Date(),
      budget_min: profileData.budgetMin || 0,
      budget_max: profileData.budgetMax || 0,
      roommate_pref_gender: profileData.roommatePrefGender || null,
      verified: profileData.verified || false,
      stripe_connect_id: profileData.stripeConnectId || null,
      trust_score: profileData.trustScore || 50,
      cleanliness: profileData.cleanliness || 5,
      sleep_schedule: profileData.sleepSchedule || 'normal',
      social_frequency: profileData.socialFrequency || 5,
      noise_tolerance: profileData.noiseTolerance || 5,
      financial_reliability: profileData.financialReliability || 5,
      has_pets: profileData.hasPets || false,
      pet_tolerance: profileData.petTolerance || 5,
      guest_policy: profileData.guestPolicy || 5,
      privacy_need: profileData.privacyNeed || 5,
      kitchen_habits: profileData.kitchenHabits || 5,
      is_active: profileData.isActive !== false,
      is_suspended: profileData.isSuspended || false,
      created_at: new Date(),
      updated_at: new Date(),
    };

    try {
      console.log(`📝 Creating profile for user ${profileData.userId}`);
      const result = await unifiedDb.createOrUpdateUserProfile(profileData.userId, userData);
      
      // Log the result with database information
      console.log(`✅ Profile creation completed for ${profileData.userId}`);
      console.log(`   Written to: ${result.writtenDatabases.join(', ')}`);
      
      if (result.failedDatabases && result.failedDatabases.length > 0) {
        console.warn(`   Failed to write to: ${result.failedDatabases.map(db => db.name).join(', ')}`);
        console.warn(`   Scheduled for retry in background`);
      }
      
      // Return the user data along with metadata about which databases succeeded
      return {
        ...userData,
        _writtenDatabases: result.writtenDatabases,
        _failedDatabases: result.failedDatabases || [],
      };
    } catch (error) {
      console.error(`❌ Profile creation failed for ${profileData.userId}: ${error.message}`);
      throw new Error(`Failed to create profile: ${error.message}`);
    }
  }

  static async getProfile(userId) {
    const unifiedDb = getUnifiedDatabase();
    
    try {
      const profile = await unifiedDb.getUserProfile(userId);
      if (!profile) {
        throw new Error('Profile not found');
      }
      return profile;
    } catch (error) {
      if (error.message.includes('Profile not found')) {
        throw error;
      }
      throw new Error(`Failed to get profile: ${error.message}`);
    }
  }

  static async updateProfile(userId, updateData) {
    const unifiedDb = getUnifiedDatabase();
    
    try {
      // First get existing profile
      const existingProfile = await unifiedDb.getUserProfile(userId);
      if (!existingProfile) {
        throw new Error('Profile not found');
      }

      // Merge with existing data
      const mergedData = { ...existingProfile, ...updateData };
      
      // Update across all databases
      const result = await unifiedDb.createOrUpdateUserProfile(userId, mergedData);
      console.log(`✅ Profile updated for ${userId}`);
      return result.data;
    } catch (error) {
      throw new Error(`Failed to update profile: ${error.message}`);
    }
  }

  static async deleteProfile(userId) {
    const pool_ = require('../db'); // For deletion operations
    const query = 'DELETE FROM users WHERE user_id = $1 RETURNING *';
    
    try {
      const result = await pool_.query(query, [userId]);
      if (result.rows.length === 0) {
        throw new Error('Profile not found');
      }
      console.log(`✅ Profile deleted for ${userId}`);
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to delete profile: ${error.message}`);
    }
  }

  static async getAllProfiles(limit = 50, offset = 0) {
    const pool_ = require('../db');
    const query = `
      SELECT * FROM users 
      WHERE is_active = true AND is_suspended = false
      ORDER BY created_at DESC 
      LIMIT $1 OFFSET $2;
    `;
    
    try {
      const result = await pool_.query(query, [limit, offset]);
      console.log(`✅ Retrieved ${result.rows.length} profiles`);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get profiles: ${error.message}`);
    }
  }

  static async getIntelligentSwipeFeed(userId, limit = 20) {
    const unifiedDb = getUnifiedDatabase();
    
    try {
      // Get current user's profile
      const currentUser = await unifiedDb.getUserProfile(userId);
      if (!currentUser) {
        throw new Error('Profile not found');
      }

      // Get feed (matching profiles)
      const feedProfiles = await unifiedDb.getUserFeed(userId, limit * 2);
      
      if (!feedProfiles || feedProfiles.length === 0) {
        return [];
      }

      // Filter for same city if available
      const filteredProfiles = feedProfiles.filter(profile => 
        profile.city === currentUser.city && 
        profile.is_active === true && 
        profile.is_suspended !== true
      );

      // Score and sort profiles based on compatibility
      const scoredProfiles = filteredProfiles.map(profile => {
        const compatibilityScore = this.calculateCompatibilityScore(currentUser, profile);
        return { ...profile, compatibilityScore };
      });

      // Sort by compatibility score (highest first)
      scoredProfiles.sort((a, b) => b.compatibilityScore - a.compatibilityScore);

      // Return top profiles
      return scoredProfiles.slice(0, limit);
    } catch (error) {
      throw new Error(`Failed to get intelligent feed: ${error.message}`);
    }
  }

  static calculateCompatibilityScore(user1, user2) {
    let score = 50; // Base score
    
    // Age compatibility (prefer within 5 years)
    const ageDiff = Math.abs(user1.age - user2.age);
    if (ageDiff <= 5) score += 20;
    else if (ageDiff <= 10) score += 10;
    else score -= 10;
    
    // Budget compatibility
    const budget1Min = user1.budget_min || 0;
    const budget1Max = user1.budget_max || 10000;
    const budget2Min = user2.budget_min || 0;
    const budget2Max = user2.budget_max || 10000;
    
    // Check if budgets overlap
    if (budget2Min <= budget1Max && budget1Min <= budget2Max) {
      score += 20;
    } else {
      score -= 15;
    }
    
    // Cleanliness compatibility
    const cleanDiff = Math.abs(user1.cleanliness - user2.cleanliness);
    if (cleanDiff <= 2) score += 15;
    else if (cleanDiff <= 4) score += 8;
    else score -= 5;
    
    // Social frequency compatibility
    const socialDiff = Math.abs(user1.social_frequency - user2.social_frequency);
    if (socialDiff <= 2) score += 12;
    else if (socialDiff <= 4) score += 6;
    else score -= 3;
    
    // Noise tolerance compatibility
    const noiseDiff = Math.abs(user1.noise_tolerance - user2.noise_tolerance);
    if (noiseDiff <= 2) score += 12;
    else if (noiseDiff <= 4) score += 6;
    else score -= 3;
    
    // Pet compatibility
    if (user1.has_pets === user2.has_pets) {
      score += 10;
    } else if (user1.has_pets && user2.pet_tolerance >= 6) {
      score += 5;
    } else if (user2.has_pets && user1.pet_tolerance >= 6) {
      score += 5;
    } else {
      score -= 10;
    }
    
    // Gender preference matching
    if (user1.roommate_pref_gender && user2.gender) {
      if (user1.roommate_pref_gender === user2.gender || user1.roommate_pref_gender === 'any') {
        score += 15;
      } else {
        score -= 20;
      }
    }
    
    // Clamp score between 0-100
    return Math.max(0, Math.min(100, score));
  }

  static camelToSnake(str) {
    return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
  }
}

module.exports = ProfileService;
