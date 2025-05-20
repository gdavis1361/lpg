-- Prerequisites: 20250519000000_enable_extensions.sql (for pg_cron)
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
