#!/usr/bin/env node
/**
 * Database Sync Utility
 * Syncs all data between PostgreSQL, MongoDB, and Firebase
 */

require('dotenv').config();
const SyncService = require('./services/syncService');
const { connectMongo } = require('./mongo');
const { migrate } = require('./migrations/migrate');

async function main() {
  const command = process.argv[2] || 'sync-users';

  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║   🔄 DATABASE SYNCHRONIZATION UTILITY     ║');
  console.log('╚════════════════════════════════════════════╝\n');

  try {
    // Connect to MongoDB
    console.log('Connecting to databases...');
    await connectMongo();

    switch (command) {
      case 'migrate':
        console.log('\nRunning migrations...');
        await migrate();
        console.log('\n✅ Migrations completed\n');
        break;

      case 'sync-users':
        console.log('\nSyncing all users across databases...');
        const userResults = await SyncService.syncAll();
        console.log(`\n✅ User sync completed: ${userResults.syncedCount}/${userResults.totalCount} synced\n`);
        break;

      case 'sync-tables':
        console.log('\nSyncing all tables to MongoDB...');
        const tableResults = await SyncService.syncAllTablesToMongo();
        console.log('\n✅ Table sync completed');
        console.log('Results:', JSON.stringify(tableResults, null, 2));
        console.log();
        break;

      case 'sync-all':
        console.log('\nPerforming full database synchronization...');
        console.log('Step 1: Running migrations...');
        await migrate();
        
        console.log('\nStep 2: Syncing all tables to MongoDB...');
        const allTableResults = await SyncService.syncAllTablesToMongo();
        
        console.log('\nStep 3: Syncing all users across all databases...');
        const allUserResults = await SyncService.syncAll();
        
        console.log('\n✅ Full database synchronization completed!');
        console.log(`   - Users synced: ${allUserResults.syncedCount}/${allUserResults.totalCount}`);
        console.log(`   - Tables synced to MongoDB`);
        console.log();
        break;

      default:
        console.log('Usage: node sync-database.js [command]');
        console.log('\nAvailable commands:');
        console.log('  migrate          - Run database migrations');
        console.log('  sync-users       - Sync all users across databases');
        console.log('  sync-tables      - Sync all tables from PostgreSQL to MongoDB');
        console.log('  sync-all         - Full synchronization (migrate + tables + users)');
        console.log();
        process.exit(1);
    }

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Sync failed:', error.message);
    console.error(error);
    process.exit(1);
  }
}

main();
