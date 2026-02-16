require('dotenv').config();
const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase
const serviceAccountPath = path.resolve(__dirname, '../serviceAccountKey.json');
const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });
}

const db = admin.database();

// Test user IDs (matching seed-test-users.js)
const testUserIds = [
  'user_001_alice_sf',
  'user_002_bob_la',
  'user_003_carol_sf',
  'user_004_david_nyc',
  'user_005_emma_sf',
  'user_006_frank_la',
  'user_007_grace_sf',
  'user_008_henry_nyc',
];

// For current user testing - set this to your Firebase UID or use a test user
const CURRENT_TEST_USER = 'user_001_alice_sf';

// Sample conversations to create
const conversationPairs = [
  // Conversations involving the current test user
  {
    user1Id: CURRENT_TEST_USER,
    user2Id: testUserIds[1],
    user1Name: 'Alice Chen',
    user2Name: 'Bob Martinez',
  },
  {
    user1Id: CURRENT_TEST_USER,
    user2Id: testUserIds[2],
    user1Name: 'Alice Chen',
    user2Name: 'Carol Wong',
  },
  {
    user1Id: CURRENT_TEST_USER,
    user2Id: testUserIds[3],
    user1Name: 'Alice Chen',
    user2Name: 'David Thompson',
  },
  {
    user1Id: CURRENT_TEST_USER,
    user2Id: testUserIds[4],
    user1Name: 'Alice Chen',
    user2Name: 'Emma Davis',
  },
  {
    user1Id: CURRENT_TEST_USER,
    user2Id: testUserIds[5],
    user1Name: 'Alice Chen',
    user2Name: 'Frank Wilson',
  },
  // Other conversations between test users (optional)
  {
    user1Id: testUserIds[1],
    user2Id: testUserIds[3],
    user1Name: 'Bob Martinez',
    user2Name: 'David Thompson',
  },
  {
    user1Id: testUserIds[2],
    user2Id: testUserIds[4],
    user1Name: 'Carol Wong',
    user2Name: 'Emma Davis',
  },
];

// Sample messages for conversations
const sampleMessages = [
  'Hey! How are you doing?',
  'I\'m doing well, thanks for asking!',
  'Have you checked out the new apartment listings?',
  'Yes, I found a few good options in the area.',
  'That\'s great! Would love to discuss them over coffee.',
  'Sure! When are you free?',
  'How about this weekend?',
  'Perfect! Saturday afternoon works for me.',
  'Awesome! Looking forward to it 😊',
  'Me too! See you then!',
  'BTW, do you have any pets?',
  'I have a cat. Hope that\'s not a problem?',
  'Not at all! I love cats.',
  'That\'s wonderful to hear!',
  'What\'s your budget range for rent?',
  'I\'m looking at around $2200-$2800 per month.',
  'Same here, that works perfectly!',
  'Are you an early riser or night owl?',
  'I\'m more of a morning person.',
  'Cool, I prefer staying up late but I\'m flexible.',
  'That actually works well then!',
  'How soon are you looking to move?',
  'I\'m planning to move in March.',
  'Perfect timing! I\'m also looking at March.',
  'Let\'s definitely stay in touch!',
  'Absolutely! This is looking promising 🎉',
];

async function generateConversationId(user1Id, user2Id) {
  // Simple conversationId generation
  return `conv_${[user1Id, user2Id].sort().join('_')}`;
}

async function createMessage(conversationId, senderId, senderName, text, sentAtOffset) {
  const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const sentAt = new Date(Date.now() - sentAtOffset);

  return {
    messageId,
    senderId,
    senderName,
    text,
    sentAt: sentAt.toISOString(),
    type: 'text',
    status: 'delivered',
    isRead: Math.random() > 0.3, // 70% chance read
    reactions: {},
  };
}

async function seedConversations() {
  console.log('🌱 Starting conversation seeding...\n');

  let created = 0;
  let failed = 0;

  for (const pair of conversationPairs) {
    try {
      const conversationId = await generateConversationId(pair.user1Id, pair.user2Id);

      // Create conversation
      const conversation = {
        conversationId,
        user1Id: pair.user1Id,
        user1Name: pair.user1Name,
        user2Id: pair.user2Id,
        user2Name: pair.user2Name,
        createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(), // Created 0-7 days ago
        updatedAt: new Date().toISOString(),
        lastMessage: '',
        lastMessageAt: new Date().toISOString(),
        lastMessageSenderId: '',
        unreadCount: 0,
        isPinned: false,
        isMuted: false,
      };

      // Create messages for this conversation
      const conversationMessages = [];
      const messageCount = Math.floor(Math.random() * 15) + 5; // 5-20 messages per conversation
      let timeOffset = messageCount * 60 * 60 * 1000; // Start messages from hours ago

      for (let i = 0; i < messageCount; i++) {
        const isFromUser1 = Math.random() > 0.4; // 60% from user1, 40% from user2
        const senderId = isFromUser1 ? pair.user1Id : pair.user2Id;
        const senderName = isFromUser1 ? pair.user1Name : pair.user2Name;
        const messageText = sampleMessages[Math.floor(Math.random() * sampleMessages.length)];

        const message = await createMessage(
          conversationId,
          senderId,
          senderName,
          messageText,
          timeOffset
        );

        conversationMessages.push(message);
        timeOffset -= Math.random() * 30 * 60 * 1000; // Random time gap between messages
      }

      // Update conversation with last message
      const lastMsg = conversationMessages[conversationMessages.length - 1];
      conversation.lastMessage = lastMsg.text;
      conversation.lastMessageAt = lastMsg.sentAt;
      conversation.lastMessageSenderId = lastMsg.senderId;

      // Write conversation to database
      await db.ref(`conversations/${conversationId}`).set(conversation);

      // Write messages to database
      for (const msg of conversationMessages) {
        await db.ref(`messages/${conversationId}/${msg.messageId}`).set(msg);
      }

      console.log(`✅ Created: ${pair.user1Name} ↔ ${pair.user2Name}`);
      console.log(`   └─ ${messageCount} messages`);
      created++;
    } catch (error) {
      console.error(`❌ Failed: ${pair.user1Name} ↔ ${pair.user2Name} - ${error.message}`);
      failed++;
    }
  }

  console.log(`\n📊 Conversation Seeding Complete!`);
  console.log(`✅ Created: ${created}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`Total: ${created + failed}`);

  process.exit(0);
}

seedConversations().catch((error) => {
  console.error('Seeding failed:', error);
  process.exit(1);
});
