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

async function seedTestUserConversations(currentUserId) {
  console.log(`\n🌱 Creating conversations for user: ${currentUserId}\n`);

  // Test user IDs to create conversations with
  const testUsers = [
    { id: 'user_001_alice_sf', name: 'Alice Chen' },
    { id: 'user_002_bob_la', name: 'Bob Martinez' },
    { id: 'user_003_carol_sf', name: 'Carol Wong' },
    { id: 'user_004_david_nyc', name: 'David Thompson' },
    { id: 'user_005_emma_sf', name: 'Emma Davis' },
  ];

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
  ];

  let created = 0;
  let failed = 0;

  for (const testUser of testUsers) {
    try {
      const conversationId = `conv_${[currentUserId, testUser.id].sort().join('_')}`;

      const conversation = {
        conversationId,
        user1Id: currentUserId,
        user1Name: 'You',
        user2Id: testUser.id,
        user2Name: testUser.name,
        createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date().toISOString(),
        lastMessage: '',
        lastMessageAt: new Date().toISOString(),
        lastMessageSenderId: '',
        unreadCount: 0,
        isPinned: false,
        isMuted: false,
      };

      // Create 3-8 sample messages
      const messageCount = Math.floor(Math.random() * 6) + 3;
      let timeOffset = messageCount * 60 * 60 * 1000;

      for (let i = 0; i < messageCount; i++) {
        const isFromCurrentUser = Math.random() > 0.4;
        const senderId = isFromCurrentUser ? currentUserId : testUser.id;
        const senderName = isFromCurrentUser ? 'You' : testUser.name;
        const messageText = sampleMessages[Math.floor(Math.random() * sampleMessages.length)];
        const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const sentAt = new Date(Date.now() - timeOffset);

        const message = {
          messageId,
          senderId,
          senderName,
          text: messageText,
          sentAt: sentAt.toISOString(),
          type: 'text',
          status: 'delivered',
          isRead: Math.random() > 0.3,
          reactions: {},
        };

        await db.ref(`messages/${conversationId}/${messageId}`).set(message);
        timeOffset -= Math.random() * 30 * 60 * 1000;
      }

      // Update conversation with last message
      const messagesSnapshot = await db.ref(`messages/${conversationId}`).orderByChild('sentAt').limitToLast(1).once('value');
      if (messagesSnapshot.exists()) {
        const messages = messagesSnapshot.val();
        const lastMsg = Object.values(messages)[0];
        conversation.lastMessage = lastMsg.text;
        conversation.lastMessageAt = lastMsg.sentAt;
        conversation.lastMessageSenderId = lastMsg.senderId;
      }

      // Write conversation
      await db.ref(`conversations/${conversationId}`).set(conversation);

      console.log(`✅ Created: You ↔ ${testUser.name} (${messageCount} messages)`);
      created++;
    } catch (error) {
      console.error(`❌ Failed: You ↔ ${testUser.name} - ${error.message}`);
      failed++;
    }
  }

  console.log(`\n📊 Complete!`);
  console.log(`✅ Created: ${created} conversations`);
  console.log(`❌ Failed: ${failed}`);
  process.exit(0);
}

// Get current user ID from environment or command line
const currentUserId = process.argv[2];

if (!currentUserId) {
  console.error('❌ Error: Please provide your current user ID as an argument');
  console.log('\nUsage: npm run seed:personal-conversations -- <your-user-id>');
  console.log('\nExample: npm run seed:personal-conversations -- user_test_12345');
  process.exit(1);
}

seedTestUserConversations(currentUserId).catch((error) => {
  console.error('Seeding failed:', error);
  process.exit(1);
});
