require('dotenv').config();
const { MongoClient, ServerApiVersion } = require('mongodb');

/**
 * Build MongoDB URI from environment variables
 */
function buildMongoUri() {
  // If MONGO_URI is provided directly, use it
  if (process.env.MONGO_URI) {
    return process.env.MONGO_URI;
  }

  // Build from individual environment variables
  const protocol = process.env.MONGO_PROTOCOL || 'mongodb';
  const username = process.env.MONGO_USER || process.env.MONGO_USERNAME;
  const password = process.env.MONGO_PASSWORD;
  const host = process.env.MONGO_HOST || 'localhost';
  const port = process.env.MONGO_PORT || '27017';
  const database = process.env.MONGO_DATABASE || 'spaceshare';
  const options = process.env.MONGO_OPTIONS || '';

  // If username AND password are provided (both must be non-empty strings), include them
  if (username && password && typeof password === 'string' && password.trim()) {
    const encodedUser = encodeURIComponent(username);
    const encodedPass = encodeURIComponent(password);
    const uri = `${protocol}://${encodedUser}:${encodedPass}@${host}:${port}/${database}?${options}`;
    return uri;
  }

  // Fallback to simple URI without credentials
  return `${protocol}://${host}:${port}/${database}`;
}

const MONGO_URI = buildMongoUri();
const DB_NAME = 'spaceshare';

let mongoClient;
let mongoDb;
let mongoConnected = false;

/**
 * MongoDB Connection with Security Best Practices
 */
async function connectMongo() {
  try {
    // Skip if MongoDB is not configured for this environment
    if (process.env.NODE_ENV !== 'production' && !process.env.MONGO_URI && !process.env.MONGO_HOST && !process.env.MONGO_USER) {
      console.log('⚠️ MongoDB not configured in development mode. Skipping MongoDB connection.');
      return;
    }

    // Debug: Log the connection attempt (without exposing password)
    const debugUri = MONGO_URI.replace(/(:)[^@]*(@)/, '$1***$2');
    console.log(`🔄 Attempting MongoDB connection to: ${debugUri}`);

    mongoClient = new MongoClient(MONGO_URI, {
      // Server API for Atlas compatibility
      serverApi: {
        version: ServerApiVersion.v1,
        strict: true,
        deprecationErrors: true,
      },
      
      // Connection Pool Configuration
      maxPoolSize: parseInt(process.env.MONGO_POOL_SIZE || 10),
      minPoolSize: parseInt(process.env.MONGO_CONNECTION_LIMIT || 2),
      
      // Retry Configuration
      retryWrites: true,
      retryReads: true,
      maxStalenessSeconds: 120,
      
      // Connection Timeouts
      serverSelectionTimeoutMS: 30000, // 30 seconds
      socketTimeoutMS: 45000,         // 45 seconds
      connectTimeoutMS: 30000,        // 30 seconds
      
      // SSL/TLS Configuration (for production)
      tls: process.env.NODE_ENV === 'production',
      tlsCAFile: process.env.MONGO_CA_CERT,
      tlsCertificateKeyFile: process.env.MONGO_CLIENT_CERT,
      tlsInsecure: false,
      
      // Authentication
      authSource: 'admin',
      authMechanism: 'SCRAM-SHA-256',
      
      // Application Metadata
      appName: 'SpaceShare-Backend',
      
      // Monitoring
      monitorCommands: process.env.LOG_LEVEL === 'debug',
    });

    await mongoClient.connect();
    mongoDb = mongoClient.db(DB_NAME);

    // Ping the database to verify connection
    const adminDb = mongoClient.db('admin');
    await adminDb.command({ ping: 1 });
    
    console.log('✅ MongoDB connected successfully');
    mongoConnected = true;

    // Initialize collections and indexes
    await initializeMongoCollections();

    return mongoDb;
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    
    // Provide helpful debugging information
    if (error.message.includes('SASL') || error.message.includes('authentication')) {
      console.error('🔍 Authentication Error Details:');
      console.error('   - MONGO_USER env var set:', !!process.env.MONGO_USER);
      console.error('   - MONGO_PASSWORD env var set:', !!process.env.MONGO_PASSWORD);
      console.error('   - MONGO_URI env var set:', !!process.env.MONGO_URI);
    }
    
    mongoConnected = false;
    throw error;
  }
}

/**
 * Initialize all MongoDB collections with proper indexes
 */
async function initializeMongoCollections() {
  try {
    console.log('🔄 Initializing MongoDB collections and indexes...');

    // Users collection
    await mongoDb.collection('users').createIndex({ user_id: 1 }, { unique: true });
    await mongoDb.collection('users').createIndex({ email: 1 }, { sparse: true });
    await mongoDb.collection('users').createIndex({ city: 1 });
    await mongoDb.collection('users').createIndex({ isActive: 1, city: 1 });
    await mongoDb.collection('users').createIndex({ createdAt: -1 });

    // Listings collection
    await mongoDb.collection('listings').createIndex({ listing_id: 1 }, { unique: true });
    await mongoDb.collection('listings').createIndex({ user_id: 1, createdAt: -1 });
    await mongoDb.collection('listings').createIndex({ city: 1, rentAmount: 1, status: 1 });
    await mongoDb.collection('listings').createIndex({ status: 1 });

    // Matches collection
    await mongoDb.collection('matches').createIndex({ match_id: 1 }, { unique: true });
    await mongoDb.collection('matches').createIndex({ user1Id: 1, status: 1 });
    await mongoDb.collection('matches').createIndex({ user2Id: 1, status: 1 });
    await mongoDb.collection('matches').createIndex({ status: 1, createdAt: -1 });

    // Messages collection
    await mongoDb.collection('messages').createIndex({ message_id: 1 }, { unique: true });
    await mongoDb.collection('messages').createIndex({ conversation_id: 1, createdAt: -1 });
    await mongoDb.collection('messages').createIndex({ match_id: 1 });
    await mongoDb.collection('messages').createIndex({ sender_id: 1, isRead: 1 });

    // Conversations collection
    await mongoDb.collection('conversations').createIndex({ conversation_id: 1 }, { unique: true });
    await mongoDb.collection('conversations').createIndex({ participants: 1, lastMessageTime: -1 });

    // Payments collection
    await mongoDb.collection('payments').createIndex({ payment_id: 1 }, { unique: true });
    await mongoDb.collection('payments').createIndex({ from_user_id: 1, createdAt: -1 });
    await mongoDb.collection('payments').createIndex({ to_user_id: 1, createdAt: -1 });
    await mongoDb.collection('payments').createIndex({ status: 1 });
    await mongoDb.collection('payments').createIndex({ stripe_payment_intent_id: 1 }, { sparse: true, unique: true });

    // Reviews collection
    await mongoDb.collection('reviews').createIndex({ review_id: 1 }, { unique: true });
    await mongoDb.collection('reviews').createIndex({ reviewer_id: 1 });
    await mongoDb.collection('reviews').createIndex({ reviewee_id: 1, status: 1, createdAt: -1 });
    await mongoDb.collection('reviews').createIndex({ match_id: 1 });

    // Escrow collection
    await mongoDb.collection('escrow').createIndex({ escrow_id: 1 }, { unique: true });
    await mongoDb.collection('escrow').createIndex({ user_id: 1, status: 1 });
    await mongoDb.collection('escrow').createIndex({ payment_id: 1 });

    // Identity verifications
    await mongoDb.collection('identity_verifications').createIndex({ session_id: 1 }, { unique: true });
    await mongoDb.collection('identity_verifications').createIndex({ user_id: 1, status: 1 });

    // Trust badges
    await mongoDb.collection('trust_badges').createIndex({ badge_id: 1 }, { unique: true });
    await mongoDb.collection('trust_badges').createIndex({ user_id: 1, is_active: 1 });

    // Discrimination complaints
    await mongoDb.collection('discrimination_complaints').createIndex({ complaint_id: 1 }, { unique: true });
    await mongoDb.collection('discrimination_complaints').createIndex({ status: 1 });
    await mongoDb.collection('discrimination_complaints').createIndex({ user_id: 1, status: 1 });

    // Compliance incidents
    await mongoDb.collection('compliance_incidents').createIndex({ incident_id: 1 }, { unique: true });
    await mongoDb.collection('compliance_incidents').createIndex({ status: 1 });

    // Compatibility scores
    await mongoDb.collection('compatibility_scores').createIndex({ score_id: 1 }, { unique: true });
    await mongoDb.collection('compatibility_scores').createIndex({ user1_id: 1, user2_id: 1 });

    // Notifications
    await mongoDb.collection('notifications').createIndex({ notification_id: 1 }, { unique: true });
    await mongoDb.collection('notifications').createIndex({ user_id: 1, is_read: 1 });
    await mongoDb.collection('notifications').createIndex({ created_at: -1 });

    // Sync logs
    await mongoDb.collection('sync_logs').createIndex({ sync_id: 1 }, { unique: true });
    await mongoDb.collection('sync_logs').createIndex({ user_id: 1, createdAt: -1 });
    await mongoDb.collection('sync_logs').createIndex({ status: 1 });

    console.log('✅ All MongoDB collections and indexes initialized successfully');
  } catch (error) {
    console.error('⚠️  Error initializing MongoDB collections:', error.message);
    // Don't throw - collections might already exist
  }
}

async function disconnectMongo() {
  if (mongoClient) {
    await mongoClient.close();
    console.log('✅ MongoDB disconnected');
  }
}

function getMongoDb() {
  if (!mongoDb) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('MongoDB not connected. Call connectMongo() first.');
    }
    // Return null in development if MongoDB not connected
    return null;
  }
  return mongoDb;
}

async function isMongConnected() {
  try {
    if (!mongoClient) return false;
    
    // Send a ping to confirm a successful connection
    const adminDb = mongoClient.db('admin');
    await adminDb.command({ ping: 1 });
    return true;
  } catch (error) {
    console.log('MongoDB connection check failed:', error.message);
    return false;
  }
}

module.exports = {
  connectMongo,
  disconnectMongo,
  getMongoDb,
  isMongConnected,
  MONGO_URI,
  DB_NAME,
};
