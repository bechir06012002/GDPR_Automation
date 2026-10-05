-- ============================================================================
-- GDPR DSAR Automation Platform - Database Schema
-- ============================================================================
-- Run this in Supabase SQL Editor (Settings → SQL Editor → New Query)
-- All tables have RLS DISABLED for n8n access
-- ============================================================================

-- Create UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. DSAR_REQUESTS - Main DSAR request records
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.dsar_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    identifier VARCHAR NOT NULL UNIQUE,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deadline_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP + INTERVAL '30 days',
    status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'delivered', 'denied')),
    notes TEXT,
    request_type VARCHAR DEFAULT 'full_access',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster queries
CREATE INDEX idx_dsar_requests_identifier ON public.dsar_requests(identifier);
CREATE INDEX idx_dsar_requests_email ON public.dsar_requests(email);
CREATE INDEX idx_dsar_requests_status ON public.dsar_requests(status);
CREATE INDEX idx_dsar_requests_received_at ON public.dsar_requests(received_at);

-- Disable RLS for n8n
ALTER TABLE public.dsar_requests DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. AUDIT_LOG - Complete audit trail (immutable records)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dsar_id UUID NOT NULL REFERENCES public.dsar_requests(id) ON DELETE CASCADE,
    action VARCHAR NOT NULL,
    actor VARCHAR NOT NULL,
    actor_type VARCHAR NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_details JSONB,
    ip_address VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for auditing
CREATE INDEX idx_audit_log_dsar_id ON public.audit_log(dsar_id);
CREATE INDEX idx_audit_log_action ON public.audit_log(action);
CREATE INDEX idx_audit_log_created_at ON public.audit_log(created_at);

-- Disable RLS
ALTER TABLE public.audit_log DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. APPROVAL_QUEUE - Manual review queue for high-risk requests
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.approval_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dsar_id UUID NOT NULL REFERENCES public.dsar_requests(id) ON DELETE CASCADE,
    status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    risk_level VARCHAR,
    risk_score FLOAT,
    notes TEXT,
    approved_by VARCHAR,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for queue operations
CREATE INDEX idx_approval_queue_status ON public.approval_queue(status);
CREATE INDEX idx_approval_queue_dsar_id ON public.approval_queue(dsar_id);

-- Disable RLS
ALTER TABLE public.approval_queue DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. ENCRYPTION_VAULT - Secure password storage
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.encryption_vault (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dsar_id UUID NOT NULL REFERENCES public.dsar_requests(id) ON DELETE CASCADE,
    password_hash TEXT NOT NULL,
    encryption_algorithm VARCHAR DEFAULT 'AES-256-CBC',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP + INTERVAL '24 hours',
    is_used BOOLEAN DEFAULT FALSE
);

-- Index for expiry cleanup
CREATE INDEX idx_encryption_vault_expires_at ON public.encryption_vault(expires_at);
CREATE INDEX idx_encryption_vault_dsar_id ON public.encryption_vault(dsar_id);

-- Disable RLS
ALTER TABLE public.encryption_vault DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. DSAR_DELIVERIES - Email delivery tracking
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.dsar_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dsar_id UUID NOT NULL REFERENCES public.dsar_requests(id) ON DELETE CASCADE,
    email_to VARCHAR NOT NULL,
    delivery_type VARCHAR NOT NULL CHECK (delivery_type IN ('pdf', 'password')),
    status VARCHAR DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'bounced')),
    email_subject TEXT,
    email_status VARCHAR,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for delivery tracking
CREATE INDEX idx_dsar_deliveries_dsar_id ON public.dsar_deliveries(dsar_id);
CREATE INDEX idx_dsar_deliveries_sent_at ON public.dsar_deliveries(sent_at);

-- Disable RLS
ALTER TABLE public.dsar_deliveries DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. EXTRACTED_DATA - Raw data from all systems
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.extracted_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dsar_id UUID NOT NULL REFERENCES public.dsar_requests(id) ON DELETE CASCADE,
    system_name VARCHAR NOT NULL,
    data_json JSONB NOT NULL,
    extracted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for system queries
CREATE INDEX idx_extracted_data_dsar_id ON public.extracted_data(dsar_id);
CREATE INDEX idx_extracted_data_system_name ON public.extracted_data(system_name);

-- Disable RLS
ALTER TABLE public.extracted_data DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. PROCESSED_DATA - Deduplicated and categorized data
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.processed_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dsar_id UUID NOT NULL REFERENCES public.dsar_requests(id) ON DELETE CASCADE,
    status VARCHAR DEFAULT 'completed',
    total_records_extracted INTEGER DEFAULT 0,
    total_records_deduplicated INTEGER DEFAULT 0,
    pii_summary JSONB,
    data_by_category JSONB,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_processed_data_dsar_id ON public.processed_data(dsar_id);

-- Disable RLS
ALTER TABLE public.processed_data DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 8. CREDENTIALS_VAULT - Stored credentials for integrations
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.credentials_vault (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_name VARCHAR NOT NULL,
    credential_name VARCHAR NOT NULL,
    credential_value TEXT NOT NULL,
    is_encrypted BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Unique constraint: one credential per system
CREATE UNIQUE INDEX idx_credentials_vault_system ON public.credentials_vault(system_name, credential_name);

-- Disable RLS
ALTER TABLE public.credentials_vault DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 9. SYSTEMS_INVENTORY - Available systems for data extraction
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.systems_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_name VARCHAR NOT NULL UNIQUE,
    system_type VARCHAR NOT NULL,
    api_endpoint VARCHAR,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync TIMESTAMP,
    sync_frequency VARCHAR DEFAULT 'daily',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Disable RLS
ALTER TABLE public.systems_inventory DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INDEXES - Additional performance indexes
-- ============================================================================

-- For joining dsar_requests with audit logs
CREATE INDEX idx_audit_log_dsar_created ON public.audit_log(dsar_id, created_at);

-- For cleanup queries (data retention)
CREATE INDEX idx_dsar_requests_deadline ON public.dsar_requests(deadline_at, status);

-- ============================================================================
-- TRIGGERS - Automatic updated_at timestamps
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
CREATE TRIGGER dsar_requests_updated_at BEFORE UPDATE ON public.dsar_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER approval_queue_updated_at BEFORE UPDATE ON public.approval_queue
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER credentials_vault_updated_at BEFORE UPDATE ON public.credentials_vault
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER systems_inventory_updated_at BEFORE UPDATE ON public.systems_inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS - Documentation
-- ============================================================================

COMMENT ON TABLE public.dsar_requests IS 'Main DSAR request records - one per data subject';
COMMENT ON TABLE public.audit_log IS 'Complete immutable audit trail of all events';
COMMENT ON TABLE public.approval_queue IS 'Manual review queue for high-risk requests';
COMMENT ON TABLE public.encryption_vault IS 'Secure storage of one-time decryption passwords';
COMMENT ON TABLE public.dsar_deliveries IS 'Email delivery tracking';
COMMENT ON TABLE public.extracted_data IS 'Raw extracted data from all systems';
COMMENT ON TABLE public.processed_data IS 'Cleaned, deduplicated, and categorized data';
COMMENT ON TABLE public.credentials_vault IS 'Credentials for system integrations';
COMMENT ON TABLE public.systems_inventory IS 'Catalog of available data systems';

-- ============================================================================
-- INITIAL SYSTEMS DATA
-- ============================================================================

-- Insert default systems
INSERT INTO public.systems_inventory (system_name, system_type, api_endpoint, is_active)
VALUES
    ('Email/IMAP', 'email', 'smtp.gmail.com', TRUE),
    ('HubSpot', 'crm', 'https://api.hubapi.com', TRUE),
    ('Zendesk', 'support', 'https://api.zendesk.com', TRUE)
ON CONFLICT (system_name) DO NOTHING;

-- ============================================================================
-- VERIFICATION - Check all tables created
-- ============================================================================

-- Run this query to verify all tables exist:
-- SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
--
-- You should see:
-- approval_queue
-- audit_log
-- credentials_vault
-- dsar_deliveries
-- dsar_requests
-- extracted_data
-- processed_data
-- systems_inventory

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
