const pool = require('../db');

async function migrate() {
  // Skip migration if DATABASE_URL is not configured
  if (!process.env.DATABASE_URL) {
    console.log('⚠️ DATABASE_URL not configured. Skipping migrations.');
    return;
  }

  const client = await pool.connect();

  try {
    console.log('🔄 Starting comprehensive database migration...');

    // ==================== USERS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        user_id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255),
        age INTEGER,
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(20),
        phone_verified BOOLEAN DEFAULT false,
        email_verified BOOLEAN DEFAULT false,
        city VARCHAR(255),
        state VARCHAR(255),
        bio TEXT,
        avatar VARCHAR(500),
        move_in_date TIMESTAMP,
        budget_min DECIMAL(10, 2),
        budget_max DECIMAL(10, 2),
        roommate_pref_gender VARCHAR(50),
        verified BOOLEAN DEFAULT false,
        stripe_connect_id VARCHAR(255),
        background_check_status VARCHAR(50),
        background_check_date TIMESTAMP,
        trust_score INTEGER DEFAULT 50,
        identity_verified_at TIMESTAMP,
        identity_document_selfie_verified BOOLEAN DEFAULT false,
        cleanliness INTEGER DEFAULT 5,
        sleep_schedule VARCHAR(50),
        social_frequency INTEGER DEFAULT 5,
        noise_tolerance INTEGER DEFAULT 5,
        financial_reliability INTEGER DEFAULT 5,
        has_pets BOOLEAN DEFAULT false,
        pet_tolerance INTEGER DEFAULT 5,
        guest_policy INTEGER DEFAULT 5,
        privacy_need INTEGER DEFAULT 5,
        kitchen_habits INTEGER DEFAULT 5,
        is_active BOOLEAN DEFAULT true,
        is_suspended BOOLEAN DEFAULT false,
        suspension_reason TEXT,
        last_active_at TIMESTAMP,
        neighborhoods TEXT[] DEFAULT ARRAY[]::TEXT[],
        trust_badge_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== LISTINGS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS listings (
        listing_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        title VARCHAR(255),
        description TEXT,
        address VARCHAR(500),
        city VARCHAR(255),
        state VARCHAR(255),
        zip_code VARCHAR(10),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(10, 8),
        property_type VARCHAR(50),
        rent_amount DECIMAL(10, 2),
        currency VARCHAR(10),
        payment_frequency VARCHAR(50),
        security_deposit DECIMAL(10, 2),
        utilities DECIMAL(10, 2),
        bedrooms INTEGER,
        bathrooms INTEGER,
        square_feet INTEGER,
        furnished BOOLEAN DEFAULT false,
        amenities TEXT[] DEFAULT ARRAY[]::TEXT[],
        available_from TIMESTAMP,
        available_until TIMESTAMP,
        lease_length INTEGER,
        total_occupants INTEGER,
        current_occupants INTEGER,
        spots_available INTEGER,
        current_tenant_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
        min_age INTEGER,
        preferred_gender VARCHAR(50),
        pets_allowed BOOLEAN DEFAULT false,
        smoking_allowed BOOLEAN DEFAULT false,
        background_check_required VARCHAR(50),
        min_credit_score DECIMAL(5, 0),
        image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
        video_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
        status VARCHAR(50),
        view_count INTEGER DEFAULT 0,
        favorite_count INTEGER DEFAULT 0,
        last_viewed_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== MATCHES TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS matches (
        match_id VARCHAR(255) PRIMARY KEY,
        user1_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        user2_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        compatibility_score DECIMAL(5, 2),
        status VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        matched_at TIMESTAMP,
        rejected_at TIMESTAMP,
        expired_at TIMESTAMP,
        shared_listing_id VARCHAR(255) REFERENCES listings(listing_id),
        shared_listing_address VARCHAR(500),
        shared_rent DECIMAL(10, 2),
        cleanliness_score DECIMAL(5, 2),
        sleep_schedule_score DECIMAL(5, 2),
        social_frequency_score DECIMAL(5, 2),
        noise_tolerance_score DECIMAL(5, 2),
        financial_reliability_score DECIMAL(5, 2),
        message_count INTEGER DEFAULT 0,
        last_message_at TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== CONVERSATIONS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversations (
        conversation_id VARCHAR(255) PRIMARY KEY,
        match_id VARCHAR(255) NOT NULL REFERENCES matches(match_id),
        participant_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
        last_message_time TIMESTAMP,
        last_message_preview TEXT,
        is_archived BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== MESSAGES TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        message_id VARCHAR(255) PRIMARY KEY,
        sender_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        recipient_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        match_id VARCHAR(255) NOT NULL REFERENCES matches(match_id),
        conversation_id VARCHAR(255) NOT NULL REFERENCES conversations(conversation_id),
        text TEXT,
        sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        read_at TIMESTAMP,
        is_read BOOLEAN DEFAULT false,
        type VARCHAR(50),
        image_url VARCHAR(500),
        system_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== PAYMENTS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS payments (
        payment_id VARCHAR(255) PRIMARY KEY,
        from_user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        to_user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        amount DECIMAL(10, 2),
        currency VARCHAR(10),
        type VARCHAR(50),
        description TEXT,
        stripe_payment_intent_id VARCHAR(255) UNIQUE,
        stripe_transfer_id VARCHAR(255),
        status VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        due_date TIMESTAMP,
        paid_at TIMESTAMP,
        refunded_at TIMESTAMP,
        dispute_id VARCHAR(255),
        dispute_reason TEXT,
        match_id VARCHAR(255) REFERENCES matches(match_id),
        listing_id VARCHAR(255) REFERENCES listings(listing_id),
        metadata JSONB,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== REVIEWS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS reviews (
        review_id VARCHAR(255) PRIMARY KEY,
        reviewer_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        reviewee_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        match_id VARCHAR(255) NOT NULL REFERENCES matches(match_id),
        rating DECIMAL(3, 1),
        title VARCHAR(255),
        comment TEXT,
        cleanliness_rating DECIMAL(3, 1),
        noise_rating DECIMAL(3, 1),
        respect_rating DECIMAL(3, 1),
        communication_rating DECIMAL(3, 1),
        reliability_rating DECIMAL(3, 1),
        positive_aspects TEXT[] DEFAULT ARRAY[]::TEXT[],
        negative_aspects TEXT[] DEFAULT ARRAY[]::TEXT[],
        verified BOOLEAN DEFAULT false,
        live_together_period VARCHAR(255),
        living_end_date TIMESTAMP,
        status VARCHAR(50),
        is_anonymous BOOLEAN DEFAULT false,
        is_private BOOLEAN DEFAULT false,
        helpful_count INTEGER DEFAULT 0,
        unhelpful_count INTEGER DEFAULT 0,
        flagged_by TEXT[] DEFAULT ARRAY[]::TEXT[],
        flag_reason TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP,
        updated_at_reviews TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== ESCROW TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS escrow (
        escrow_id VARCHAR(255) PRIMARY KEY,
        payment_id VARCHAR(255) NOT NULL REFERENCES payments(payment_id),
        user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        amount DECIMAL(10, 2),
        reason VARCHAR(255),
        status VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        release_date TIMESTAMP,
        released_at TIMESTAMP,
        dispute_started_at TIMESTAMP,
        dispute_reason TEXT,
        release_reason TEXT,
        metadata JSONB,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== IDENTITY VERIFICATIONS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS identity_verifications (
        session_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        status VARCHAR(50),
        verification_method VARCHAR(50),
        stripe_identity_session_id VARCHAR(255),
        document_type VARCHAR(50),
        document_verified BOOLEAN DEFAULT false,
        selfie_verified BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP,
        failure_reason TEXT,
        verification_data JSONB,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== TRUST BADGES TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS trust_badges (
        badge_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        type VARCHAR(100),
        title VARCHAR(255),
        description TEXT,
        icon VARCHAR(500),
        earned_at TIMESTAMP,
        expires_at TIMESTAMP,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== DISCRIMINATION COMPLAINTS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS discrimination_complaints (
        complaint_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        match_id VARCHAR(255) REFERENCES matches(match_id),
        reported_user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        category VARCHAR(100),
        severity VARCHAR(50),
        description TEXT,
        evidence TEXT[] DEFAULT ARRAY[]::TEXT[],
        status VARCHAR(50),
        submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        resolved_at TIMESTAMP,
        resolution_notes TEXT,
        admin_notes TEXT,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== COMPLIANCE INCIDENTS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS compliance_incidents (
        incident_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) REFERENCES users(user_id),
        match_id VARCHAR(255) REFERENCES matches(match_id),
        type VARCHAR(100),
        severity VARCHAR(50),
        description TEXT,
        status VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        resolved_at TIMESTAMP,
        resolution_notes TEXT,
        admin_notes TEXT,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== COMPATIBILITY SCORES TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS compatibility_scores (
        score_id VARCHAR(255) PRIMARY KEY,
        user1_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        user2_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        overall_score DECIMAL(5, 2),
        dimensions JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== NOTIFICATIONS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        notification_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL REFERENCES users(user_id),
        type VARCHAR(100),
        title VARCHAR(255),
        message TEXT,
        data JSONB,
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        read_at TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== SYNC LOGS TABLE ====================
    await client.query(`
      CREATE TABLE IF NOT EXISTS sync_logs (
        sync_id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) REFERENCES users(user_id),
        sync_direction VARCHAR(50),
        status VARCHAR(50),
        error_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ==================== ALTER TABLE STATEMENTS TO ADD MISSING COLUMNS ====================
    console.log('🔧 Adding missing columns if they don\'t exist...');

    // Add last_active_at column to users table if it doesn't exist
    try {
      await client.query(`
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP;
      `);
      console.log('✅ Added last_active_at column to users table');
    } catch (e) {
      if (!e.message.includes('already exists')) {
        console.warn('⚠️ Could not add last_active_at column:', e.message);
      }
    }

    // ==================== INDICES ====================
    console.log('📇 Creating indexes...');

    // Users indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_users_city ON users(city);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_users_verified ON users(verified);`);

    // Listings indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_listings_user_id ON listings(user_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_listings_city_rent_status ON listings(city, rent_amount, status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_listings_created_at ON listings(created_at DESC);`);

    // Matches indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_matches_user1_status ON matches(user1_id, status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_matches_user2_status ON matches(user2_id, status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_matches_status_created ON matches(status, created_at DESC);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at DESC);`);

    // Messages indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_messages_match_id ON messages(match_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id, created_at DESC);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_messages_sender_is_read ON messages(sender_id, is_read);`);

    // Payments indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_payments_from_user ON payments(from_user_id, created_at DESC);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_payments_to_user ON payments(to_user_id, created_at DESC);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_payments_stripe_id ON payments(stripe_payment_intent_id);`);

    // Reviews indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_status ON reviews(reviewee_id, status, created_at DESC);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_reviews_match_id ON reviews(match_id);`);

    // Escrow indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_escrow_user_status ON escrow(user_id, status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_escrow_payment_id ON escrow(payment_id);`);

    // Identity verifications indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_identity_user_status ON identity_verifications(user_id, status);`);

    // Trust badges indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_trust_badges_user ON trust_badges(user_id, is_active);`);

    // Complaints and incidents indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_discrimination_status ON discrimination_complaints(status);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_compliance_incidents_status ON compliance_incidents(status);`);

    // Compatibility scores indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_compatibility_users ON compatibility_scores(user1_id, user2_id);`);

    // Notifications indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);`);

    // Sync logs indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_sync_logs_user ON sync_logs(user_id, created_at DESC);`);

    console.log('✅ Database migration completed successfully');
    console.log('📊 Tables created: users, listings, matches, conversations, messages, payments, reviews, escrow, identity_verifications, trust_badges, discrimination_complaints, compliance_incidents, compatibility_scores, notifications, sync_logs');
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// If running directly (npm run migrate), exit after completion
if (require.main === module) {
  migrate()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { migrate };
