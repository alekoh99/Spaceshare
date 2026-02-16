// MongoDB Security Index Configuration
// Run this in MongoDB admin database

db = db.getSiblingDB('spaceshare');

// Create indexes for security and performance
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ status: 1 });
db.users.createIndex({ createdAt: -1 });
db.users.createIndex({ "authentication.lastLogin": -1 });
db.users.createIndex({ "security.twoFactorEnabled": 1 });

db.listings.createIndex({ userId: 1, status: 1 });
db.listings.createIndex({ createdAt: -1 });
db.listings.createIndex({ status: 1 });

db.messages.createIndex({ conversationId: 1, createdAt: -1 });
db.messages.createIndex({ senderId: 1 });
db.messages.createIndex({ recipientId: 1 });
db.messages.createIndex({ readAt: 1 });

db.payments.createIndex({ payerId: 1, status: 1 });
db.payments.createIndex({ payeeId: 1, status: 1 });
db.payments.createIndex({ createdAt: -1 });
db.payments.createIndex({ status: 1 });

db.reviews.createIndex({ revieweeId: 1 });
db.reviews.createIndex({ reviewerId: 1 });
db.reviews.createIndex({ createdAt: -1 });
db.reviews.createIndex({ status: 1 });

// Create capped collection for security events
db.createCollection("security_events", {
  capped: true,
  size: 104857600, // 100MB
  max: 100000 // Max 100k documents
});

db.security_events.createIndex({ userId: 1, timestamp: -1 });
db.security_events.createIndex({ eventType: 1, timestamp: -1 });
db.security_events.createIndex({ ipAddress: 1, timestamp: -1 });

// Create capped collection for audit logs
db.createCollection("audit_logs", {
  capped: true,
  size: 104857600, // 100MB
  max: 100000
});

db.audit_logs.createIndex({ userId: 1, timestamp: -1 });
db.audit_logs.createIndex({ action: 1, timestamp: -1 });
db.audit_logs.createIndex({ resource: 1, timestamp: -1 });

// Enable document validation
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
        passwordHash: { bsonType: "string" },
        status: {
          enum: ["active", "inactive", "suspended", "deleted"]
        },
        role: {
          enum: ["admin", "moderator", "user"]
        },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

db.runCommand({
  collMod: "payments",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "payerId", "payeeId", "amount", "status"],
      properties: {
        _id: { bsonType: "objectId" },
        payerId: { bsonType: "objectId" },
        payeeId: { bsonType: "objectId" },
        amount: { bsonType: "decimal" },
        status: {
          enum: ["pending", "completed", "failed", "refunded"]
        },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

// Create expiring indexes for temporary data
db.password_reset_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
db.mfa_sessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
db.login_sessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

print("✅ MongoDB security configuration complete");
