-- Version: 2.0 (Refactored May 2025)
-- seed-entry.sql - Environment-aware entry point for Chattanooga Prep Relationship Platform
-- This file detects the current environment and runs the appropriate seed file
-- For development: seed-dev.sql (includes reference data + sample data)
-- For production: seed-prod.sql (only includes reference data)

DO $$
DECLARE
  v_environment TEXT;
BEGIN
  -- Attempt to get environment from Supabase settings
  BEGIN
    v_environment := COALESCE(current_setting('app.environment', true), 'dev');
  EXCEPTION WHEN OTHERS THEN
    -- Default to dev if setting doesn't exist
    v_environment := 'dev';
  END;
  
  RAISE NOTICE 'Detected environment: %', v_environment;
  
  -- Run the appropriate seed file based on environment
  IF v_environment = 'prod' OR v_environment = 'production' THEN
    RAISE NOTICE 'Using production seed file (seed-prod.sql)...';
    \i 'seed-prod.sql';
  ELSE
    RAISE NOTICE 'Using development seed file (seed-dev.sql)...';
    \i 'seed-dev.sql';
  END IF;
END;
$$;
