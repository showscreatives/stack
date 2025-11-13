-- =====================================================
-- LeadFlow System - PostgreSQL Initialization Script
-- Multi-Database Setup for Production
-- Domain: leadsflowsys.online
-- =====================================================

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =====================================================
-- 1. Create Application Databases
-- =====================================================

-- Mautic Database
CREATE DATABASE mautic;

-- n8n Database
CREATE DATABASE n8n;

-- Metabase Database
CREATE DATABASE metabase;

-- WAHA Database
CREATE DATABASE waha;

-- =====================================================
-- 2. Create Application Users with Passwords
-- =====================================================

-- Mautic User
CREATE USER mauticuser WITH PASSWORD 'IqLX0Igz7d4LWwmWR&vWYZ3y';
ALTER ROLE mauticuser SET client_encoding TO 'utf8';
ALTER ROLE mauticuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE mauticuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE mautic TO mauticuser;

-- n8n User
CREATE USER n8nuser WITH PASSWORD 'P1w&a1gmDqoWqq!O@vOSZQG$';
ALTER ROLE n8nuser SET client_encoding TO 'utf8';
ALTER ROLE n8nuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE n8nuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8nuser;

-- Metabase User
CREATE USER metabaseuser WITH PASSWORD '3X8FS!F9$9v5E%rqL1@aBbVu';
ALTER ROLE metabaseuser SET client_encoding TO 'utf8';
ALTER ROLE metabaseuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE metabaseuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE metabase TO metabaseuser;

-- WAHA User
CREATE USER wahauser WITH PASSWORD 'MyJ97^EplPhv2NLXY@7dNAA@';
ALTER ROLE wahauser SET client_encoding TO 'utf8';
ALTER ROLE wahauser SET default_transaction_isolation TO 'read committed';
ALTER ROLE wahauser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE waha TO wahauser;

-- =====================================================
-- 3. Connect to leadflow database for LeadFlow tables
-- =====================================================

\c leadflow

-- =====================================================
-- PUBLIC SCHEMA TABLES (Shared Across All Clients)
-- =====================================================

-- Clients Management
CREATE TABLE IF NOT EXISTS public.clients (
    client_id SERIAL PRIMARY KEY,
    client_name VARCHAR(255) NOT NULL UNIQUE,
    api_key UUID NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    max_leads_per_month INTEGER DEFAULT 10000,
    trial_period_days INTEGER DEFAULT 14,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients(status);
CREATE INDEX IF NOT EXISTS idx_clients_api_key ON public.clients(api_key);

-- Raw Lead Ingestion
CREATE TABLE IF NOT EXISTS public.raw_leads (
    lead_id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES public.clients(client_id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL DEFAULT 'form',
    raw_data JSONB NOT NULL,
    ingestion_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    verification_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'risky', 'invalid')),
    quality_score INTEGER DEFAULT 0 CHECK (quality_score >= 0 AND quality_score <= 100),
    processing_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'complete', 'failed')),
    error_message TEXT,
    processed_at TIMESTAMP,
    stored_in_client_schema BOOLEAN DEFAULT FALSE,
    enriched_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_raw_leads_client_id ON public.raw_leads(client_id);
CREATE INDEX IF NOT EXISTS idx_raw_leads_source ON public.raw_leads(source);
CREATE INDEX IF NOT EXISTS idx_raw_leads_verification_status ON public.raw_leads(verification_status);
CREATE INDEX IF NOT EXISTS idx_raw_leads_quality_score ON public.raw_leads(quality_score);

-- Lead ID Mapping Hub
CREATE TABLE IF NOT EXISTS public.lead_mappings (
    mapping_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
    internal_lead_id INTEGER NOT NULL REFERENCES public.raw_leads(lead_id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL,
    mautic_contact_id INTEGER,
    crm_lead_id INTEGER,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    domain_verified BOOLEAN DEFAULT FALSE,
    quality_score INTEGER DEFAULT 0,
    sync_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed', 'partial')),
    conversion_status VARCHAR(50) DEFAULT 'new' CHECK (conversion_status IN ('new', 'trial', 'paid', 'churned')),
    last_sync_at TIMESTAMP,
    sync_error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lead_mappings_client_id ON public.lead_mappings(client_id);
CREATE INDEX IF NOT EXISTS idx_lead_mappings_mautic_contact_id ON public.lead_mappings(mautic_contact_id);

-- Verification Logs
CREATE TABLE IF NOT EXISTS public.verification_logs (
    log_id SERIAL PRIMARY KEY,
    lead_id INTEGER NOT NULL REFERENCES public.raw_leads(lead_id) ON DELETE CASCADE,
    verification_type VARCHAR(50) NOT NULL CHECK (verification_type IN ('email_format', 'dns_lookup', 'smtp_verify', 'phone_verify', 'domain_verify')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('verified', 'risky', 'invalid', 'failed')),
    verification_value VARCHAR(255),
    api_provider VARCHAR(100),
    api_response JSONB,
    error_message TEXT,
    verification_timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verification_logs_lead_id ON public.verification_logs(lead_id);

-- Sync Errors
CREATE TABLE IF NOT EXISTS public.sync_errors (
    error_id SERIAL PRIMARY KEY,
    lead_id INTEGER NOT NULL REFERENCES public.raw_leads(lead_id) ON DELETE CASCADE,
    error_type VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    stacktrace TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP,
    resolution_status VARCHAR(50) DEFAULT 'open' CHECK (resolution_status IN ('open', 'resolved', 'ignored')),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_errors_lead_id ON public.sync_errors(lead_id);

-- =====================================================
-- 4. Insert Default Client
-- =====================================================

INSERT INTO public.clients (client_name, status)
VALUES ('LeadFlowSys Production', 'active')
ON CONFLICT (client_name) DO NOTHING;

-- =====================================================
-- 5. Grant Permissions
-- =====================================================

-- Grant permissions on leadflow database
GRANT ALL ON SCHEMA public TO mauticuser;
GRANT ALL ON SCHEMA public TO n8nuser;
GRANT ALL ON SCHEMA public TO metabaseuser;
GRANT ALL ON SCHEMA public TO wahauser;

GRANT ALL ON ALL TABLES IN SCHEMA public TO mauticuser;
GRANT ALL ON ALL TABLES IN SCHEMA public TO n8nuser;
GRANT ALL ON ALL TABLES IN SCHEMA public TO metabaseuser;
GRANT ALL ON ALL TABLES IN SCHEMA public TO wahauser;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO mauticuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO n8nuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO metabaseuser;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO wahauser;

-- =====================================================
-- 6. Create Views for Reporting
-- =====================================================

CREATE OR REPLACE VIEW public.lead_status_summary AS
SELECT
    c.client_id,
    c.client_name,
    COUNT(rl.lead_id) as total_leads,
    COUNT(CASE WHEN rl.verification_status = 'verified' THEN 1 END) as verified_leads,
    COUNT(CASE WHEN rl.verification_status = 'risky' THEN 1 END) as risky_leads,
    COUNT(CASE WHEN rl.verification_status = 'invalid' THEN 1 END) as invalid_leads,
    ROUND(COUNT(CASE WHEN rl.verification_status = 'verified' THEN 1 END)::numeric / NULLIF(COUNT(rl.lead_id), 0) * 100, 2) as verification_rate_pct,
    ROUND(AVG(rl.quality_score), 1) as avg_quality_score
FROM public.clients c
LEFT JOIN public.raw_leads rl ON c.client_id = rl.client_id
GROUP BY c.client_id, c.client_name;

-- =====================================================
-- Initialization Complete
-- =====================================================
