require('dotenv').config();
const admin = require('firebase-admin');
const path = require('path');

let firebaseApp;
let db;

async function initializeFirebase() {
  try {
    // Try to initialize with service account key from env
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 
      path.join(__dirname, '../serviceAccountKey.json');

    let serviceAccount;
    try {
      serviceAccount = require(serviceAccountPath);
    } catch (err) {
      console.warn('⚠️  Service account file not found at:', serviceAccountPath);
      console.warn('Firebase Realtime Database may not be available');
      return null;
    }

    if (!firebaseApp) {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL,
      });
    }

    db = admin.database();
    
    // Test connection
    await db.ref('.info/connected').once('value');
    console.log('✅ Firebase Realtime Database connected');
    
    return db;
  } catch (error) {
    console.warn('⚠️  Firebase initialization error:', error.message);
    return null;
  }
}

function getFirebaseDb() {
  if (!db) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('Firebase not initialized. Call initializeFirebase() first.');
    }
    // Return null in development if Firebase not initialized
    return null;
  }
  return db;
}

function isFirebaseAvailable() {
  return db !== undefined && db !== null;
}

module.exports = {
  initializeFirebase,
  getFirebaseDb,
  isFirebaseAvailable,
  admin,
};
