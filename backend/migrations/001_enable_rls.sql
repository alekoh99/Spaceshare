-- PostgreSQL Row-Level Security Configuration
-- Run this on the spaceshare database

-- Enable RLS on critical tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY users_row_security ON users
    USING (id = current_setting('app.current_user_id')::uuid OR 
           (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin')
    WITH CHECK (id = current_setting('app.current_user_id')::uuid OR 
                (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin');

-- Listings: public read, owner write
CREATE POLICY listings_row_security ON listings
    USING (status = 'active' OR user_id = current_setting('app.current_user_id')::uuid OR
           (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin')
    WITH CHECK (user_id = current_setting('app.current_user_id')::uuid OR
                (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin');

-- Messages: only parties and admins
CREATE POLICY messages_row_security ON messages
    USING (sender_id = current_setting('app.current_user_id')::uuid OR 
           recipient_id = current_setting('app.current_user_id')::uuid OR
           (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin')
    WITH CHECK (sender_id = current_setting('app.current_user_id')::uuid OR
                (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin');

-- Payments: only parties and admins
CREATE POLICY payments_row_security ON payments
    USING (payer_id = current_setting('app.current_user_id')::uuid OR 
           payee_id = current_setting('app.current_user_id')::uuid OR
           (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin')
    WITH CHECK (payer_id = current_setting('app.current_user_id')::uuid OR
                (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin');

-- Reviews: public read, owner/admin write
CREATE POLICY reviews_row_security ON reviews
    USING (true)
    WITH CHECK (reviewer_id = current_setting('app.current_user_id')::uuid OR
                (SELECT role FROM users WHERE id = current_setting('app.current_user_id')::uuid) = 'admin');

-- Grant default privileges for future tables
ALTER DEFAULT PRIVILEGES FOR USER spaceshare_app GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO spaceshare_app;

-- Create function to set current user context
CREATE OR REPLACE FUNCTION set_user_context(user_id uuid) RETURNS void AS $$
BEGIN
    PERFORM set_config('app.current_user_id', user_id::text, false);
END;
$$ LANGUAGE plpgsql;

-- Create audit trigger for sensitive tables
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    user_id UUID,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, user_id)
        VALUES (TG_TABLE_NAME, OLD.id, TG_OP, row_to_json(OLD), current_setting('app.current_user_id')::uuid);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, user_id)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(OLD), row_to_json(NEW), current_setting('app.current_user_id')::uuid);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_data, user_id)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(NEW), current_setting('app.current_user_id')::uuid);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply audit trigger to sensitive tables
CREATE TRIGGER users_audit AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();

CREATE TRIGGER payments_audit AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();

CREATE TRIGGER listings_audit AFTER INSERT OR UPDATE OR DELETE ON listings
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();
