-- ════════════════════════════════════════════════════════════════
-- SPACESHARE PostgreSQL SECURITY CONFIGURATION
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- 1. USER ROLES AND PERMISSIONS
-- ════════════════════════════════════════════════════════════════

-- Create restricted application role
CREATE ROLE spaceshare_app WITH
    LOGIN
    PASSWORD 'CHANGE_ME_STRONG_PASSWORD'
    NOINHERIT
    NOCREATEDB
    NOCREATEROLE
    NOSUPERUSER
    NOREPLICATION;

-- Create read-only role for analytics
CREATE ROLE spaceshare_readonly WITH
    LOGIN
    PASSWORD 'CHANGE_ME_STRONG_PASSWORD'
    NOCREATEDB
    NOCREATEROLE
    NOSUPERUSER
    NOREPLICATION;

-- Create backup role
CREATE ROLE spaceshare_backup WITH
    LOGIN
    PASSWORD 'CHANGE_ME_STRONG_PASSWORD'
    NOCREATEDB
    NOCREATEROLE
    NOSUPERUSER
    NOREPLICATION;

-- ════════════════════════════════════════════════════════════════
-- 2. ENCRYPTION AND SSL CONFIGURATION
-- ════════════════════════════════════════════════════════════════

-- Force SSL connections
ALTER SYSTEM SET ssl = on;
ALTER SYSTEM SET ssl_cert_file = '/etc/postgresql/server.crt';
ALTER SYSTEM SET ssl_key_file = '/etc/postgresql/server.key';
ALTER SYSTEM SET ssl_prefer_server_ciphers = on;

-- ════════════════════════════════════════════════════════════════
-- 3. CONNECTION LIMITS AND TIMEOUTS
-- ════════════════════════════════════════════════════════════════

-- Set connection limits
ALTER ROLE spaceshare_app WITH CONNECTION LIMIT 50;
ALTER ROLE spaceshare_readonly WITH CONNECTION LIMIT 20;
ALTER ROLE spaceshare_backup WITH CONNECTION LIMIT 5;

-- Set session timeout
ALTER SYSTEM SET idle_in_transaction_session_timeout = '15min';
ALTER SYSTEM SET statement_timeout = '5min';

-- ════════════════════════════════════════════════════════════════
-- 4. LOGGING AND AUDIT
-- ════════════════════════════════════════════════════════════════

ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = on;
ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM SET log_statement_sample_rate = 0.1;

-- ════════════════════════════════════════════════════════════════
-- 5. PASSWORD SECURITY
-- ════════════════════════════════════════════════════════════════

-- Install pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ════════════════════════════════════════════════════════════════
-- 6. ROW LEVEL SECURITY (RLS)
-- ════════════════════════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY users_own_data ON users
    USING (id = current_user_id())
    WITH CHECK (id = current_user_id());

-- Profiles can only be updated by owner
CREATE POLICY profiles_own_data ON profiles
    USING (user_id = current_user_id())
    WITH CHECK (user_id = current_user_id());

-- Messages can only be accessed by participants
CREATE POLICY messages_participants ON messages
    USING (sender_id = current_user_id() OR receiver_id = current_user_id())
    WITH CHECK (sender_id = current_user_id());

-- Payments can only be accessed by involved parties
CREATE POLICY payments_parties ON payments
    USING (payer_id = current_user_id() OR payee_id = current_user_id())
    WITH CHECK (payer_id = current_user_id());

-- ════════════════════════════════════════════════════════════════
-- 7. SCHEMA AND TABLE PERMISSIONS
-- ════════════════════════════════════════════════════════════════

-- Grant necessary permissions
GRANT CONNECT ON DATABASE spaceshare TO spaceshare_app;
GRANT USAGE ON SCHEMA public TO spaceshare_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO spaceshare_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO spaceshare_app;

-- Read-only permissions
GRANT CONNECT ON DATABASE spaceshare TO spaceshare_readonly;
GRANT USAGE ON SCHEMA public TO spaceshare_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO spaceshare_readonly;

-- Backup permissions
GRANT CONNECT ON DATABASE spaceshare TO spaceshare_backup;
GRANT USAGE ON SCHEMA public TO spaceshare_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO spaceshare_backup;

-- ════════════════════════════════════════════════════════════════
-- 8. SENSITIVE DATA MASKING
-- ════════════════════════════════════════════════════════════════

-- Create view for masked user data
CREATE OR REPLACE VIEW public.users_masked AS
SELECT
    id,
    email,
    CONCAT(substring(first_name, 1, 1), '***') AS first_name_masked,
    CONCAT(substring(last_name, 1, 1), '***') AS last_name_masked,
    created_at,
    updated_at
FROM public.users;

-- Grant permissions on masked view
GRANT SELECT ON public.users_masked TO spaceshare_app;
GRANT SELECT ON public.users_masked TO spaceshare_readonly;

-- ════════════════════════════════════════════════════════════════
-- 9. PREPARED STATEMENTS (SQL INJECTION PREVENTION)
-- ════════════════════════════════════════════════════════════════

-- All queries should use prepared statements (handled in application code)
-- This is enforced through application-level best practices

-- ════════════════════════════════════════════════════════════════
-- 10. BACKUPS AND RECOVERY
-- ════════════════════════════════════════════════════════════════

-- Backup configuration (requires root access)
-- pg_dump -U spaceshare_backup -h localhost spaceshare > backup.sql
-- Enable WAL archiving for point-in-time recovery
ALTER SYSTEM SET archive_mode = on;
ALTER SYSTEM SET archive_timeout = '300s';

-- ════════════════════════════════════════════════════════════════
-- 11. APPLY CONFIGURATION
-- ════════════════════════════════════════════════════════════════

SELECT pg_reload_conf();

-- ════════════════════════════════════════════════════════════════
-- 12. VERIFICATION QUERIES
-- ════════════════════════════════════════════════════════════════

-- Verify roles created
SELECT usename, usecreatedb, usesuper FROM pg_user 
WHERE usename LIKE 'spaceshare_%' OR usename = 'postgres';

-- Verify table RLS is enabled
SELECT schemaname, tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- Verify SSL is enabled
SHOW ssl;

-- Check current connection settings
SHOW max_connections;
SHOW idle_in_transaction_session_timeout;
SHOW statement_timeout;
