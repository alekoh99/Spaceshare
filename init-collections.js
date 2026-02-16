const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath)
});

const db = admin.firestore();

const collections = [
  'activity',
  'activity_log',
  'address_verifications',
  'admin_notifications',
  'agora_token_requests',
  'analytics',
  'archived_conversations',
  'attachment_abuse_reports',
  'attachment_analytics',
  'attachment_security_reports',
  'banned_users',
  'chain_of_custody_reports',
  'compatibility',
  'compatibility_cache',
  'compatibility_scores',
  'complaints',
  'compliance_audit_log',
  'compliance_audit_log_archive',
  'compliance_audit_reports',
  'compliance_incidents',
  'content_removal_log',
  'content_violations',
  'conversation_outcome_predictions',
  'conversation_quality_analytics',
  'conversations',
  '_diagnostics',
  'discrimination_complaints',
  'discrimination_pattern_reports',
  'disputes',
  'document_verifications',
  'encrypted_messages',
  'engagement_decline_reports',
  'escrow',
  'escrow_holds',
  'escrow_payments',
  'escrow_platform_metrics',
  'escrow_releases',
  'evidence_analytics',
  'evidence_authenticity_reports',
  'evidence_quality_assessments',
  'evidence_uploads',
  'fee_variant_assignments',
  'frequency_predictions',
  '_health',
  'liveness_detections',
  'matches',
  'match_interactions',
  'match_outcomes',
  'match_response_analytics',
  'message_events',
  'messages',
  'ml_models',
  'moderation_action_log',
  'moderation_cases',
  'moderation_policies',
  'notification_ab_tests',
  'notification_analytics',
  'notification_campaigns',
  'notification_engagement',
  'notification_optimization_reports',
  'notification_preferences',
  'notifications',
  'notification_segments',
  'payment_audit_logs',
  'payment_default_predictions',
  'payment_logs',
  'payments',
  'payment_splits',
  'payouts',
  'predictions',
  'preference_comparisons',
  'preference_evolution_reports',
  'preference_matches',
  'preference_outlier_reports',
  'preference_recommendations',
  'preference_signals',
  'profile_views',
  'recommendation_ab_tests',
  'recommended_matches',
  'refunds',
  'reports',
  'response_time_metrics',
  'response_time_metrics_history',
  'response_time_predictions',
  'review_moderation_flags',
  'reviews',
  'safety_checklist_templates',
  'safety_verification',
  'saved_filters',
  'security_logs',
  'stripe_connect_accounts',
  'stripe_transfers',
  'subscription_audit_log',
  'subscriptions',
  'support_queue',
  'support_tickets',
  'system_calls',
  'trust_badges',
  'typing_indicators',
  'user_activity_metrics',
  'user_analytics',
  'user_archival_patterns',
  'user_attachment_profiles',
  'user_blocking_analytics',
  'user_blocks',
  'user_compliance_risk_profiles',
  'user_notification_analytics',
  'user_payment_patterns',
  'user_preference_insights',
  'user_preference_learning',
  'user_report_analytics',
  'user_reports',
  'user_reputation',
  'user_reviews',
  'user_risk_assessments',
  'user_risk_predictions',
  'users',
  'user_safety_profiles',
  'user_subscriptions',
  'user_suspensions',
  'verification_sessions',
  'video_calls',
  'violation_trend_reports'
];

async function initializeCollections() {
  try {
    console.log('🔄 Creating collections...');
    
    for (const collectionName of collections) {
      // Create a placeholder document
      await db.collection(collectionName).doc('__init__').set({
        initialized: true,
        createdAt: new Date()
      });
      
      // Delete the placeholder
      await db.collection(collectionName).doc('__init__').delete();
      
      console.log(`✅ Created: ${collectionName}`);
    }
    
    console.log('\n✨ All collections created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

initializeCollections();