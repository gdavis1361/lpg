-- 20240603_relationship_framework_v2.sql
-- Relationship Framework – *non‑destructive* / *idempotent* version
-- This migration only **adds** new structures; it never drops or alters existing
-- NOT‑NULL constraints or defaults.  Safe to run multiple times.

-- 0.  Prerequisites -----------------------------------------------------------
-- (uuid extension is usually created in the core foundation, but keep it idempotent)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1.  Lookup table ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS relationship_types (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code        TEXT NOT NULL UNIQUE,   -- short code: 'mentor', 'donor', etc.
  name        TEXT,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Populate canonical types (no‑op if they already exist)
INSERT INTO relationship_types (code, name) VALUES
  ('mentor', 'Mentor'),
  ('donor' , 'Donor' ),
  ('alumni', 'Alumni')
ON CONFLICT (code) DO NOTHING;

-- 2.  relationships table extensions -----------------------------------------
-- 2.1  FK to relationship_types
ALTER TABLE IF EXISTS relationships
  ADD COLUMN IF NOT EXISTS relationship_type_id UUID;
  
-- Add foreign key constraint if it doesn't exist yet
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_relationship_type'
  ) THEN
    ALTER TABLE relationships
      ADD CONSTRAINT fk_relationship_type
      FOREIGN KEY (relationship_type_id) REFERENCES relationship_types(id);
  END IF;
END$$;

-- 2.2  Additional relationship metadata
ALTER TABLE IF EXISTS relationships
  ADD COLUMN IF NOT EXISTS end_date       DATE,
  ADD COLUMN IF NOT EXISTS strength_score INT;

-- 2.3  Partial unique index enforcing one active relationship of each type
CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_relationship
  ON relationships (from_person_id, to_person_id, relationship_type_id)
  WHERE status = 'active' AND end_date IS NULL;

-- 3.  interactions table extensions ------------------------------------------
-- NOTE: We are **not** touching occurred_at.  We only add new, optional fields.
ALTER TABLE IF EXISTS interactions
  ADD COLUMN IF NOT EXISTS scheduled_at   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_planned     BOOLEAN      DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS status         TEXT         DEFAULT 'scheduled',
  ADD COLUMN IF NOT EXISTS sentiment_score INT;

-- Optional: status domain check (non‑destructive if already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_interactions_status'
  ) THEN
    ALTER TABLE interactions
      ADD CONSTRAINT chk_interactions_status
        CHECK (status IN ('scheduled','completed','canceled','rescheduled'));
  END IF;
END $$;
-- -----------------------------------------------------------------------------