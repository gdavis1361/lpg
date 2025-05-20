-- 20240602000000_relationship_types.sql
-- Extracted from 20240603000100_relationship_framework.sql

-- Create lookup table for relationship types
BEGIN;

-- 0. Prerequisites
-- (uuid extension is usually created in the core foundation, but keep it idempotent)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Relationship types lookup table
CREATE TABLE IF NOT EXISTS relationship_types (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code        TEXT NOT NULL UNIQUE,   -- short code: 'mentor', 'donor', etc.
  name        TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Populate canonical types (no‑op if they already exist)
INSERT INTO relationship_types (code, name) VALUES
  ('mentor', 'Mentor'),
  ('donor' , 'Donor' ),
  ('alumni', 'Alumni'),
  ('teacher', 'Teacher'),
  ('advisor', 'Advisor'),
  ('counselor', 'Counselor')
ON CONFLICT (code) DO NOTHING;

-- Apply RLS immediately for security
ALTER TABLE relationship_types ENABLE ROW LEVEL SECURITY;

-- Base RLS policy (allows authenticated users to view relationship types)
CREATE POLICY "relationship_types_read_authenticated" ON relationship_types
  FOR SELECT USING (auth.role() = 'authenticated');

COMMENT ON TABLE relationship_types IS 'Defines the types of relationships that can exist between people';
COMMENT ON COLUMN relationship_types.code IS 'Unique identifier code for the relationship type';
COMMENT ON COLUMN relationship_types.name IS 'Display name for the relationship type';

COMMIT; 