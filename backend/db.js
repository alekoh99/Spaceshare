require('dotenv').config();
const { Pool } = require('pg');

/**
 * PostgreSQL Connection Pool Configuration
 * with Security Best Practices
 */

// Only create pool if DATABASE_URL or DB_HOST is configured
let pool = null;

if (process.env.DATABASE_URL || process.env.DB_HOST) {
  pool = new Pool({
    user: process.env.DB_USER || 'spaceshare_user',
    password: process.env.DB_PASSWORD || process.env.DATABASE_PASSWORD,
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || 5432),
    database: process.env.DB_NAME || 'spaceshare_db',
    
    // Connection string fallback
    connectionString: process.env.DATABASE_URL,
    
    // Security Configuration
    ssl: process.env.NODE_ENV === 'production' 
      ? { 
          rejectUnauthorized: true,  // Enforce certificate verification
          ca: process.env.DB_CA_CERT,  // Custom CA certificate if needed
          key: process.env.DB_CLIENT_KEY,  // Client key for mutual TLS
          cert: process.env.DB_CLIENT_CERT,  // Client certificate for mutual TLS
        }
      : false,
    
    // Connection Pool Configuration
    min: parseInt(process.env.DB_POOL_MIN || 2),
    max: parseInt(process.env.DB_POOL_MAX || 20),
    
    // Timeouts
    idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT || 900000), // 15 minutes
    connectionTimeoutMillis: parseInt(process.env.DB_CONN_TIMEOUT || 30000), // 30 seconds
    
    // Query Configuration
    statement_timeout: 30000, // Max 30 seconds for any query
    
    // Additional Security Options
    allowExitOnIdle: false,  // Don't exit on idle connections
  });
} else {
  console.warn('⚠️ PostgreSQL not configured. DATABASE_URL or DB_HOST not found.');
  // Create a mock pool that throws errors when used
  pool = {
    connect: async () => {
      throw new Error('PostgreSQL not configured. Set DATABASE_URL or DB_HOST.');
    },
    query: async () => {
      throw new Error('PostgreSQL not configured. Set DATABASE_URL or DB_HOST.');
    },
    end: async () => {
      console.log('No PostgreSQL pool to close.');
    }
  };
}

/**
 * Error Handling for Pool
 */
if (pool.on) {
  pool.on('error', (err) => {
    console.error('Unexpected error on idle client', {
      message: err.message,
      code: err.code,
      timestamp: new Date().toISOString(),
    });
    
    // Log to file instead of console in production
    if (process.env.NODE_ENV === 'production') {
      // Implement proper logging to file
    }
  });

  pool.on('connect', () => {
    // Connection established
    if (process.env.LOG_LEVEL === 'debug') {
      console.log('Database connection established');
    }
  });
}

/**
 * Health Check Function
 */
async function testConnection() {
  try {
    if (!process.env.DATABASE_URL && !process.env.DB_HOST) {
      return {
        success: false,
        error: 'PostgreSQL not configured',
      };
    }

    const result = await pool.query('SELECT NOW()');
    return {
      success: true,
      timestamp: result.rows[0].now,
      poolSize: pool.totalCount || 0,
      idleCount: pool.idleCount || 0,
      waitingCount: pool.waitingCount || 0,
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * Graceful Pool Shutdown
 */
async function closePool() {
  try {
    await pool.end();
    console.log('Database pool closed');
  } catch (error) {
    console.error('Error closing database pool:', error);
  }
}

module.exports = pool;
module.exports.testConnection = testConnection;
module.exports.closePool = closePool;
