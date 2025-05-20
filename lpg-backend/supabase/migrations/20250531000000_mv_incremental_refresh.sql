-- Migration: 20250531000000_mv_incremental_refresh.sql
-- Purpose: Implements an efficient incremental refresh mechanism for materialized views

-- 1. Create tracking table for materialized view refreshes
CREATE TABLE IF NOT EXISTS public.mv_refresh_tracking (
  view_name TEXT PRIMARY KEY,
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  refresh_frequency INTERVAL NOT NULL DEFAULT '1 day',
  last_refresh_duration INTERVAL,
  rows_affected INTEGER,
  is_refreshing BOOLEAN DEFAULT FALSE,
  refresh_error TEXT
);

-- 2. Insert initial tracking records for our materialized views
INSERT INTO mv_refresh_tracking (view_name, refresh_frequency)
VALUES 
  ('relationship_strength_analytics_mv', '1 day'),
  ('mentor_relationship_health_mv', '1 day'),
  ('brotherhood_visibility_mv', '1 day'),
  ('alumni_risk_assessment_mv', '1 day')
ON CONFLICT (view_name) DO NOTHING;

-- 3. Create a comprehensive function for incremental view refresh
CREATE OR REPLACE FUNCTION refresh_mv_incremental(
  p_view_name TEXT,
  p_full_refresh BOOLEAN DEFAULT FALSE
) RETURNS TABLE (refreshed_view TEXT, rows_affected INTEGER, duration_ms INTEGER) AS $$
DECLARE
  v_start_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
  v_last_refresh TIMESTAMPTZ;
  v_affected_count INTEGER := 0;
  v_threshold_date TIMESTAMPTZ;
  v_query TEXT;
  v_temp_table_name TEXT;
  v_duration_ms INTEGER;
BEGIN
  -- Record start time
  v_start_time := clock_timestamp();
  
  -- Update tracking table to show we're refreshing
  UPDATE mv_refresh_tracking
  SET is_refreshing = TRUE,
      refresh_error = NULL
  WHERE view_name = p_view_name;
  
  -- Get last refresh time
  SELECT last_updated INTO v_last_refresh 
  FROM mv_refresh_tracking
  WHERE view_name = p_view_name;
  
  -- Set threshold date for changes
  v_threshold_date := CASE 
    WHEN p_full_refresh THEN NULL 
    ELSE v_last_refresh
  END;
  
  -- Create a temp table name for the affected IDs
  v_temp_table_name := 'temp_refresh_' || p_view_name || '_' || replace(cast(now() as text), ' ', '_');
  
  BEGIN
    -- Handle different views based on their structure and dependencies
    CASE p_view_name
      ------------------------------------------------------
      -- relationship_strength_analytics_mv refresh logic
      ------------------------------------------------------
      WHEN 'relationship_strength_analytics_mv' THEN
        -- Create temp table for affected relationships
        EXECUTE format('
          CREATE TEMP TABLE %I (relationship_id UUID PRIMARY KEY) ON COMMIT DROP', 
          v_temp_table_name
        );
        
        -- Fill temp table with IDs of affected relationships
        IF p_full_refresh THEN
          -- For full refresh, include all relationships
          EXECUTE format('
            INSERT INTO %I (relationship_id)
            SELECT id FROM relationships',
            v_temp_table_name
          );
        ELSE
          -- For incremental refresh, only include recently modified relationships
          EXECUTE format('
            INSERT INTO %I (relationship_id)
            SELECT DISTINCT r.id 
            FROM relationships r
            LEFT JOIN interaction_participants ip_from ON r.from_person_id = ip_from.person_id
            LEFT JOIN interaction_participants ip_to ON r.to_person_id = ip_to.person_id
            LEFT JOIN interactions i ON ip_from.interaction_id = i.id AND ip_to.interaction_id = i.id
            WHERE
              -- Include relationships modified directly
              r.created_at > $1 OR r.updated_at > $1
              -- Or those with new/updated interactions
              OR i.created_at > $1 OR i.updated_at > $1
              -- Or those in recently modified relationship milestones
              OR EXISTS (
                SELECT 1 FROM relationship_milestones rm
                WHERE rm.relationship_id = r.id AND (rm.created_at > $1 OR rm.updated_at > $1)
              )',
            v_temp_table_name
          ) USING v_threshold_date;
        END IF;
        
        -- Get count of affected relationships
        EXECUTE format('SELECT COUNT(*) FROM %I', v_temp_table_name) INTO v_affected_count;
        
        -- Remove affected relationships from materialized view
        IF v_affected_count > 0 THEN
          EXECUTE format('
            DELETE FROM relationship_strength_analytics_mv
            WHERE relationship_id IN (SELECT relationship_id FROM %I)',
            v_temp_table_name
          );
          
          -- Reinsert with fresh calculations - we have to recreate the original view calculation
          -- since the original view has been dropped
          EXECUTE format('
            INSERT INTO relationship_strength_analytics_mv
            SELECT 
              r.id AS relationship_id,
              r.from_person_id,
              r.to_person_id,
              r.relationship_type_id,
              rt.name AS relationship_type_name,
              COUNT(DISTINCT i.id) AS interaction_count,
              COALESCE(AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time))/60), 0) AS avg_interaction_minutes,
              COUNT(DISTINCT i.id) FILTER (WHERE i.start_time > NOW() - INTERVAL ''90 days'') AS recent_interactions,
              -- Calculate strength score based on interaction patterns
              (
                -- Factor 1: Recency (higher score for more recent interactions)
                COALESCE(
                  CASE 
                    WHEN MAX(i.start_time) IS NULL THEN 1
                    WHEN MAX(i.start_time) > NOW() - INTERVAL ''30 days'' THEN 10
                    WHEN MAX(i.start_time) > NOW() - INTERVAL ''90 days'' THEN 7
                    WHEN MAX(i.start_time) > NOW() - INTERVAL ''180 days'' THEN 5
                    WHEN MAX(i.start_time) > NOW() - INTERVAL ''365 days'' THEN 3
                    ELSE 1
                  END, 1
                ) + 
                -- Factor 2: Frequency (higher score for more interactions)
                COALESCE(
                  CASE 
                    WHEN COUNT(i.id) = 0 THEN 1
                    WHEN COUNT(i.id) >= 20 THEN 10
                    WHEN COUNT(i.id) >= 10 THEN 8
                    WHEN COUNT(i.id) >= 5 THEN 6
                    WHEN COUNT(i.id) >= 2 THEN 4
                    ELSE 2
                  END, 1
                ) +
                -- Factor 3: Duration (based on average interaction length)
                COALESCE(
                  CASE 
                    WHEN AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time))/60) IS NULL THEN 5
                    WHEN AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time))/60) > 120 THEN 10
                    WHEN AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time))/60) > 60 THEN 8
                    WHEN AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time))/60) > 30 THEN 6
                    ELSE 4
                  END, 5
                )
              )/3.0 AS strength_score,
              -- Calculate reciprocity (interaction initiation balance)
              CASE 
                WHEN COUNT(i.id) = 0 THEN 5 -- Default for no interactions
                ELSE (
                  5 + 5 * (
                    1 - ABS(
                      COUNT(i.id) FILTER (WHERE i.created_by = r.from_person_id)::FLOAT / 
                      NULLIF(COUNT(i.id), 0) - 0.5
                    ) / 0.5
                  )
                )::NUMERIC(5,2)
              END AS reciprocity_score,
              NOW() AS calculated_at
            FROM relationships r
            JOIN relationship_types rt ON r.relationship_type_id = rt.id
            LEFT JOIN interaction_participants ip_from ON r.from_person_id = ip_from.person_id
            LEFT JOIN interaction_participants ip_to ON r.to_person_id = ip_to.person_id
            LEFT JOIN interactions i ON ip_from.interaction_id = i.id AND ip_to.interaction_id = i.id
            WHERE r.id IN (SELECT relationship_id FROM %I)
            GROUP BY r.id, r.from_person_id, r.to_person_id, r.relationship_type_id, rt.name',
            v_temp_table_name
          );
        END IF;
        
      ------------------------------------------------------
      -- mentor_relationship_health_mv refresh logic
      ------------------------------------------------------
      WHEN 'mentor_relationship_health_mv' THEN
        -- Create temp table for affected mentor relationships
        EXECUTE format('
          CREATE TEMP TABLE %I (relationship_id UUID PRIMARY KEY) ON COMMIT DROP', 
          v_temp_table_name
        );
        
        -- Fill temp table with mentor relationship IDs
        IF p_full_refresh THEN
          -- For full refresh, include all mentor relationships
          EXECUTE format('
            INSERT INTO %I (relationship_id)
            SELECT r.id 
            FROM relationships r
            JOIN relationship_types rt ON r.relationship_type_id = rt.id
            WHERE rt.code = ''mentor''',
            v_temp_table_name
          );
        ELSE
          -- For incremental refresh, only include modified mentor relationships
          EXECUTE format('
            INSERT INTO %I (relationship_id)
            SELECT DISTINCT r.id 
            FROM relationships r
            JOIN relationship_types rt ON r.relationship_type_id = rt.id
            LEFT JOIN interaction_participants ip_from ON r.from_person_id = ip_from.person_id
            LEFT JOIN interaction_participants ip_to ON r.to_person_id = ip_to.person_id
            LEFT JOIN interactions i ON ip_from.interaction_id = i.id AND ip_to.interaction_id = i.id
            LEFT JOIN relationship_milestones rm ON r.id = rm.relationship_id
            WHERE rt.code = ''mentor'' AND (
              -- Include relationships modified directly
              r.created_at > $1 OR r.updated_at > $1
              -- Or those with new/updated interactions
              OR i.created_at > $1 OR i.updated_at > $1
              -- Or those with modified milestones
              OR rm.created_at > $1 OR rm.updated_at > $1
            )',
            v_temp_table_name
          ) USING v_threshold_date;
        END IF;
        
        -- Get count of affected relationships
        EXECUTE format('SELECT COUNT(*) FROM %I', v_temp_table_name) INTO v_affected_count;
        
        -- Remove affected relationships from materialized view
        IF v_affected_count > 0 THEN
          EXECUTE format('
            DELETE FROM mentor_relationship_health_mv
            WHERE relationship_id IN (SELECT relationship_id FROM %I)',
            v_temp_table_name
          );
          
          -- Reinsert with fresh calculations - recreating the original view logic
          EXECUTE format('
            INSERT INTO mentor_relationship_health_mv
            SELECT
              r.id AS relationship_id,
              r.from_person_id AS mentor_id,
              pm.first_name AS mentor_first_name,
              pm.last_name AS mentor_last_name,
              r.to_person_id AS student_id,
              ps.first_name AS student_first_name,
              ps.last_name AS student_last_name,
              r.created_at AS start_date,
              EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.created_at)) AS relationship_years,
              COUNT(DISTINCT i.id) AS total_interactions,
              COUNT(DISTINCT i.id) FILTER (WHERE i.start_time > CURRENT_DATE - INTERVAL ''90 days'') AS recent_interactions,
              COUNT(DISTINCT rm.milestone_id) AS milestones_achieved,
              COUNT(DISTINCT mm.id) FILTER (WHERE mm.is_required = TRUE) AS required_milestones,
              COUNT(DISTINCT rm.milestone_id) FILTER (WHERE mm.is_required = TRUE) AS required_milestones_achieved,
              -- Health indicators
              CASE
                WHEN COUNT(DISTINCT i.id) FILTER (WHERE i.start_time > CURRENT_DATE - INTERVAL ''90 days'') = 0 THEN ''inactive''
                WHEN COUNT(DISTINCT rm.milestone_id) FILTER (WHERE mm.is_required = TRUE) < 
                     COUNT(DISTINCT mm.id) FILTER (WHERE mm.is_required = TRUE AND mm.typical_year <= EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.created_at))) THEN ''behind''
                ELSE ''healthy''
              END AS health_status
            FROM relationships r
            JOIN people pm ON r.from_person_id = pm.id -- mentor
            JOIN people ps ON r.to_person_id = ps.id -- student
            LEFT JOIN interaction_participants ip1 ON r.from_person_id = ip1.person_id
            LEFT JOIN interaction_participants ip2 ON r.to_person_id = ip2.person_id
            LEFT JOIN interactions i ON ip1.interaction_id = i.id AND ip2.interaction_id = i.id
            LEFT JOIN relationship_milestones rm ON r.id = rm.relationship_id
            LEFT JOIN mentor_milestones mm ON rm.milestone_id = mm.id
            WHERE r.id IN (SELECT relationship_id FROM %I)
            GROUP BY r.id, r.from_person_id, pm.first_name, pm.last_name, r.to_person_id, ps.first_name, ps.last_name, r.created_at',
            v_temp_table_name
          );
        END IF;
        
      ------------------------------------------------------
      -- brotherhood_visibility_mv refresh logic
      ------------------------------------------------------
      WHEN 'brotherhood_visibility_mv' THEN
        -- For brotherhood_visibility, a full refresh is more appropriate
        -- because changes in any cross_group_participation affects many rows
        IF p_full_refresh OR v_last_refresh IS NULL THEN
          -- Full refresh for brotherhood visibility
          TRUNCATE brotherhood_visibility_mv;
          
          INSERT INTO brotherhood_visibility_mv
          SELECT * FROM brotherhood_visibility;
          
          GET DIAGNOSTICS v_affected_count = ROW_COUNT;
        ELSE
          -- Check if there are changes to cross_group_participations
          SELECT COUNT(*) INTO v_affected_count
          FROM cross_group_participations
          WHERE created_at > v_threshold_date OR updated_at > v_threshold_date;
          
          -- If changes exist, do a full refresh anyway
          IF v_affected_count > 0 THEN
            TRUNCATE brotherhood_visibility_mv;
            
            INSERT INTO brotherhood_visibility_mv
            SELECT * FROM brotherhood_visibility;
            
            GET DIAGNOSTICS v_affected_count = ROW_COUNT;
          END IF;
        END IF;
        
      ------------------------------------------------------
      -- alumni_risk_assessment_mv refresh logic
      ------------------------------------------------------
      WHEN 'alumni_risk_assessment_mv' THEN
        -- Create temp table for affected alumni
        EXECUTE format('
          CREATE TEMP TABLE %I (alumni_id UUID PRIMARY KEY) ON COMMIT DROP', 
          v_temp_table_name
        );
        
        -- Fill temp table with alumni IDs
        IF p_full_refresh THEN
          -- For full refresh, include all alumni
          EXECUTE format('
            INSERT INTO %I (alumni_id)
            SELECT p.id
            FROM people p
            JOIN roles r ON p.role_id = r.id
            WHERE r.code = ''alumni''',
            v_temp_table_name
          );
        ELSE
          -- For incremental refresh, only include alumni with recent changes
          EXECUTE format('
            INSERT INTO %I (alumni_id)
            SELECT DISTINCT ac.alumni_id
            FROM alumni_checkins ac
            WHERE ac.created_at > $1 OR ac.updated_at > $1
            UNION
            SELECT p.id
            FROM people p
            JOIN roles r ON p.role_id = r.id
            WHERE r.code = ''alumni'' AND (p.created_at > $1 OR p.updated_at > $1)',
            v_temp_table_name
          ) USING v_threshold_date;
        END IF;
        
        -- Get count of affected alumni
        EXECUTE format('SELECT COUNT(*) FROM %I', v_temp_table_name) INTO v_affected_count;
        
        -- Remove affected alumni from materialized view
        IF v_affected_count > 0 THEN
          EXECUTE format('
            DELETE FROM alumni_risk_assessment_mv
            WHERE id IN (SELECT alumni_id FROM %I)',
            v_temp_table_name
          );
          
          -- Reinsert with fresh calculations - recreating the original view logic
          EXECUTE format('
            INSERT INTO alumni_risk_assessment_mv
            SELECT 
              p.id,
              p.first_name,
              p.last_name,
              COALESCE(p.email, '''') AS email,
              COALESCE(p.phone, '''') AS phone,
              MAX(ac.check_date) AS last_check_date,
              EXTRACT(DAYS FROM NOW() - MAX(ac.check_date))::INTEGER AS days_since_last_checkin,
              COUNT(DISTINCT ac.id) AS total_checkins,
              COUNT(DISTINCT ac.id) FILTER (WHERE ac.check_date > NOW() - INTERVAL ''1 year'') AS checkins_last_year,
              CASE
                WHEN MAX(ac.check_date) IS NULL OR MAX(ac.check_date) < NOW() - INTERVAL ''1 year'' THEN ''high''
                WHEN MAX(ac.check_date) < NOW() - INTERVAL ''6 months'' THEN ''medium''
                WHEN MAX(ac.support_needed) = TRUE THEN ''medium''
                ELSE ''low''
              END AS risk_level,
              BOOL_OR(ac.support_needed) AS ever_needed_support,
              NOW() AS assessed_at
            FROM people p
            JOIN roles r ON p.role_id = r.id
            LEFT JOIN alumni_checkins ac ON p.id = ac.alumni_id
            WHERE r.code = ''alumni'' AND p.id IN (SELECT alumni_id FROM %I)
            GROUP BY p.id, p.first_name, p.last_name, p.email, p.phone',
            v_temp_table_name
          );
        END IF;
        
      ELSE
        RAISE EXCEPTION 'Unknown materialized view: %', p_view_name;
    END CASE;
    
    -- Calculate execution time
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    -- Update tracking information
    UPDATE mv_refresh_tracking
    SET last_updated = NOW(),
        last_refresh_duration = v_end_time - v_start_time,
        rows_affected = v_affected_count,
        is_refreshing = FALSE
    WHERE view_name = p_view_name;
    
    -- Return info about the refresh
    RETURN QUERY SELECT p_view_name, v_affected_count, v_duration_ms;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Update tracking with error
      UPDATE mv_refresh_tracking
      SET is_refreshing = FALSE,
          refresh_error = SQLERRM
      WHERE view_name = p_view_name;
      
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_all_materialized_views(p_full_refresh BOOLEAN DEFAULT FALSE)
RETURNS TABLE(view_name TEXT, rows_affected INTEGER, duration_ms INTEGER) AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM refresh_mv_incremental('relationship_strength_analytics_mv', p_full_refresh);
  
  RETURN QUERY
  SELECT * FROM refresh_mv_incremental('mentor_relationship_health_mv', p_full_refresh);
  
  RETURN QUERY
  SELECT * FROM refresh_mv_incremental('brotherhood_visibility_mv', p_full_refresh);
  
  RETURN QUERY
  SELECT * FROM refresh_mv_incremental('alumni_risk_assessment_mv', p_full_refresh);
END;
$$ LANGUAGE plpgsql;

-- 5. Update the environment config to control refresh frequency
ALTER TABLE app_settings.env_settings
ADD COLUMN IF NOT EXISTS mv_refresh_frequency INTERVAL DEFAULT '1 day';

-- 6. Update the env_settings table with the refresh frequency
INSERT INTO app_settings.env_settings (key, value, description)
VALUES ('mv_refresh_frequency', '"1 day"', 'Frequency for materialized view refreshes')
ON CONFLICT (key) DO NOTHING;

-- 7. Update the pg_cron job to use incremental refresh
SELECT cron.unschedule('0 2 * * *');
SELECT cron.schedule('refresh_mvs_daily', '0 2 * * *', $$
  DO $$
  DECLARE
    v_env TEXT;
    v_refresh_frequency INTERVAL;
  BEGIN
    -- Get current environment
    SELECT current_setting('app.environment', TRUE) INTO v_env;
    
    -- Only run in production
    IF v_env = 'production' THEN
      -- Get configured refresh frequency
      SELECT COALESCE(
        (SELECT value::INTERVAL FROM app_settings.env_settings WHERE key = 'mv_refresh_frequency'),
        INTERVAL '1 day'
      ) INTO v_refresh_frequency;
      
      -- Perform incremental refresh of all materialized views
      PERFORM refresh_all_materialized_views(FALSE);
    END IF;
  END $$;
$$);

-- 8. Create a function to refresh a single view by name
CREATE OR REPLACE FUNCTION api_refresh_materialized_view(p_view_name TEXT, p_full_refresh BOOLEAN DEFAULT FALSE)
RETURNS JSONB AS $$
DECLARE
  v_refresh_result RECORD;
BEGIN
  SELECT * INTO v_refresh_result 
  FROM refresh_mv_incremental(p_view_name, p_full_refresh);
  
  RETURN jsonb_build_object(
    'success', TRUE,
    'view_name', v_refresh_result.view_name,
    'rows_affected', v_refresh_result.rows_affected,
    'duration_ms', v_refresh_result.duration_ms,
    'full_refresh', p_full_refresh
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'view_name', p_view_name,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create a function to get the status of all materialized views
CREATE OR REPLACE FUNCTION get_materialized_views_status()
RETURNS TABLE (
  view_name TEXT,
  last_updated TIMESTAMPTZ,
  refresh_frequency INTERVAL,
  last_refresh_duration INTERVAL,
  rows_affected INTEGER,
  is_refreshing BOOLEAN,
  refresh_error TEXT,
  row_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    mt.view_name,
    mt.last_updated,
    mt.refresh_frequency,
    mt.last_refresh_duration,
    mt.rows_affected,
    mt.is_refreshing,
    mt.refresh_error,
    (SELECT COUNT(*) FROM pg_catalog.pg_class c WHERE c.relname = mt.view_name)
  FROM mv_refresh_tracking mt
  ORDER BY mt.view_name;
END;
$$ LANGUAGE plpgsql;

-- 10. Grant permission to API functions
GRANT EXECUTE ON FUNCTION api_refresh_materialized_view TO authenticated;
GRANT EXECUTE ON FUNCTION get_materialized_views_status TO authenticated;

COMMENT ON TABLE mv_refresh_tracking IS 'Tracks materialized view refresh status and history';
COMMENT ON FUNCTION refresh_mv_incremental IS 'Core function for efficient incremental materialized view refresh';
COMMENT ON FUNCTION refresh_all_materialized_views IS 'Refreshes all materialized views with optional full refresh';
COMMENT ON FUNCTION api_refresh_materialized_view IS 'API function to trigger a materialized view refresh';
COMMENT ON FUNCTION get_materialized_views_status IS 'Returns status information about all materialized views';
