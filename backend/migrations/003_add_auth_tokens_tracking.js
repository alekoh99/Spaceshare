/**
 * Migration: Add Auth Tokens Tracking
 * Adds tables for tracking JWT tokens and refresh tokens
 */

const pool = require('../db');
const { SecureLogger } = require('../middleware/errors');

const logger = new SecureLogger();

const migration = {
  name: '003_add_auth_tokens_tracking',
  
  async up() {
    try {
      console.log('Running migration: Add Auth Tokens Tracking...');

      // Create auth_tokens table for tracking issued tokens
      await pool.query(`
        CREATE TABLE IF NOT EXISTS auth_tokens (
          id SERIAL PRIMARY KEY,
          user_id VARCHAR(128) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
          token_hash VARCHAR(256) NOT NULL UNIQUE,
          token_type VARCHAR(50) NOT NULL DEFAULT 'access', -- 'access' or 'refresh'
          issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP NOT NULL,
          revoked_at TIMESTAMP,
          ip_address VARCHAR(45),
          user_agent TEXT,
          is_valid BOOLEAN DEFAULT true,
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        );
        
        CREATE INDEX IF NOT EXISTS idx_auth_tokens_user_id ON auth_tokens(user_id);
        CREATE INDEX IF NOT EXISTS idx_auth_tokens_expires_at ON auth_tokens(expires_at);
        CREATE INDEX IF NOT EXISTS idx_auth_tokens_revoked ON auth_tokens(revoked_at);
      `);

      console.log('✅ Created auth_tokens table');

      // Create login_sessions table for tracking user sessions
      await pool.query(`
        CREATE TABLE IF NOT EXISTS login_sessions (
          id SERIAL PRIMARY KEY,
          user_id VARCHAR(128) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
          session_token VARCHAR(256) NOT NULL UNIQUE,
          ip_address VARCHAR(45),
          user_agent TEXT,
          device_info JSONB,
          login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          logout_at TIMESTAMP,
          is_active BOOLEAN DEFAULT true,
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        );
        
        CREATE INDEX IF NOT EXISTS idx_login_sessions_user_id ON login_sessions(user_id);
        CREATE INDEX IF NOT EXISTS idx_login_sessions_active ON login_sessions(is_active);
      `);

      console.log('✅ Created login_sessions table');

      // Create auth_events table for audit logging
      await pool.query(`
        CREATE TABLE IF NOT EXISTS auth_events (
          id SERIAL PRIMARY KEY,
          user_id VARCHAR(128),
          event_type VARCHAR(100) NOT NULL, -- 'signin', 'signup', 'logout', 'token_refresh', 'token_revoke', etc.
          status VARCHAR(50) NOT NULL DEFAULT 'success', -- 'success', 'failure', 'warning'
          details JSONB,
          ip_address VARCHAR(45),
          user_agent TEXT,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
        );
        
        CREATE INDEX IF NOT EXISTS idx_auth_events_user_id ON auth_events(user_id);
        CREATE INDEX IF NOT EXISTS idx_auth_events_type ON auth_events(event_type);
        CREATE INDEX IF NOT EXISTS idx_auth_events_timestamp ON auth_events(timestamp);
      `);

      console.log('✅ Created auth_events table');

      // Add auth-related columns to users table if they don't exist
      try {
        await pool.query(`
          ALTER TABLE users
          ADD COLUMN IF NOT EXISTS last_signin_at TIMESTAMP,
          ADD COLUMN IF NOT EXISTS signin_count INTEGER DEFAULT 0,
          ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMP,
          ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT false,
          ADD COLUMN IF NOT EXISTS two_factor_method VARCHAR(50),
          ADD COLUMN IF NOT EXISTS account_locked_until TIMESTAMP,
          ADD COLUMN IF NOT EXISTS failed_signin_attempts INTEGER DEFAULT 0;
        `);
        console.log('✅ Updated users table with auth columns');
      } catch (e) {
        if (!e.message.includes('already exists')) {
          throw e;
        }
        console.log('✅ Users table already has auth columns');
      }

      logger.info('✅ Migration completed: Add Auth Tokens Tracking');
      return true;
    } catch (error) {
      logger.error('Migration failed:', { error: error.message });
      throw error;
    }
  },

  async down() {
    try {
      console.log('Rolling back migration: Add Auth Tokens Tracking...');

      await pool.query(`
        DROP TABLE IF EXISTS auth_events CASCADE;
        DROP TABLE IF EXISTS login_sessions CASCADE;
        DROP TABLE IF EXISTS auth_tokens CASCADE;
      `);

      // Remove auth columns from users table
      try {
        await pool.query(`
          ALTER TABLE users
          DROP COLUMN IF EXISTS last_signin_at,
          DROP COLUMN IF EXISTS signin_count,
          DROP COLUMN IF EXISTS password_changed_at,
          DROP COLUMN IF EXISTS two_factor_enabled,
          DROP COLUMN IF EXISTS two_factor_method,
          DROP COLUMN IF EXISTS account_locked_until,
          DROP COLUMN IF EXISTS failed_signin_attempts;
        `);
      } catch (e) {
        // Columns might not exist, continue
      }

      logger.info('✅ Rollback completed');
      return true;
    } catch (error) {
      logger.error('Rollback failed:', { error: error.message });
      throw error;
    }
  }
};

module.exports = migration;
