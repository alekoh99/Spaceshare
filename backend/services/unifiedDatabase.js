const pool = require('../db');
const { getMongoDb, connectMongo } = require('../mongo');
const { getFirebaseDb, isFirebaseAvailable } = require('../firebase');

class UnifiedDatabaseService {
  constructor() {
    this.primaryDb = 'postgres'; // Start with PostgreSQL as primary
    this.dbStatus = {
      postgres: { available: true, lastCheck: Date.now(), failureCount: 0 },
      mongo: { available: true, lastCheck: Date.now(), failureCount: 0 },
      firebase: { available: true, lastCheck: Date.now(), failureCount: 0 },
    };
    this.retryConfig = {
      maxRetries: 3,
      retryDelayMs: 1000,
    };

    // Start health check interval
    this.startHealthChecks();
  }

  /**
   * Perform health check on all databases
   */
  async startHealthChecks() {
    setInterval(async () => {
      try {
        // Check PostgreSQL
        try {
          const result = await pool.query('SELECT 1');
          if (result) {
            this.dbStatus.postgres.available = true;
            this.dbStatus.postgres.failureCount = 0;
            this.dbStatus.postgres.lastCheck = Date.now();
          }
        } catch (err) {
          this.dbStatus.postgres.available = false;
          this.dbStatus.postgres.failureCount++;
          console.warn('⚠️  PostgreSQL health check failed:', err.message);
        }

        // Check MongoDB
        try {
          const mongoDb = getMongoDb();
          if (mongoDb) {
            await mongoDb.admin().ping();
            this.dbStatus.mongo.available = true;
            this.dbStatus.mongo.failureCount = 0;
            this.dbStatus.mongo.lastCheck = Date.now();
          } else {
            this.dbStatus.mongo.available = false;
            this.dbStatus.mongo.failureCount++;
          }
        } catch (err) {
          this.dbStatus.mongo.available = false;
          this.dbStatus.mongo.failureCount++;
          console.warn('⚠️  MongoDB health check failed:', err.message);
        }

        // Check Firebase
        try {
          const firebaseDb = getFirebaseDb();
          if (firebaseDb && isFirebaseAvailable()) {
            await firebaseDb.ref('.info/connected').once('value');
            this.dbStatus.firebase.available = true;
            this.dbStatus.firebase.failureCount = 0;
            this.dbStatus.firebase.lastCheck = Date.now();
          } else {
            this.dbStatus.firebase.available = false;
            this.dbStatus.firebase.failureCount++;
          }
        } catch (err) {
          this.dbStatus.firebase.available = false;
          this.dbStatus.firebase.failureCount++;
          console.warn('⚠️  Firebase health check failed:', err.message);
        }

        this.updatePrimaryDatabase();
      } catch (error) {
        console.error('Health check error:', error);
      }
    }, 30000); // Check every 30 seconds
  }

  /**
   * Update primary database based on availability
   */
  updatePrimaryDatabase() {
    const availableDbs = Object.entries(this.dbStatus)
      .filter(([_, status]) => status.available)
      .sort((a, b) => a[1].failureCount - b[1].failureCount);

    if (availableDbs.length > 0) {
      const newPrimary = availableDbs[0][0];
      if (newPrimary !== this.primaryDb) {
        console.log(`🔄 Switching primary database from ${this.primaryDb} to ${newPrimary}`);
        this.primaryDb = newPrimary;
      }
    }
  }

  /**
   * Get user profile with fallback strategy
   */
  async getUserProfile(userId) {
    let lastError = null;

    for (let attempt = 0; attempt < this.retryConfig.maxRetries; attempt++) {
      try {
        // Try primary database first
        const result = await this.getDatabaseOperation(this.primaryDb, 'getUser', userId);
        if (result) {
          console.log(`✅ Retrieved user ${userId} from ${this.primaryDb}`);
          // Sync to other databases in background
          this.syncUserToOtherDatabases(userId, result).catch(err =>
            console.warn('Background sync failed:', err.message)
          );
          return result;
        }
      } catch (error) {
        lastError = error;
        console.warn(`Attempt ${attempt + 1} failed on ${this.primaryDb}:`, error.message);
      }

      // Try fallback databases
      for (const [dbName, status] of Object.entries(this.dbStatus)) {
        if (dbName === this.primaryDb || !status.available) continue;

        try {
          const result = await this.getDatabaseOperation(dbName, 'getUser', userId);
          if (result) {
            console.log(`✅ Retrieved user ${userId} from fallback DB: ${dbName}`);
            // Sync back to primary
            await this.syncUserToDatabase(this.primaryDb, userId, result).catch(err =>
              console.warn('Sync failed:', err.message)
            );
            return result;
          }
        } catch (error) {
          console.warn(`${dbName} fallback failed:`, error.message);
        }
      }

      // Wait before retry
      if (attempt < this.retryConfig.maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, this.retryConfig.retryDelayMs));
      }
    }

    throw lastError || new Error(`Failed to retrieve user ${userId} from all databases`);
  }

  /**
   * Create or update user profile across all databases with redundancy
   * Ensures profile is created in all available databases
   */
  async createOrUpdateUserProfile(userId, profileData) {
    const results = {
      postgres: { success: false, error: null, attempts: 0 },
      mongo: { success: false, error: null, attempts: 0 },
      firebase: { success: false, error: null, attempts: 0 },
    };

    console.log(`🔄 Starting multi-database write for user ${userId}`);
    
    // First attempt: parallel writes to all available databases
    const writePromises = [];
    
    for (const [dbName, status] of Object.entries(this.dbStatus)) {
      if (!status.available) {
        console.warn(`⏭️  Skipping ${dbName} (unavailable)`);
        results[dbName].error = 'Database unavailable';
        continue;
      }

      writePromises.push(
        this.syncUserToDatabase(dbName, userId, profileData)
          .then(() => {
            results[dbName].success = true;
            results[dbName].attempts = 1;
            console.log(`✅ Profile created in ${dbName} on attempt 1`);
          })
          .catch(async (error) => {
            results[dbName].attempts = 1;
            results[dbName].error = error.message;
            console.error(`❌ ${dbName} failed (attempt 1): ${error.message}`);
            
            // Retry once for critical databases
            if (dbName === 'postgres' || dbName === 'mongo') {
              try {
                results[dbName].attempts = 2;
                console.log(`🔄 Retrying ${dbName} (attempt 2)...`);
                await this.syncUserToDatabase(dbName, userId, profileData);
                results[dbName].success = true;
                console.log(`✅ ${dbName} succeeded on attempt 2`);
              } catch (retryError) {
                results[dbName].attempts = 2;
                results[dbName].error = retryError.message;
                console.error(`❌ ${dbName} failed retry: ${retryError.message}`);
              }
            }
          })
      );
    }

    // Wait for all write attempts
    await Promise.all(writePromises);

    // Check results
    const successCount = Object.values(results).filter(r => r.success).length;
    const failedDbs = Object.entries(results)
      .filter(([_, r]) => !r.success && r.error !== 'Database unavailable')
      .map(([name, r]) => `${name} (${r.error})`)
      .join(', ');

    console.log(`📊 Write results for ${userId}: ${successCount}/3 databases succeeded`);
    
    if (successCount === 0) {
      const errorMsg = failedDbs || 'All databases unavailable';
      console.error(`❌ CRITICAL: Failed to write to any database: ${errorMsg}`);
      throw new Error(`Failed to create profile in any database: ${errorMsg}`);
    }

    // Warn if not all databases succeeded (should attempt background sync)
    if (successCount < 2) {
      console.warn(`⚠️  WARNING: Profile created in only ${successCount} database(s). Failed: ${failedDbs}`);
    } else {
      console.log(`✅ SUCCESS: Profile created in ${successCount} databases`);
    }

    // Schedule background sync for failed databases
    if (successCount < 3) {
      this.scheduleFailedDatabaseSync(userId, profileData, results);
    }

    return {
      success: true,
      writtenDatabases: Object.entries(results)
        .filter(([_, r]) => r.success)
        .map(([name]) => name),
      failedDatabases: Object.entries(results)
        .filter(([_, r]) => !r.success && r.error !== 'Database unavailable')
        .map(([name, r]) => ({ name, error: r.error, attempts: r.attempts })),
      data: profileData,
    };
  }

  /**
   * Schedule background sync for databases that failed
   */
  async scheduleFailedDatabaseSync(userId, profileData, results) {
    const failedDbs = Object.entries(results)
      .filter(([_, r]) => !r.success && r.error !== 'Database unavailable')
      .map(([name]) => name);

    if (failedDbs.length === 0) return;

    console.log(`📅 Scheduling background sync for ${userId} in: ${failedDbs.join(', ')}`);
    
    // Schedule retries with exponential backoff
    const delays = [5000, 15000, 45000]; // 5s, 15s, 45s
    
    for (const attempt of delays) {
      setTimeout(async () => {
        try {
          console.log(`🔄 Background sync attempt for ${userId}`);
          for (const dbName of failedDbs) {
            if (!results[dbName].success) {
              try {
                await this.syncUserToDatabase(dbName, userId, profileData);
                results[dbName].success = true;
                console.log(`✅ Background sync succeeded for ${dbName}`);
              } catch (error) {
                console.warn(`❌ Background sync failed for ${dbName}: ${error.message}`);
              }
            }
          }
        } catch (error) {
          console.error(`❌ Background sync error: ${error.message}`);
        }
      }, attempt);
    }
  }

  /**
   * Get user feed (intelligent matching)
   */
  async getUserFeed(userId, limit = 10) {
    try {
      // Get from primary database
      const feed = await this.getDatabaseOperation(this.primaryDb, 'getFeed', userId, limit);
      console.log(`✅ Retrieved feed for ${userId} from ${this.primaryDb}`);
      return feed;
    } catch (error) {
      console.warn(`Feed retrieval failed from ${this.primaryDb}:`, error.message);

      // Try fallback
      for (const [dbName, status] of Object.entries(this.dbStatus)) {
        if (dbName === this.primaryDb || !status.available) continue;

        try {
          const feed = await this.getDatabaseOperation(dbName, 'getFeed', userId, limit);
          console.log(`✅ Retrieved feed for ${userId} from fallback: ${dbName}`);
          return feed;
        } catch (fallbackError) {
          console.warn(`Fallback ${dbName} failed:`, fallbackError.message);
        }
      }

      throw error;
    }
  }

  /**
   * Execute database-specific operations
   */
  async getDatabaseOperation(dbName, operation, ...args) {
    switch (dbName) {
      case 'postgres':
        return this.postgresOperation(operation, ...args);
      case 'mongo':
        return this.mongoOperation(operation, ...args);
      case 'firebase':
        return this.firebaseOperation(operation, ...args);
      default:
        throw new Error(`Unknown database: ${dbName}`);
    }
  }

  /**
   * PostgreSQL operations
   */
  async postgresOperation(operation, ...args) {
    const [userId, limit] = args;

    switch (operation) {
      case 'getUser': {
        const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
        return result.rows[0] || null;
      }

      case 'getFeed': {
        const result = await pool.query(`
          SELECT u.*, COUNT(*) OVER () as total
          FROM users u
          WHERE u.user_id != $1 
            AND u.is_active = true 
            AND u.is_suspended = false
          LIMIT $2
        `, [userId, limit]);
        return result.rows;
      }

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }
  }

  /**
   * MongoDB operations
   */
  async mongoOperation(operation, ...args) {
    const [userId, limit] = args;
    const mongoDb = getMongoDb();

    switch (operation) {
      case 'getUser': {
        const doc = await mongoDb.collection('users').findOne({ user_id: userId });
        // Ensure user_id is present in returned document
        if (doc && !doc.user_id) {
          doc.user_id = userId;
        }
        return doc;
      }

      case 'getFeed': {
        const docs = await mongoDb
          .collection('users')
          .find({
            user_id: { $ne: userId },
            is_active: true,
            is_suspended: false,
          })
          .limit(limit)
          .toArray();
        
        // Ensure user_id is present in all returned documents
        return docs.map(doc => ({
          ...doc,
          user_id: doc.user_id || doc._id?.toString() || doc.userId
        }));
      }

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }
  }

  /**
   * Firebase operations
   */
  async firebaseOperation(operation, ...args) {
    const [userId, limit] = args;
    
    if (!isFirebaseAvailable()) {
      throw new Error('Firebase not available');
    }
    
    const db = getFirebaseDb();

    switch (operation) {
      case 'getUser': {
        const snapshot = await db.ref(`users/${userId}`).once('value');
        return snapshot.val();
      }

      case 'getFeed': {
        const snapshot = await db
          .ref('users')
          .orderByChild('is_active')
          .equalTo(true)
          .limitToFirst(limit)
          .once('value');
        const data = snapshot.val();
        return data ? Object.values(data) : [];
      }

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }
  }

  /**
   * Sync user data to another database
   */
  async syncUserToDatabase(dbName, userId, userData) {
    // Normalize field names to snake_case for PostgreSQL compatibility
    const normalizeFieldNames = (data) => {
      const normalized = {};
      for (const [key, value] of Object.entries(data)) {
        // Convert camelCase to snake_case
        const snakeKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
        // Handle special cases
        if (snakeKey === '_id') {
          normalized['user_id'] = value;
        } else if (snakeKey === 'userid') {
          normalized['user_id'] = value;
        } else {
          normalized[snakeKey] = value;
        }
      }
      return normalized;
    };

    const normalizedData = normalizeFieldNames(userData);

    switch (dbName) {
      case 'postgres': {
        // List of known fields in the users table (only essential fields that should always exist)
        const knownFields = [
          'user_id', 'name', 'age', 'email', 'phone', 'phone_verified', 'email_verified',
          'city', 'state', 'bio', 'avatar', 'move_in_date', 'budget_min', 'budget_max',
          'roommate_pref_gender', 'verified', 'stripe_connect_id', 'background_check_status',
          'background_check_date', 'trust_score', 'identity_verified_at',
          'identity_document_selfie_verified', 'cleanliness', 'sleep_schedule',
          'social_frequency', 'noise_tolerance', 'financial_reliability', 'has_pets',
          'pet_tolerance', 'guest_policy', 'privacy_need', 'kitchen_habits', 'is_active',
          'is_suspended', 'suspension_reason', 'last_active_at', 'neighborhoods',
          'trust_badge_ids', 'created_at', 'updated_at'
        ];
        
        // Filter fields to only include those we know exist
        const fields = Object.keys(normalizedData)
          .filter(k => k !== '_id' && knownFields.includes(k));
        
        // If no valid fields, just return early
        if (fields.length === 0) {
          throw new Error('No valid fields to sync for user');
        }
        
        const values = fields.map(k => normalizedData[k]);
        const placeholders = fields.map((_, i) => `$${i + 1}`).join(', ');
        const updates = fields
          .filter(f => f !== 'user_id')
          .map((f, i) => `${f} = $${fields.indexOf(f) + 1}`)
          .join(', ');

        const query = `
          INSERT INTO users (${fields.join(', ')})
          VALUES (${placeholders})
          ON CONFLICT (user_id) DO UPDATE SET ${updates}
          RETURNING *
        `;

        try {
          const result = await pool.query(query, values);
          return result.rows[0];
        } catch (error) {
          // If we get a column doesn't exist error, try again with a smaller set of core fields
          if (error.message.includes('does not exist')) {
            console.warn(`⚠️ Column error in sync: ${error.message}. Retrying with core fields only.`);
            
            // Use only the most essential fields
            const coreFields = ['user_id', 'name', 'email', 'city', 'is_active', 'updated_at'];
            const coreValues = coreFields
              .filter(f => normalizedData.hasOwnProperty(f))
              .map(f => normalizedData[f]);
            const coreFieldsFiltered = coreFields.filter(f => normalizedData.hasOwnProperty(f));
            
            if (coreFieldsFiltered.length > 0) {
              const corePlaceholders = coreFieldsFiltered.map((_, i) => `$${i + 1}`).join(', ');
              const coreUpdates = coreFieldsFiltered
                .filter(f => f !== 'user_id')
                .map((f, i) => `${f} = $${coreFieldsFiltered.indexOf(f) + 1}`)
                .join(', ');
              
              const coreQuery = `
                INSERT INTO users (${coreFieldsFiltered.join(', ')})
                VALUES (${corePlaceholders})
                ON CONFLICT (user_id) DO UPDATE SET ${coreUpdates}
                RETURNING *
              `;
              
              const result = await pool.query(coreQuery, coreValues);
              return result.rows[0];
            }
          }
          throw error;
        }
      }

      case 'mongo': {
        const mongoDb = getMongoDb();
        // Ensure user_id is always included in the document
        const dataToSet = { ...normalizedData, user_id: userId };
        const result = await mongoDb.collection('users').updateOne(
          { user_id: userId },
          { $set: dataToSet },
          { upsert: true }
        );
        return result.upsertedId ? dataToSet : result;
      }

      case 'firebase': {
        if (!isFirebaseAvailable()) {
          throw new Error('Firebase not initialized');
        }
        const db = getFirebaseDb();
        await db.ref(`users/${userId}`).set(normalizedData);
        return normalizedData;
      }

      default:
        throw new Error(`Unknown database: ${dbName}`);
    }
  }

  /**
   * Sync user to all available databases
   */
  async syncUserToOtherDatabases(userId, userData) {
    const syncPromises = [];

    for (const [dbName, status] of Object.entries(this.dbStatus)) {
      if (!status.available) continue;

      syncPromises.push(
        this.syncUserToDatabase(dbName, userId, userData)
          .then(() => console.log(`✅ Synced ${userId} to ${dbName}`))
          .catch(err => console.warn(`Sync to ${dbName} failed:`, err.message))
      );
    }

    await Promise.all(syncPromises);
  }

  /**
   * Get database status
   */
  getStatus() {
    return {
      primaryDb: this.primaryDb,
      databases: this.dbStatus,
      timestamp: new Date().toISOString(),
    };
  }
}

// Initialize and export singleton
let instance = null;

function getUnifiedDatabase() {
  if (!instance) {
    instance = new UnifiedDatabaseService();
  }
  return instance;
}

module.exports = {
  UnifiedDatabaseService,
  getUnifiedDatabase,
};
