// ════════════════════════════════════════════════════════════════
// MONGODB SECURITY CONFIGURATION
// ════════════════════════════════════════════════════════════════
// NOTE: This file contains MongoDB shell commands for manual setup
// To use: mongosh < mongodb-security.js
// ════════════════════════════════════════════════════════════════

// use admin;

// ════════════════════════════════════════════════════════════════
// 1. CREATE ADMIN USER
// ════════════════════════════════════════════════════════════════

db.createUser({
  user: "admin",
  pwd: "CHANGE_ME_STRONG_PASSWORD",
  roles: [
    {
      role: "root",
      db: "admin"
    }
  ]
});

// ════════════════════════════════════════════════════════════════
// 2. CREATE APPLICATION-SPECIFIC ROLES
// ════════════════════════════════════════════════════════════════

// Create role for spaceshare application
db.createRole({
  role: "spaceshareApp",
  privileges: [
    {
      resource: { db: "spaceshare", collection: "" },
      actions: ["find", "insert", "update", "remove", "createIndex"]
    },
    {
      resource: { db: "spaceshare", collection: "system.indexes" },
      actions: ["find"]
    }
  ],
  roles: []
});

// Create read-only role
db.createRole({
  role: "spaceshareReadOnly",
  privileges: [
    {
      resource: { db: "spaceshare", collection: "" },
      actions: ["find"]
    }
  ],
  roles: []
});

// Create backup role
db.createRole({
  role: "spaceshareBackup",
  privileges: [
    {
      resource: { db: "spaceshare", collection: "" },
      actions: ["find"]
    },
    {
      resource: { cluster: true },
      actions: ["backup"]
    }
  ],
  roles: []
});

// ════════════════════════════════════════════════════════════════
// 3. CREATE APPLICATION USERS
// ════════════════════════════════════════════════════════════════

// use spaceshare;

// Main application user
db.createUser({
  user: "spaceshare_app",
  pwd: "CHANGE_ME_STRONG_PASSWORD",
  roles: [
    {
      role: "spaceshareApp",
      db: "spaceshare"
    }
  ]
});

// Read-only user
db.createUser({
  user: "spaceshare_readonly",
  pwd: "CHANGE_ME_STRONG_PASSWORD",
  roles: [
    {
      role: "spaceshareReadOnly",
      db: "spaceshare"
    }
  ]
});

// Backup user
db.createUser({
  user: "spaceshare_backup",
  pwd: "CHANGE_ME_STRONG_PASSWORD",
  roles: [
    {
      role: "spaceshareBackup",
      db: "spaceshare"
    }
  ]
});

// ════════════════════════════════════════════════════════════════
// 4. ENABLE ENCRYPTION
// ════════════════════════════════════════════════════════════════

// Enable Transparent Data Encryption (Requires MongoDB Enterprise)
// db.adminCommand({"setParameter": 1, "encryptionCipherMode": "AES256-GCM"})

// ════════════════════════════════════════════════════════════════
// 5. CREATE INDEXES
// ════════════════════════════════════════════════════════════════

// User collection
db.users.createIndex({ email: 1 }, { unique: true, sparse: true });
db.users.createIndex({ createdAt: 1 });
db.users.createIndex({ status: 1 });

// Listings collection
db.listings.createIndex({ userId: 1 });
db.listings.createIndex({ status: 1 });
db.listings.createIndex({ createdAt: 1 });

// Messages collection
db.messages.createIndex({ conversationId: 1, createdAt: 1 });
db.messages.createIndex({ senderId: 1 });
db.messages.createIndex({ recipientId: 1 });

// Payments collection
db.payments.createIndex({ payerId: 1, status: 1 });
db.payments.createIndex({ payeeId: 1, status: 1 });
db.payments.createIndex({ createdAt: 1 });

// Reviews collection
db.reviews.createIndex({ revieweeId: 1 });
db.reviews.createIndex({ reviewerId: 1 });
db.reviews.createIndex({ createdAt: 1 });

// ════════════════════════════════════════════════════════════════
// 6. ENABLE AUDIT LOGGING
// ════════════════════════════════════════════════════════════════

// Configure audit filtering
db.adminCommand({
  setParameter: 1,
  auditAuthorizationSuccess: true
});

// ════════════════════════════════════════════════════════════════
// 7. FIELD VALIDATION SCHEMA
// ════════════════════════════════════════════════════════════════

// Validate users collection
db.runCommand({
  collMod: "users",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "email", "createdAt"],
      properties: {
        _id: { bsonType: "objectId" },
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        },
        firstName: { bsonType: ["string", "null"], maxLength: 50 },
        lastName: { bsonType: ["string", "null"], maxLength: 50 },
        passwordHash: { bsonType: "string" },
        status: {
          enum: ["active", "inactive", "suspended", "deleted"]
        },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

// Validate listings collection
db.runCommand({
  collMod: "listings",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "userId", "title", "status"],
      properties: {
        _id: { bsonType: "objectId" },
        userId: { bsonType: "objectId" },
        title: { bsonType: "string", maxLength: 200 },
        description: { bsonType: "string", maxLength: 5000 },
        status: { enum: ["active", "inactive", "archived", "deleted"] },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

// Validate messages collection
db.runCommand({
  collMod: "messages",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "conversationId", "senderId"],
      properties: {
        _id: { bsonType: "objectId" },
        conversationId: { bsonType: "objectId" },
        senderId: { bsonType: "objectId" },
        recipientId: { bsonType: "objectId" },
        text: { bsonType: "string" },
        encrypted: { bsonType: "bool" },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

// ════════════════════════════════════════════════════════════════
// 8. CHANGE STREAMS FOR AUDIT (Optional)
// ════════════════════════════════════════════════════════════════

// Create audit collection if needed
db.createCollection("audit_logs", {
  capped: true,
  size: 104857600  // 100 MB
});

// ════════════════════════════════════════════════════════════════
// 9. BACKUP CONFIGURATION
// ════════════════════════════════════════════════════════════════

// Backup command (run from command line):
// mongodump --uri "mongodb+srv://spaceshare_backup:password@cluster.mongodb.net/spaceshare" \
//   --out /backups/spaceshare_$(date +%Y%m%d_%H%M%S)

// ════════════════════════════════════════════════════════════════
// 10. VERIFICATION QUERIES
// ════════════════════════════════════════════════════════════════

// List all users
db.system.users.find().pretty();

// List all roles
db.system.roles.find().pretty();

// Check database stats
db.stats();

// Check collection validation schemas
db.getCollectionInfos({ name: "users" });
db.getCollectionInfos({ name: "listings" });

// List all indexes
db.users.getIndexes();
db.listings.getIndexes();
db.messages.getIndexes();
