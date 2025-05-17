-- migration_2_relationship_framework.sql
-- Phase 2: Relationship Framework – relationship types, richer relationship & interaction models
-- -----------------------------------------------------------------------------
-- Applies on top of 20240603_core_foundation.sql.

-- ***************************
-- UP MIGRATION --------------
-- ***************************

-- 1. Lookup: relationship_types ----------------------------------------------
CREATE TABLE IF NOT EXISTS relationship_types (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code        TEXT NOT NULL UNIQUE,  -- short code: 'mentor', 'donor', etc.
  name        TEXT,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed a few canonical relationship types
INSERT INTO relationship_types (code, name) VALUES
  ('mentor', 'Mentor')
ON CONFLICT (code) DO NOTHING;
INSERT INTO relationship_types (code, name) VALUES
  ('donor',  'Donor')
ON CONFLICT (code) DO NOTHING;
INSERT INTO relationship_types (code, name) VALUES
  ('alumni', 'Alumni')
ON CONFLICT (code) DO NOTHING;

-- 2. Relationships table refactor --------------------------------------------
-- 2.1 Add the FK column
ALTER TABLE relationships
  ADD COLUMN IF NOT EXISTS relationship_type_id UUID;

-- 2.2 Back-fill relationship_type_id from the old text column (if data exists)
UPDATE relationships r
SET relationship_type_id = rt.id
FROM relationship_types rt
WHERE r.relationship_type IS NOT NULL
  AND rt.code = r.relationship_type;

-- Safeguard: Check for unmapped relationship_type values before making relationship_type_id NOT NULL
DO $$
DECLARE
  unmapped_count INTEGER;
  sample_unmapped_types TEXT;
BEGIN
  SELECT COUNT(*), array_to_string(array_agg(DISTINCT r.relationship_type), ', ')
  INTO unmapped_count, sample_unmapped_types
  FROM relationships r
  LEFT JOIN relationship_types rt ON rt.code = r.relationship_type
  WHERE r.relationship_type IS NOT NULL AND rt.id IS NULL;

  RAISE NOTICE 'Found % unmapped relationship_type values. Sample unmapped types: %', unmapped_count, COALESCE(sample_unmapped_types, 'None');

  IF unmapped_count > 0 THEN
    RAISE EXCEPTION 'Aborting migration: % unmapped relationship_type values detected. Please seed these types in relationship_types or clean data. Sample problematic types: %', unmapped_count, COALESCE(sample_unmapped_types, 'None');
  END IF;
END;
$$;

-- 2.3 Make the new column NOT NULL (safe if table is empty or back-fill worked)
ALTER TABLE relationships
  ALTER COLUMN relationship_type_id SET NOT NULL;

-- 2.4 Drop the old text column
ALTER TABLE relationships
  DROP COLUMN relationship_type;

-- 2.5 Add end_date & strength_score; make start_date explicit (nullable)
ALTER TABLE relationships
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS strength_score INT,
  ALTER COLUMN start_date DROP DEFAULT;

-- 2.6 Re-work uniqueness logic -------------------------------------------------
-- Drop the original constraint (name may vary across dev DBs, so IF EXISTS)
ALTER TABLE relationships
  DROP CONSTRAINT IF EXISTS unique_active_relationship;

-- Safeguard: Check for duplicate active relationships based on (from_person_id, to_person_id, relationship_type_id)
-- This check assumes relationship_type_id has been successfully populated by this stage.
DO $$
DECLARE
  duplicate_group_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO duplicate_group_count
  FROM (
    SELECT 1
    FROM relationships
    WHERE status = 'active'
      AND end_date IS NULL
      AND relationship_type_id IS NOT NULL -- Should be NOT NULL if previous steps and safeguard passed
    GROUP BY from_person_id, to_person_id, relationship_type_id
    HAVING COUNT(*) > 1
  ) AS duplicate_groups;

  RAISE NOTICE 'Found % groups of (from_person_id, to_person_id, relationship_type_id) that would violate the new unique index for active relationships.', duplicate_group_count;

  IF duplicate_group_count > 0 THEN
    RAISE EXCEPTION 'Aborting migration: % groups of duplicate active relationships detected (based on from_person_id, to_person_id, relationship_type_id) that would violate the new unique index. Please clean/merge these duplicates or mark them as inactive/ended.', duplicate_group_count;
  END IF;
END;
$$;

-- Add partial unique index enforcing one active relationship per type
CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_relationship
  ON relationships(from_person_id, to_person_id, relationship_type_id)
  WHERE status = 'active' AND end_date IS NULL;

-- 3. Interactions table extensions -------------------------------------------
ALTER TABLE interactions
  ALTER COLUMN occurred_at DROP NOT NULL,
  ALTER COLUMN occurred_at DROP DEFAULT,
  ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_planned BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'canceled', 'rescheduled')),
  ADD COLUMN IF NOT EXISTS sentiment_score INT;

-- ***************************
-- DOWN MIGRATION ------------
-- ***************************
-- (Down migration moved to separate file: 20240603_relationship_framework.down.sql)

-- -----------------------------------------------------------------------------
-- End migration_2_relationship_framework.sql 