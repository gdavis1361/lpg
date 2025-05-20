-- migration_2_relationship_framework.down.sql
-- Roll-back for 20240603_relationship_framework.sql
-- --------------------------------------------------
-- IMPORTANT: run this only if the corresponding UP migration has been applied.

-- 1. Revert Interaction table changes -----------------------------------------
ALTER TABLE interactions
  DROP COLUMN IF EXISTS sentiment_score,
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS is_planned,
  DROP COLUMN IF EXISTS scheduled_at,
  ALTER COLUMN occurred_at SET DEFAULT NOW(),
  ALTER COLUMN occurred_at SET NOT NULL;

-- 2. Relationships rollback ----------------------------------------------------
-- 2.1 Drop the partial unique index (if present)
DROP INDEX IF EXISTS uniq_active_relationship;

-- 2.2 Add legacy text column back
ALTER TABLE relationships
  ADD COLUMN IF NOT EXISTS relationship_type TEXT;

-- 2.3 Back-fill string column from FK where possible
UPDATE relationships r
SET relationship_type = rt.code
FROM relationship_types rt
WHERE r.relationship_type IS NULL
  AND r.relationship_type_id = rt.id;

-- 2.4 Remove FK column
ALTER TABLE relationships
  DROP COLUMN IF EXISTS relationship_type_id;

-- 2.5 Restore default on start_date
ALTER TABLE relationships
  ALTER COLUMN start_date SET DEFAULT CURRENT_DATE;

-- 2.6 Recreate original uniqueness constraint
ALTER TABLE relationships
  ADD CONSTRAINT IF NOT EXISTS unique_active_relationship
    UNIQUE (from_person_id, to_person_id, relationship_type);

-- 2.7 Drop additional columns added in UP
ALTER TABLE relationships
  DROP COLUMN IF EXISTS end_date,
  DROP COLUMN IF EXISTS strength_score;

-- 3. Drop lookup table ---------------------------------------------------------
DROP TABLE IF EXISTS relationship_types;

-- End migration_2_relationship_framework.down.sql 