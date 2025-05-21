-- 20240601000000_enable_extensions.sql
-- Prerequisites: None
-- Purpose: Enables extensions required by subsequent migrations.

BEGIN;

-- UUID generation for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
COMMENT ON EXTENSION "uuid-ossp" IS 'UUID generation functions for primary keys';

-- Cron functionality for scheduled jobs
CREATE EXTENSION IF NOT EXISTS "pg_cron";
COMMENT ON EXTENSION "pg_cron" IS 'Job scheduling for various automated tasks';

-- Full text search capability / text similarity
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
COMMENT ON EXTENSION "pg_trgm" IS 'Text similarity and indexing for search capabilities';

-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
COMMENT ON EXTENSION "pgcrypto" IS 'Cryptographic functions for secure data storage';

COMMIT; -- migration_1_core_foundation.sql
-- Phase 1: Core foundation for the Chattanooga Prep Relationship-Centered Platform
-- -----------------------------------------------------------------------------
-- This migration sets up the base schema, seeds initial lookup data, enables
-- row-level security (RLS) on all user-facing tables, and wires automatic
-- updated_at handling.

-- 1. Extensions ----------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Helper functions -----------------------------------------------------------
-- Automatically bump updated_at on UPDATE.
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Tables --------------------------------------------------------------------

-- 3.1 People -------------------------------------------------------------------
CREATE TABLE people (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id       UUID UNIQUE, -- Links to Supabase auth.users
  first_name    TEXT NOT NULL,
  last_name     TEXT NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  phone         TEXT,
  avatar_url    TEXT,
  bio           TEXT,
  address_line1 TEXT,
  address_line2 TEXT,
  city          TEXT,
  state         TEXT,
  postal_code   TEXT,
  country       TEXT DEFAULT 'USA',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_active_at TIMESTAMPTZ,
  status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  metadata      JSONB DEFAULT '{}'::JSONB
);

-- 3.2 Roles --------------------------------------------------------------------
CREATE TABLE roles (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  permissions JSONB DEFAULT '{}'::JSONB
);

-- 3.3 People ↔ Roles (many-to-many) -------------------------------------------
CREATE TABLE people_roles (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id    UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  role_id      UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  assigned_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  assigned_by  UUID REFERENCES people(id),
  primary_role BOOLEAN DEFAULT FALSE,
  start_date   DATE,
  end_date     DATE,
  notes        TEXT,
  UNIQUE (person_id, role_id)
);

-- Enforce at most one primary role per person
CREATE UNIQUE INDEX unique_primary_role_per_person
  ON people_roles(person_id)
  WHERE primary_role IS TRUE;

-- 3.4 Relationships ------------------------------------------------------------
CREATE TABLE relationships (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_person_id    UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  to_person_id      UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL, -- e.g., 'mentor', 'donor', 'alumni'
  start_date        DATE DEFAULT CURRENT_DATE,
  status            TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'potential')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by        UUID REFERENCES people(id),
  notes             TEXT,
  metadata          JSONB DEFAULT '{}'::JSONB,
  CONSTRAINT unique_active_relationship UNIQUE (from_person_id, to_person_id, relationship_type)
    DEFERRABLE INITIALLY IMMEDIATE
    -- Prevent duplicate active relationships only when status is 'active'
    -- (implemented via partial unique index in Postgres ≥ 15, but kept as CHECK here)
    ,
  CONSTRAINT no_self_relationships CHECK (from_person_id <> to_person_id)
);

-- 3.5 Interactions -------------------------------------------------------------
CREATE TABLE interactions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  interaction_type TEXT NOT NULL, -- e.g., 'meeting', 'email', 'phone_call'
  title            TEXT NOT NULL,
  description      TEXT,
  occurred_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  duration_minutes INT,
  location         TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by       UUID REFERENCES people(id),
  follow_up_needed BOOLEAN DEFAULT FALSE,
  follow_up_date   DATE,
  follow_up_notes  TEXT,
  metadata         JSONB DEFAULT '{}'::JSONB
);

-- 3.6 Interaction ↔ Participants ---------------------------------------------
CREATE TABLE interaction_participants (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  interaction_id UUID NOT NULL REFERENCES interactions(id) ON DELETE CASCADE,
  person_id      UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  role           TEXT, -- Role in this interaction (e.g., 'host', 'attendee')
  attended       BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (interaction_id, person_id)
);

-- 3.7 Tags & junction tables ---------------------------------------------------
CREATE TABLE tags (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT NOT NULL UNIQUE,
  category   TEXT,
  color      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE people_tags (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id  UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  tag_id     UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES people(id),
  UNIQUE (person_id, tag_id)
);

CREATE TABLE interaction_tags (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  interaction_id UUID NOT NULL REFERENCES interactions(id) ON DELETE CASCADE,
  tag_id         UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by     UUID REFERENCES people(id),
  UNIQUE (interaction_id, tag_id)
);

-- 3.8 Organizations -----------------------------------------------------------
CREATE TABLE organizations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL UNIQUE,
  type        TEXT,                         -- e.g., 'school', 'employer'
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.9 Affiliations ------------------------------------------------------------
CREATE TABLE affiliations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id       UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  role            TEXT,      -- e.g., 'student', 'alumni', 'staff'
  start_date      DATE,
  end_date        DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (person_id, organization_id, role)
);

-- 4. Triggers ------------------------------------------------------------------
CREATE TRIGGER set_people_updated_at
  BEFORE UPDATE ON people
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_relationships_updated_at
  BEFORE UPDATE ON relationships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_interactions_updated_at
  BEFORE UPDATE ON interactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Indexes -------------------------------------------------------------------
CREATE INDEX idx_people_email        ON people(email);
CREATE INDEX idx_people_last_name    ON people(last_name);
CREATE INDEX idx_people_status       ON people(status);

CREATE INDEX idx_people_roles_person ON people_roles(person_id);
CREATE INDEX idx_people_roles_role   ON people_roles(role_id);

CREATE INDEX idx_relationships_from  ON relationships(from_person_id);
CREATE INDEX idx_relationships_to    ON relationships(to_person_id);

CREATE INDEX idx_interactions_occurred_at ON interactions(occurred_at);

CREATE INDEX idx_interaction_participants_interaction
  ON interaction_participants(interaction_id);
CREATE INDEX idx_interaction_participants_person
  ON interaction_participants(person_id);

CREATE INDEX idx_tags_category ON tags(category);

-- 6. Row-Level Security --------------------------------------------------------
-- Enable RLS on all user-facing tables (people already handled below).
ALTER TABLE people                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationships              ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions               ENABLE ROW LEVEL SECURITY;
ALTER TABLE people_roles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE interaction_participants   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE people_tags                ENABLE ROW LEVEL SECURITY;
ALTER TABLE interaction_tags           ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations              ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliations               ENABLE ROW LEVEL SECURITY;

-- Baseline SELECT policies (liberal for MVP – will tighten later).
CREATE POLICY "People view – authenticated" ON people
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Relationships view – authenticated" ON relationships
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Interactions view – authenticated" ON interactions
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "People-roles view – authenticated" ON people_roles
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Interaction participants view – authenticated" ON interaction_participants
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Tags view – authenticated" ON tags
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "People-tags view – authenticated" ON people_tags
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Interaction-tags view – authenticated" ON interaction_tags
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Organizations view – authenticated" ON organizations
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Affiliations view – authenticated" ON affiliations
  FOR SELECT USING (auth.role() = 'authenticated');

-- 7. Seed data -----------------------------------------------------------------
INSERT INTO roles (name, description, permissions) VALUES
  ('admin',  'System administrator with full access',           '{"all": true}'::jsonb),
  ('mentor', 'Mentors students throughout their journey',       '{"mentor_features": true}'::jsonb),
  ('donor',  'Financial supporters of the school',              '{"donor_features": true}'::jsonb),
  ('alumni', 'Graduated students',                               '{"alumni_features": true}'::jsonb),
  ('staff',  'School staff members',                             '{"staff_features": true}'::jsonb);

INSERT INTO tags (name, category, color) VALUES
  ('STEM',          'interest', '#4CAF50'),
  ('Arts',          'interest', '#2196F3'),
  ('Leadership',    'skill',    '#FFC107'),
  ('College Prep',  'program',  '#9C27B0'),
  ('Financial Aid', 'need',     '#F44336');

-- -----------------------------------------------------------------------------
-- End migration_1_core_foundation.sql -- Prerequisites: 20250519000000_enable_extensions.sql (for pg_cron)
-- Purpose: Sets up environment configuration and related functions.

-- Create app settings schema for configuration
CREATE SCHEMA IF NOT EXISTS settings;
COMMENT ON SCHEMA settings IS 'Schema for application-level settings and configuration.';

-- Create a config table to store persistent settings
CREATE TABLE IF NOT EXISTS settings.config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE settings.config IS 'Stores persistent application settings.';
COMMENT ON COLUMN settings.config.key IS 'The unique key for the setting.';
COMMENT ON COLUMN settings.config.value IS 'The JSONB value of the setting.';
COMMENT ON COLUMN settings.config.updated_at IS 'Timestamp of the last update to the setting.';

-- Create a function to set the environment
CREATE OR REPLACE FUNCTION settings.set_environment(env TEXT)
RETURNS VOID AS $$
BEGIN
  -- Store the environment setting in a session variable (non-persistent)
  PERFORM set_config('app.environment', env, false);
  
  -- Create or update the persistent settings record
  INSERT INTO settings.config (key, value, updated_at)
  VALUES ('environment', jsonb_build_object('value', env), NOW())
  ON CONFLICT (key) DO UPDATE
  SET value = jsonb_build_object('value', env),
      updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
COMMENT ON FUNCTION settings.set_environment(TEXT) IS 'Sets the application environment (e.g., development, production) persistently and for the current session.';

-- Set default environment (e.g., 'development')
-- This ensures a value is present. Override in specific environments as needed.
SELECT settings.set_environment('development');

-- Create a function to get current environment
CREATE OR REPLACE FUNCTION public.current_environment()
RETURNS TEXT AS $$
DECLARE
  env_value TEXT;
BEGIN
  -- Try to get from session variable first
  env_value := current_setting('app.environment', true);
  
  -- If not in session, try to get from persistent config
  IF env_value IS NULL THEN
    SELECT value->>'value' INTO env_value FROM settings.config WHERE key = 'environment';
  END IF;
  
  -- Default to 'development' if still not found
  RETURN COALESCE(env_value, 'development');
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION public.current_environment() IS 'Retrieves the current application environment, defaulting to ''development''.';

-- Function to refresh materialized views, aware of the environment
CREATE OR REPLACE FUNCTION public.refresh_materialized_views()
RETURNS VOID AS $$
BEGIN
  -- Only refresh in production to avoid unnecessary load in dev/staging
  IF public.current_environment() = 'production' THEN
    -- Add REFRESH MATERIALIZED VIEW CONCURRENTLY commands here as MVs are created
    -- Example: REFRESH MATERIALIZED VIEW CONCURRENTLY IF EXISTS public.example_mv;
    
    -- For now, this will refresh the MVs planned:
    REFRESH MATERIALIZED VIEW CONCURRENTLY IF EXISTS public.relationship_strength_analytics_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY IF EXISTS public.mentor_relationship_health_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY IF EXISTS public.brotherhood_visibility_mv;
  END IF;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION public.refresh_materialized_views() IS 'Refreshes all relevant materialized views, typically run on a schedule. Only executes in ''production'' environment.';

-- Schedule the refresh - only active in production
-- This cron job attempts to run daily at 2 AM server time.
-- The CASE statement inside ensures refresh_materialized_views() only runs if the environment is 'production'.
SELECT cron.schedule(
  'refresh_mvs_daily', -- name of the cron job
  '0 2 * * *',         -- cron schedule: daily at 2:00 AM
  $$
  SELECT public.refresh_materialized_views();
  $$
);
COMMENT ON FUNCTION cron.schedule(TEXT, TEXT, TEXT) IS 'Schedules the daily refresh of materialized views if in production environment.';
