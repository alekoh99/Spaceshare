require('dotenv').config();
const { Pool } = require('pg');
const path = require('path');

// Database configuration
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'spaceshare_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

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

// Notification types and templates
const notificationTemplates = [
  {
    type: 'message',
    titles: [
      'New message from {name}',
      '{name} sent you a message',
      'You have a new message',
    ],
    messages: [
      'Check out the latest in your conversation',
      'Reply to {name}\'s message',
      'You received a new message',
    ],
  },
  {
    type: 'match',
    titles: [
      'New roommate match!',
      'Great compatibility match found',
      '{name} could be your roommate!',
    ],
    messages: [
      'You have a high compatibility with {name}. Send a message to learn more!',
      'Check out this potential roommate match',
      '85% compatibility with {name} in {city}',
    ],
  },
  {
    type: 'profile_view',
    titles: [
      '{name} viewed your profile',
      'Someone viewed your profile',
      'Profile view notification',
    ],
    messages: [
      'Check out their profile and see if you\'re interested',
      '{name} from {city} viewed your roommate profile',
      'Someone is interested in you!',
    ],
  },
  {
    type: 'verification',
    titles: [
      'Profile verification needed',
      'Complete your profile verification',
      'Verify your identity',
    ],
    messages: [
      'Verify your email to unlock more features',
      'Complete identity verification to increase trust',
      'Finish your profile setup',
    ],
  },
  {
    type: 'listing',
    titles: [
      'New listing available',
      'Apartment matching your criteria',
      '{name} posted a new listing',
    ],
    messages: [
      'Check out this new listing that matches your preferences',
      'A new 2-bedroom apartment became available',
      'New roommate listing from {city}',
    ],
  },
  {
    type: 'system',
    titles: [
      'Welcome to SpaceShare!',
      'Important security update',
      'Account update required',
    ],
    messages: [
      'Get started by completing your profile',
      'We\'ve improved your privacy and security settings',
      'Please review and update your account settings',
    ],
  },
];

async function generateNotificationId() {
  return `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

function getRandomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function replaceTemplate(text, variables) {
  let result = text;
  Object.keys(variables).forEach((key) => {
    result = result.replace(new RegExp(`{${key}}`, 'g'), variables[key]);
  });
  return result;
}

async function seedNotifications() {
  console.log('🌱 Starting notification seeding...\n');

  let created = 0;
  let failed = 0;

  try {
    for (const userId of testUserIds) {
      try {
        // Generate 5-10 notifications per user
        const notificationCount = Math.floor(Math.random() * 6) + 5;

        for (let i = 0; i < notificationCount; i++) {
          const notificationId = await generateNotificationId();
          const template = getRandomElement(notificationTemplates);
          const title = getRandomElement(template.titles);
          const message = getRandomElement(template.messages);

          // Random other user for templating
          const otherUser = getRandomElement(
            testUserIds.filter((id) => id !== userId)
          );
          const otherUserName = otherUser.split('_').slice(1, -1).join(' ');
          const cities = ['San Francisco', 'Los Angeles', 'New York', 'Chicago'];
          const city = getRandomElement(cities);

          const variables = {
            name: otherUserName,
            city: city,
          };

          const finalTitle = replaceTemplate(title, variables);
          const finalMessage = replaceTemplate(message, variables);

          // Random time offset (0-30 days ago)
          const createdAt = new Date(
            Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000
          );

          // 60% of notifications are unread
          const isRead = Math.random() > 0.6;
          const readAt = isRead
            ? new Date(createdAt.getTime() + Math.random() * 24 * 60 * 60 * 1000)
            : null;

          const notification = {
            notification_id: notificationId,
            user_id: userId,
            type: template.type,
            title: finalTitle,
            message: finalMessage,
            data: JSON.stringify({
              otherUserId: otherUser,
              city: city,
              timestamp: createdAt.toISOString(),
            }),
            is_read: isRead,
            created_at: createdAt,
            read_at: readAt,
            updated_at: new Date(),
          };

          // Insert notification into database
          const query = `
            INSERT INTO notifications (
              notification_id, user_id, type, title, message, data, 
              is_read, created_at, read_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            ON CONFLICT (notification_id) DO NOTHING
          `;

          const values = [
            notification.notification_id,
            notification.user_id,
            notification.type,
            notification.title,
            notification.message,
            notification.data,
            notification.is_read,
            notification.created_at,
            notification.read_at,
            notification.updated_at,
          ];

          await pool.query(query, values);
          created++;
        }

        console.log(`✅ Created: ${notificationCount} notifications for ${userId}`);
      } catch (error) {
        console.error(`❌ Failed for ${userId}: ${error.message}`);
        failed++;
      }
    }

    console.log(`\n📊 Notification Seeding Complete!`);
    console.log(`✅ Created: ${created} notifications`);
    console.log(`❌ Failed: ${failed} users`);
    console.log(`Total: ${created} notifications`);

    // Get summary statistics
    const statsQuery = `
      SELECT 
        COUNT(*) as total_notifications,
        SUM(CASE WHEN is_read = true THEN 1 ELSE 0 END) as read_count,
        SUM(CASE WHEN is_read = false THEN 1 ELSE 0 END) as unread_count,
        COUNT(DISTINCT user_id) as users_with_notifications
      FROM notifications
    `;
    const statsResult = await pool.query(statsQuery);
    const stats = statsResult.rows[0];

    console.log(`\n📈 Database Summary:`);
    console.log(`   Total Notifications: ${stats.total_notifications}`);
    console.log(`   Read: ${stats.read_count}`);
    console.log(`   Unread: ${stats.unread_count}`);
    console.log(`   Users: ${stats.users_with_notifications}`);

    // Type breakdown
    const typeQuery = `
      SELECT type, COUNT(*) as count
      FROM notifications
      GROUP BY type
      ORDER BY count DESC
    `;
    const typeResult = await pool.query(typeQuery);

    console.log(`\n📋 By Type:`);
    typeResult.rows.forEach((row) => {
      console.log(`   ${row.type}: ${row.count}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seedNotifications().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
