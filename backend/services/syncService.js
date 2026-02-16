const pool = require('../db');
const { getMongoDb } = require('../mongo');
const { getFirebaseDb, isFirebaseAvailable } = require('../firebase');

/**
 * Enhanced SyncService - Synchronizes data across PostgreSQL, MongoDB, and Firebase
 */
class SyncService {
  // ==================== USER SYNCHRONIZATION ====================

  /**
   * Sync user from PostgreSQL to MongoDB
   */
  static async syncPostgresToMongo(userId) {
    try {
      const pgResult = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
      
      if (pgResult.rows.length === 0) {
        throw new Error('User not found in PostgreSQL');
      }

      const userData = this.postgresRowToMongo(pgResult.rows[0]);
      const mongoDb = getMongoDb();
      
      // Upsert to MongoDB
      await mongoDb.collection('users').updateOne(
        { user_id: userId },
        { $set: userData },
        { upsert: true }
      );

      await this.logSync(userId, 'postgres->mongo', 'success');
      console.log(`✅ Synced user ${userId} from PostgreSQL to MongoDB`);
      return userData;
    } catch (error) {
      await this.logSync(userId, 'postgres->mongo', 'error', error.message);
      console.error('❌ Sync error (Postgres->Mongo):', error.message);
      throw error;
    }
  }

  /**
   * Sync user from MongoDB to PostgreSQL
   */
  static async syncMongoToPostgres(userId) {
    try {
      const mongoDb = getMongoDb();
      const mongoDoc = await mongoDb.collection('users').findOne({ user_id: userId });
      
      if (!mongoDoc) {
        throw new Error('User not found in MongoDB');
      }

      const pgData = this.mongoDocToPostgres(mongoDoc);
      const fieldsToUpdate = Object.keys(pgData)
        .filter(key => key !== 'user_id' && key !== 'created_at')
        .sort();

      const placeholders = fieldsToUpdate.map((_, i) => `$${i + 1}`).join(', ');
      const updateClauses = fieldsToUpdate.map((field, i) => `${field} = $${i + 1}`).join(', ');

      const query = `
        INSERT INTO users (user_id, ${fieldsToUpdate.join(', ')})
        VALUES ($${fieldsToUpdate.length + 1}, ${placeholders})
        ON CONFLICT (user_id) DO UPDATE SET
          ${updateClauses},
          updated_at = CURRENT_TIMESTAMP
        RETURNING *;
      `;

      const values = [userId, ...fieldsToUpdate.map(f => pgData[f])];
      const result = await pool.query(query, values);

      await this.logSync(userId, 'mongo->postgres', 'success');
      console.log(`✅ Synced user ${userId} from MongoDB to PostgreSQL`);
      return result.rows[0];
    } catch (error) {
      await this.logSync(userId, 'mongo->postgres', 'error', error.message);
      console.error('❌ Sync error (Mongo->Postgres):', error.message);
      throw error;
    }
  }

  /**
   * Sync user to all databases (tri-directional)
   */
  static async syncUserToAllDatabases(userId) {
    const results = {
      postgres: false,
      mongo: false,
      firebase: false,
    };

    try {
      // Get fresh data from primary (PostgreSQL)
      const pgResult = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
      if (pgResult.rows.length === 0) {
        throw new Error('User not found in any database');
      }

      const userData = pgResult.rows[0];

      // Sync to MongoDB
      try {
        const mongoDb = getMongoDb();
        const mongoData = this.postgresRowToMongo(userData);
        await mongoDb.collection('users').updateOne(
          { user_id: userId },
          { $set: mongoData },
          { upsert: true }
        );
        results.mongo = true;
      } catch (error) {
        console.warn(`⚠️  MongoDB sync failed for ${userId}:`, error.message);
      }

      // Sync to Firebase (if available)
      if (isFirebaseAvailable()) {
        try {
          const db = getFirebaseDb();
          const firebaseData = this.postgresRowToFirebase(userData);
          await db.ref(`users/${userId}`).set(firebaseData);
          results.firebase = true;
        } catch (error) {
          console.warn(`⚠️  Firebase sync failed for ${userId}:`, error.message);
        }
      }

      results.postgres = true;
      await this.logSync(userId, 'tri-sync', 'success');
      console.log(`✅ User ${userId} synced to all databases`);
      return results;
    } catch (error) {
      await this.logSync(userId, 'tri-sync', 'error', error.message);
      console.error('❌ Tri-sync failed:', error.message);
      throw error;
    }
  }

  /**
   * Sync all users across all databases
   */
  static async syncAll() {
    try {
      console.log('🔄 Starting full database sync...');
      
      const pgResult = await pool.query('SELECT user_id FROM users');
      const userIds = pgResult.rows.map(row => row.user_id);

      console.log(`📊 Found ${userIds.length} users to sync`);

      let syncedCount = 0;
      let failedCount = 0;

      for (const userId of userIds) {
        try {
          await this.syncUserToAllDatabases(userId);
          syncedCount++;
        } catch (error) {
          console.warn(`⚠️  Failed to sync ${userId}:`, error.message);
          failedCount++;
        }
      }

      console.log(`✅ Sync complete: ${syncedCount} succeed, ${failedCount} failed`);
      return { syncedCount, failedCount, totalCount: userIds.length };
    } catch (error) {
      console.error('❌ Full sync failed:', error.message);
      throw error;
    }
  }

  // ==================== TABLE SYNCHRONIZATION ====================

  /**
   * Sync a specific table/collection from PostgreSQL to MongoDB
   */
  static async syncTableToMongo(tableName) {
    try {
      const result = await pool.query(`SELECT * FROM ${tableName}`);
      const mongoDb = getMongoDb();
      const collection = mongoDb.collection(tableName);

      if (result.rows.length === 0) {
        console.log(`ℹ️  No rows to sync for ${tableName}`);
        return { inserted: 0, updated: 0 };
      }

      const bulkOps = result.rows.map(row => {
        const idField = this.getIdField(tableName);
        return {
          updateOne: {
            filter: { [idField]: row[idField] },
            update: { $set: row },
            upsert: true,
          },
        };
      });

      const bulkResult = await collection.bulkWrite(bulkOps);
      console.log(`✅ Synced ${tableName}: ${bulkResult.upsertedCount} inserted, ${bulkResult.modifiedCount} updated`);
      
      return {
        inserted: bulkResult.upsertedCount,
        updated: bulkResult.modifiedCount,
      };
    } catch (error) {
      console.error(`❌ Failed to sync table ${tableName}:`, error.message);
      throw error;
    }
  }

  /**
   * Sync all tables to MongoDB
   */
  static async syncAllTablesToMongo() {
    const tables = [
      'users', 'listings', 'matches', 'conversations', 'messages',
      'payments', 'reviews', 'escrow', 'identity_verifications',
      'trust_badges', 'discrimination_complaints', 'compliance_incidents',
      'compatibility_scores', 'notifications', 'sync_logs'
    ];

    console.log(`🔄 Syncing ${tables.length} tables to MongoDB...`);
    const results = {};

    for (const table of tables) {
      try {
        results[table] = await this.syncTableToMongo(table);
      } catch (error) {
        console.error(`⚠️  Failed to sync ${table}:`, error.message);
        results[table] = { error: error.message };
      }
    }

    return results;
  }

  // ==================== HELPER METHODS ====================

  /**
   * Log synchronization operations
   */
  static async logSync(userId, direction, status, errorMessage = null) {
    try {
      const mongoDb = getMongoDb();
      const syncId = `sync_${userId}_${Date.now()}`;
      
      await mongoDb.collection('sync_logs').insertOne({
        sync_id: syncId,
        user_id: userId,
        sync_direction: direction,
        status: status,
        error_message: errorMessage,
        created_at: new Date(),
      });

      // Also log to PostgreSQL
      await pool.query(
        'INSERT INTO sync_logs (sync_id, user_id, sync_direction, status, error_message, created_at) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)',
        [syncId, userId, direction, status, errorMessage]
      );
    } catch (error) {
      console.error('⚠️  Failed to log sync:', error.message);
    }
  }

  /**
   * Convert PostgreSQL row to MongoDB document
   */
  static postgresRowToMongo(pgRow) {
    const { created_at, updated_at, ...rest } = pgRow;
    return {
      ...rest,
      created_at: created_at || new Date(),
      updated_at: updated_at || new Date(),
    };
  }

  /**
   * Convert PostgreSQL row to Firebase format
   */
  static postgresRowToFirebase(pgRow) {
    return this.postgresRowToMongo(pgRow);
  }

  /**
   * Convert MongoDB document to PostgreSQL format
   */
  static mongoDocToPostgres(mongoDoc) {
    const { _id, ...rest } = mongoDoc;
    return rest;
  }

  /**
   * Get primary ID field for a table
   */
  static getIdField(tableName) {
    const idFields = {
      users: 'user_id',
      listings: 'listing_id',
      matches: 'match_id',
      conversations: 'conversation_id',
      messages: 'message_id',
      payments: 'payment_id',
      reviews: 'review_id',
      escrow: 'escrow_id',
      identity_verifications: 'session_id',
      trust_badges: 'badge_id',
      discrimination_complaints: 'complaint_id',
      compliance_incidents: 'incident_id',
      compatibility_scores: 'score_id',
      notifications: 'notification_id',
      sync_logs: 'sync_id',
    };

    return idFields[tableName] || 'id';
  }
}

module.exports = SyncService;
