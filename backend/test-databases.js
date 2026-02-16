#!/usr/bin/env node
/**
 * Database Testing & Verification Utility
 * Tests connections to PostgreSQL, MongoDB, and Firebase
 * Verifies schema, indexes, and data consistency
 */

require('dotenv').config();
const pool = require('./db');
const { connectMongo, getMongoDb } = require('./mongo');
const { initializeFirebase, isFirebaseAvailable, getFirebaseDb } = require('./firebase');

class DatabaseTester {
  constructor() {
    this.results = {
      postgres: { status: 'pending', tables: {}, indexes: {} },
      mongo: { status: 'pending', collections: {}, indexes: {} },
      firebase: { status: 'pending', collections: [] },
    };
  }

  /**
   * Test PostgreSQL connection and schema
   */
  async testPostgreSQL() {
    console.log('\n🔷 Testing PostgreSQL...');
    try {
      // Test connection
      const result = await pool.query('SELECT NOW()');
      console.log('✅ PostgreSQL connected:', result.rows[0].now);

      // Check tables
      const tablesQuery = `
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' ORDER BY table_name;
      `;
      const tablesResult = await pool.query(tablesQuery);
      const expectedTables = [
        'users', 'listings', 'matches', 'conversations', 'messages',
        'payments', 'reviews', 'escrow', 'identity_verifications',
        'trust_badges', 'discrimination_complaints', 'compliance_incidents',
        'compatibility_scores', 'notifications', 'sync_logs'
      ];

      console.log(`\n📋 PostgreSQL Tables (Found: ${tablesResult.rows.length}):`);
      const foundTables = tablesResult.rows.map(r => r.table_name);
      
      expectedTables.forEach(table => {
        const exists = foundTables.includes(table);
        this.results.postgres.tables[table] = exists ? '✅' : '❌';
        console.log(`  ${this.results.postgres.tables[table]} ${table}`);
      });

      // Check indexes
      const indexesQuery = `
        SELECT indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY indexname;
      `;
      const indexesResult = await pool.query(indexesQuery);
      console.log(`\n🔑 PostgreSQL Indexes (Total: ${indexesResult.rows.length}):`);
      console.log('  Sample indexes:', indexesResult.rows.slice(0, 5).map(r => r.indexname).join(', '));

      this.results.postgres.status = 'success';
      this.results.postgres.totalIndexes = indexesResult.rows.length;
      return true;
    } catch (error) {
      console.error('❌ PostgreSQL test failed:', error.message);
      this.results.postgres.status = 'failed';
      this.results.postgres.error = error.message;
      return false;
    }
  }

  /**
   * Test MongoDB connection and schema
   */
  async testMongoDB() {
    console.log('\n🟩 Testing MongoDB...');
    try {
      // Connect to MongoDB
      await connectMongo();
      const mongoDb = getMongoDb();

      // Test connection
      const adminDb = mongoDb.admin();
      const pingResult = await adminDb.ping();
      console.log('✅ MongoDB connected');

      // Check collections
      const collections = await mongoDb.listCollections().toArray();
      const expectedCollections = [
        'users', 'listings', 'matches', 'conversations', 'messages',
        'payments', 'reviews', 'escrow', 'identity_verifications',
        'trust_badges', 'discrimination_complaints', 'compliance_incidents',
        'compatibility_scores', 'notifications', 'sync_logs'
      ];

      console.log(`\n📚 MongoDB Collections (Found: ${collections.length}):`);
      const foundCollectionNames = collections.map(c => c.name);

      expectedCollections.forEach(colName => {
        const exists = foundCollectionNames.includes(colName);
        this.results.mongo.collections[colName] = exists ? '✅' : '❌';
        console.log(`  ${this.results.mongo.collections[colName]} ${colName}`);
      });

      // Check document counts
      console.log(`\n📊 MongoDB Document Counts:`);
      for (const colName of foundCollectionNames.slice(0, 5)) {
        const count = await mongoDb.collection(colName).countDocuments();
        console.log(`  ${colName}: ${count} documents`);
      }

      this.results.mongo.status = 'success';
      this.results.mongo.totalCollections = collections.length;
      return true;
    } catch (error) {
      console.error('❌ MongoDB test failed:', error.message);
      this.results.mongo.status = 'failed';
      this.results.mongo.error = error.message;
      return false;
    }
  }

  /**
   * Test Firebase connection
   */
  async testFirebase() {
    console.log('\n🔥 Testing Firebase...');
    try {
      const fbDb = await initializeFirebase();
      
      if (!fbDb) {
        console.log('⚠️  Firebase not initialized (optional)');
        this.results.firebase.status = 'skipped';
        return false;
      }

      if (!isFirebaseAvailable()) {
        console.log('⚠️  Firebase Realtime Database not available (optional)');
        this.results.firebase.status = 'unavailable';
        return false;
      }

      // Test connection
      const db = getFirebaseDb();
      await db.ref('.info/connected').once('value');
      console.log('✅ Firebase Realtime Database connected');

      this.results.firebase.status = 'success';
      return true;
    } catch (error) {
      console.warn('⚠️  Firebase test failed (optional):', error.message);
      this.results.firebase.status = 'optional_unavailable';
      this.results.firebase.error = error.message;
      return false;
    }
  }

  /**
   * Test data consistency between databases
   */
  async testDataConsistency() {
    console.log('\n🔄 Testing Data Consistency...');
    try {
      const mongoDb = getMongoDb();

      // Count users in each database
      const pgResult = await pool.query('SELECT COUNT(*) as count FROM users');
      const pgUserCount = parseInt(pgResult.rows[0].count);

      const mongoUserCount = await mongoDb.collection('users').countDocuments();

      console.log(`\nUser Count Comparison:`);
      console.log(`  PostgreSQL: ${pgUserCount} users`);
      console.log(`  MongoDB: ${mongoUserCount} users`);
      
      if (pgUserCount === mongoUserCount && pgUserCount > 0) {
        console.log(`  ✅ Counts match!`);
      } else if (pgUserCount === 0 && mongoUserCount === 0) {
        console.log(`  ℹ️  Both empty (setup needed)`);
      } else {
        console.log(`  ⚠️  Counts don't match - sync needed`);
      }

      return true;
    } catch (error) {
      console.warn('⚠️  Data consistency test failed:', error.message);
      return false;
    }
  }

  /**
   * Run all tests
   */
  async runAllTests() {
    console.log('\n╔══════════════════════════════════════════╗');
    console.log('║   🗄️  DATABASE VERIFICATION TEST SUITE  ║');
    console.log('╚══════════════════════════════════════════╝\n');

    console.log(`Testing at: ${new Date().toISOString()}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}\n`);

    const pgSuccess = await this.testPostgreSQL();
    const mongoSuccess = await this.testMongoDB();
    const fbSuccess = await this.testFirebase();
    await this.testDataConsistency();

    this.printSummary();
    
    return {
      allTestsPassed: pgSuccess && mongoSuccess,
      results: this.results
    };
  }

  /**
   * Print test summary
   */
  printSummary() {
    console.log('\n╔══════════════════════════════════════════╗');
    console.log('║           📊 TEST SUMMARY                ║');
    console.log('╚══════════════════════════════════════════╝\n');

    console.log(`PostgreSQL:  ${this.results.postgres.status === 'success' ? '✅' : '❌'} ${this.results.postgres.status}`);
    if (this.results.postgres.status === 'success') {
      const tablesStatus = Object.values(this.results.postgres.tables).filter(s => s === '✅').length;
      console.log(`             ${tablesStatus}/${Object.keys(this.results.postgres.tables).length} tables found`);
      console.log(`             ${this.results.postgres.totalIndexes} indexes created`);
    }

    console.log(`\nMongoDB:     ${this.results.mongo.status === 'success' ? '✅' : '❌'} ${this.results.mongo.status}`);
    if (this.results.mongo.status === 'success') {
      const colStatus = Object.values(this.results.mongo.collections).filter(s => s === '✅').length;
      console.log(`             ${colStatus}/${Object.keys(this.results.mongo.collections).length} collections found`);
    }

    console.log(`\nFirebase:    ${['success', 'optional_unavailable'].includes(this.results.firebase.status) ? '✅' : '⚠️ '} ${this.results.firebase.status}`);

    console.log('\n' + '='.repeat(42));

    const readyStatus = this.results.postgres.status === 'success' && this.results.mongo.status === 'success';
    console.log(`\n${readyStatus ? '✅ All databases ready!' : '❌ Some databases need attention'}`);
    console.log('\nNext steps:');
    console.log('1. Run migrations: npm run migrate');
    console.log('2. Initialize Firestore: node init-collections.js');
    console.log('3. Sync all data: npm run sync-all');
    console.log('4. Start server: npm start\n');
  }
}

/**
 * Run tests
 */
async function main() {
  const tester = new DatabaseTester();
  
  try {
    const results = await tester.runAllTests();
    
    if (results.allTestsPassed) {
      process.exit(0);
    } else {
      process.exit(1);
    }
  } catch (error) {
    console.error('\n❌ Unexpected error during tests:', error);
    process.exit(1);
  }
}

main();
