#!/usr/bin/env bash
set -euo pipefail

# 0. Ensure a clean slate by dropping and recreating the public schema if it exists.
echo "🗑️  Dropping & recreating public schema…"

# 1. Boot a disposable Postgres via Supabase CLI (runs in Docker).
supabase start > /dev/null 2>&1 &
SP_PID=$!
echo "⏳  Starting scratch Supabase…"

# Connection string for the local Supabase Postgres instance
DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

# Wait until Postgres is accepting connections instead of sleeping blindly.
until psql "$DB_URL" -v ON_ERROR_STOP=1 -c '\q' 2>/dev/null; do
  sleep 1
done

# Now that the DB is reachable, drop and recreate the public schema to guarantee a clean slate.
psql "$DB_URL" -v ON_ERROR_STOP=1 <<'SQL'
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
SQL

# Ensure the container is stopped even if the script exits early (Ctrl-C, error, etc.).
cleanup() {
  supabase stop
  kill "$SP_PID" 2>/dev/null || true
}
trap cleanup EXIT

# 2. Apply all migration files in chronological order.
echo "⚙️   Applying migrations…"
for mig in $(ls lpg-backend/supabase/migrations/*.sql | grep -v '\.down\.sql$' | sort); do
  echo "   ↪️  $mig"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$mig"
done

# 3. Run diagnostic probes and tee output to results.txt.
echo "🔍  Running probes…"
psql "$DB_URL" -v ON_ERROR_STOP=1 <<'SQL' | tee /tmp/probe_results.txt
\echo '-- Missing planned tables ------------------------'
WITH planned(name) AS (
  VALUES ('organizations'), ('affiliations'), ('relationship_types')
)
SELECT name AS missing_table
FROM planned
WHERE NOT EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_name = planned.name
);

\echo '-- Default NOW() copy-paste artifacts -------------'
SELECT table_name, column_name, column_default
FROM information_schema.columns
WHERE column_default ILIKE '%now()%' 
  AND table_name IN ('interactions','relationships');

\echo '-- RLS policy count per table --------------------'
SELECT tablename AS table_name, COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

\echo '-- Duplicate active-relationship stress test -----'
BEGIN;
-- Ensure dummy people exist for the test
INSERT INTO people (id, first_name, last_name, email)
VALUES ('11111111-1111-1111-1111-111111111111', 'Test', 'PersonA', 'persona@example.com'),
       ('22222222-2222-2222-2222-222222222222', 'Test', 'PersonB', 'personb@example.com')
ON CONFLICT (id) DO NOTHING;

-- Get the ID for 'mentor' relationship type
DO $$
DECLARE mentor_type_id UUID;
BEGIN
  SELECT id INTO mentor_type_id FROM relationship_types WHERE code = 'mentor' LIMIT 1;

  IF mentor_type_id IS NULL THEN
    RAISE WARNING 'Stress test: Could not find ''mentor'' relationship type ID. Skipping relationship inserts.';
    RETURN;
  END IF;

  -- Attempt to insert one active and one inactive mentor relationship
  INSERT INTO relationships (from_person_id, to_person_id, relationship_type_id, status)
  VALUES ('11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222',
          mentor_type_id, 'active');

  INSERT INTO relationships (from_person_id, to_person_id, relationship_type_id, status)
  VALUES ('11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222',
          mentor_type_id, 'inactive');

  RAISE NOTICE 'Stress test: Inserted active and inactive relationships. Rollback will occur.';
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'Stress test: unique_violation as expected. This is correct if you attempted to insert two conflicting active relationships. SQLERRM: %', SQLERRM;
  WHEN others THEN
    RAISE WARNING 'Stress test: FAILED - SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
END $$;
ROLLBACK;
SQL

echo "✅  Probe output saved to /tmp/probe_results.txt"

# The cleanup trap will handle stopping; still echo for visibility.
echo "🧹  Stopping scratch Supabase…" 