-- In 20240608005000_rls_optimization.sql
BEGIN;

-- Create telemetry tables
CREATE SCHEMA IF NOT EXISTS telemetry;

CREATE TABLE IF NOT EXISTS telemetry.rls_evaluations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  view_name TEXT NOT NULL,
  duration_ms DOUBLE PRECISION NOT NULL,
  evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS optimization function
CREATE OR REPLACE FUNCTION log_rls_evaluation(view_name TEXT)
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO telemetry.rls_evaluations (view_name, duration_ms)
  VALUES (view_name, extract(milliseconds from clock_timestamp() - 
    (SELECT query_start FROM pg_stat_activity WHERE pid = pg_backend_pid())));
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Add denormalized columns to materialized views
ALTER MATERIALIZED VIEW IF EXISTS relationship_strength_analytics_mv 
ADD COLUMN IF NOT EXISTS accessible_by UUID[] GENERATED ALWAYS AS (
  ARRAY[from_person_id, to_person_id]
) STORED;

ALTER MATERIALIZED VIEW IF EXISTS brotherhood_visibility_mv 
ADD COLUMN IF NOT EXISTS accessible_by UUID[] GENERATED ALWAYS AS (
  ARRAY[person_id]
) STORED;

ALTER MATERIALIZED VIEW IF EXISTS mentor_relationship_health_mv 
ADD COLUMN IF NOT EXISTS accessible_by UUID[] GENERATED ALWAYS AS (
  ARRAY[mentor_id, student_id]
) STORED;

-- Drop old RLS policies and create optimized ones
DROP POLICY IF EXISTS "relationship_strength_mv_read_self" ON relationship_strength_analytics_mv;
CREATE POLICY "relationship_strength_mv_read_self" 
ON relationship_strength_analytics_mv FOR SELECT 
USING (
  (SELECT id FROM people WHERE auth_id = auth.uid()) = ANY(accessible_by)
  OR
  EXISTS (
    SELECT 1 FROM people
    JOIN roles ON people.role_id = roles.id
    WHERE people.auth_id = auth.uid() 
    AND (roles.name = 'admin' OR roles.name = 'staff')
  )
);

-- Create RLS telemetry triggers
CREATE TRIGGER log_relationship_strength_rls
AFTER SELECT ON relationship_strength_analytics_mv
FOR EACH STATEMENT EXECUTE FUNCTION log_rls_evaluation('relationship_strength_analytics_mv');

-- Add similar triggers and policies for other materialized views

COMMIT;
