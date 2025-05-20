-- Migration: 20250603000000_enhanced_indexes.sql
-- Purpose: Adds optimized indexes to improve query performance across the platform

-- 1. Create composite index for interaction participants
-- This optimizes common query patterns joining interactions with participants
CREATE INDEX IF NOT EXISTS idx_interaction_participants_person_interaction
ON interaction_participants(person_id, interaction_id)
INCLUDE (created_at);

-- 2. Create partial index for active mentor relationships
-- First, get the mentor relationship type ID
DO $$
DECLARE
  mentor_type_id UUID;
BEGIN
  SELECT id INTO mentor_type_id FROM relationship_types WHERE code = 'mentor';
  
  -- Create the partial index with the literal UUID
  IF mentor_type_id IS NOT NULL THEN
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS idx_relationships_active_mentor
       ON relationships(from_person_id, to_person_id) 
       WHERE status = ''active'' AND relationship_type_id = %L',
      mentor_type_id
    );
  END IF;
END $$;

-- 3. Create composite index for relationship milestones
CREATE INDEX IF NOT EXISTS idx_relationship_milestones_composite
ON relationship_milestones(relationship_id, milestone_id)
INCLUDE (achieved_date, created_at);

-- 4. Create index for timeline event lookups by person and date range
CREATE INDEX IF NOT EXISTS idx_timeline_events_person_date_range
ON timeline_events(person_id, event_date)
WHERE NOT is_deleted;

-- 5. Create index for timeline event lookups by relationship
CREATE INDEX IF NOT EXISTS idx_timeline_events_relationship_date
ON timeline_events(relationship_id, event_date)
WHERE relationship_id IS NOT NULL AND NOT is_deleted;

-- 6. Create optimized index for relationship lookup by person
CREATE INDEX IF NOT EXISTS idx_relationships_from_to_composite
ON relationships(from_person_id, to_person_id, status)
INCLUDE (relationship_type_id, created_at);

CREATE INDEX IF NOT EXISTS idx_relationships_to_from_composite
ON relationships(to_person_id, from_person_id, status)
INCLUDE (relationship_type_id, created_at);

-- 7. Create index for filtering interactions by date range
CREATE INDEX IF NOT EXISTS idx_interactions_date_range
ON interactions(start_time)
INCLUDE (end_time, interaction_type);

-- 8. Create index for filtering recent alumni check-ins
CREATE INDEX IF NOT EXISTS idx_alumni_checkins_alumni_date
ON alumni_checkins(alumni_id, check_date DESC);

-- 9. Create index to optimize cross-group participation queries
CREATE INDEX IF NOT EXISTS idx_cross_group_participations_person_date
ON cross_group_participations(person_id, event_date)
INCLUDE (home_activity_id, visited_activity_id);

CREATE INDEX IF NOT EXISTS idx_cross_group_participations_activity_date
ON cross_group_participations(visited_activity_id, event_date)
INCLUDE (person_id, home_activity_id);

-- 10. Create index for relationship suggestions
CREATE INDEX IF NOT EXISTS idx_relationship_suggestions_person_status
ON relationship_suggestions(for_person_id, status)
WHERE status = 'pending'
INCLUDE (created_at, urgency, expires_at);

-- 11. Create index for authorization lookups
CREATE INDEX IF NOT EXISTS idx_people_auth_id_role_id
ON people(auth_id)
WHERE auth_id IS NOT NULL
INCLUDE (role_id);

-- 12. Create index for searching people by name
CREATE INDEX IF NOT EXISTS idx_people_name_search
ON people USING gin (
  (first_name || ' ' || last_name) gin_trgm_ops
);

-- 13. Create index for materialized view refresh lookups
CREATE INDEX IF NOT EXISTS idx_relationships_modified_dates
ON relationships(updated_at)
INCLUDE (created_at);

CREATE INDEX IF NOT EXISTS idx_interactions_modified_dates
ON interactions(updated_at)
INCLUDE (created_at);

CREATE INDEX IF NOT EXISTS idx_relationship_milestones_modified_dates
ON relationship_milestones(updated_at)
INCLUDE (created_at);

-- 14. Create index for users by role to optimize role-based queries
CREATE INDEX IF NOT EXISTS idx_people_by_role
ON people(role_id)
INCLUDE (first_name, last_name);

-- 15. Create index for mentor milestone lookups
CREATE INDEX IF NOT EXISTS idx_mentor_milestones_required_year
ON mentor_milestones(is_required, typical_year)
WHERE is_required = TRUE;

-- 16. Create index for pattern detection lookups
CREATE INDEX IF NOT EXISTS idx_relationship_pattern_detections_pattern
ON relationship_pattern_detections(pattern_id, status)
INCLUDE (relationship_id, person_id);

-- 17. Create indexes for relationship strength analytics materialized view
-- These are particularly important since the materialized view is referenced frequently
CREATE INDEX IF NOT EXISTS idx_relationship_strength_analytics_mv_scores
ON relationship_strength_analytics_mv(strength_score DESC, quality_score DESC, recency_score DESC);

CREATE INDEX IF NOT EXISTS idx_relationship_strength_analytics_mv_people
ON relationship_strength_analytics_mv(from_person_id, to_person_id);

-- 18. Create index for mentor relationship health materialized view
CREATE INDEX IF NOT EXISTS idx_mentor_relationship_health_mv_status
ON mentor_relationship_health_mv(health_status);

CREATE INDEX IF NOT EXISTS idx_mentor_relationship_health_mv_recent
ON mentor_relationship_health_mv(recent_interactions DESC);

-- 19. Analyze tables to update statistics for query planner
ANALYZE people;
ANALYZE relationships;
ANALYZE interactions;
ANALYZE interaction_participants;
ANALYZE relationship_milestones;
ANALYZE mentor_milestones;
ANALYZE timeline_events;
ANALYZE relationship_strength_analytics_mv;
ANALYZE mentor_relationship_health_mv;
ANALYZE alumni_checkins;
ANALYZE cross_group_participations;
ANALYZE relationship_suggestions;
ANALYZE relationship_pattern_detections;

-- 20. Add helpful comments to explain index usage
COMMENT ON INDEX idx_interaction_participants_person_interaction IS 'Optimizes queries that join interactions with participants by person';
COMMENT ON INDEX idx_relationships_active_mentor IS 'Partial index for active mentor relationships to optimize RLS policies';
COMMENT ON INDEX idx_relationship_milestones_composite IS 'Optimizes milestone achievement lookups by relationship';
COMMENT ON INDEX idx_timeline_events_person_date_range IS 'Optimizes timeline queries filtered by person and date range';
COMMENT ON INDEX idx_relationships_from_to_composite IS 'Optimizes relationship lookups from person perspective';
COMMENT ON INDEX idx_interactions_date_range IS 'Optimizes queries that filter interactions by date range';
COMMENT ON INDEX idx_alumni_checkins_alumni_date IS 'Optimizes queries for recent alumni check-ins';
COMMENT ON INDEX idx_cross_group_participations_person_date IS 'Optimizes cross-group participation queries by person';
COMMENT ON INDEX idx_relationship_suggestions_person_status IS 'Partial index for pending relationship suggestions by person';
COMMENT ON INDEX idx_people_auth_id_role_id IS 'Optimizes auth_id lookups with role inclusion for permission checks';
COMMENT ON INDEX idx_people_name_search IS 'Optimizes full-text search on people names';
COMMENT ON INDEX idx_relationships_modified_dates IS 'Supports incremental materialized view refresh algorithms';
COMMENT ON INDEX idx_mentor_milestones_required_year IS 'Partial index for required milestones by year to optimize health status calculations';
COMMENT ON INDEX idx_relationship_strength_analytics_mv_scores IS 'Optimizes queries that sort or filter by relationship strength scores';

-- Query Performance Monitoring Infrastructure

-- Create performance logging table
CREATE TABLE query_performance_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  query_identifier TEXT NOT NULL,
  execution_time_ms INTEGER NOT NULL,
  rows_processed INTEGER,
  execution_plan TEXT,
  query_parameters JSONB,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on performance logs
CREATE INDEX idx_query_performance_logs_identifier ON query_performance_logs(query_identifier, logged_at);
CREATE INDEX idx_query_performance_logs_time ON query_performance_logs(execution_time_ms DESC, logged_at DESC);

-- Create performance monitoring function
CREATE OR REPLACE FUNCTION log_query_performance(
  p_query_identifier TEXT,
  p_execution_time_ms INTEGER,
  p_rows_processed INTEGER DEFAULT NULL,
  p_execution_plan TEXT DEFAULT NULL,
  p_query_parameters JSONB DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  -- Log performance data
  INSERT INTO query_performance_logs (
    query_identifier,
    execution_time_ms,
    rows_processed,
    execution_plan,
    query_parameters
  ) VALUES (
    p_query_identifier,
    p_execution_time_ms,
    p_rows_processed,
    p_execution_plan,
    p_query_parameters
  );
  
  -- If this is a slow query, log it more visibly
  IF p_execution_time_ms > 1000 THEN -- More than 1 second
    INSERT INTO app_settings.system_logs (
      log_type,
      log_message,
      details
    ) VALUES (
      'slow_query',
      'Slow query detected: ' || p_query_identifier || ' (' || p_execution_time_ms || 'ms)',
      jsonb_build_object(
        'query_identifier', p_query_identifier,
        'execution_time_ms', p_execution_time_ms,
        'rows_processed', p_rows_processed,
        'logged_at', now(),
        'query_parameters', p_query_parameters
      )
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create a wrapper function to easily measure query performance
CREATE OR REPLACE FUNCTION measure_query_performance(
  p_query_identifier TEXT,
  p_query TEXT,
  p_params JSONB DEFAULT NULL,
  p_explain BOOLEAN DEFAULT FALSE
) RETURNS TABLE (execution_time_ms INTEGER, rows_affected INTEGER) AS $$
DECLARE
  v_start_time TIMESTAMPTZ;
  v_execution_time_ms INTEGER;
  v_rows_affected INTEGER;
  v_execution_plan TEXT;
  v_result REFCURSOR;
BEGIN
  -- Record start time
  v_start_time := clock_timestamp();
  
  -- Get execution plan if requested
  IF p_explain THEN
    EXECUTE 'EXPLAIN (FORMAT JSON) ' || p_query INTO v_execution_plan;
  END IF;
  
  -- Execute the query and count rows
  OPEN v_result FOR EXECUTE p_query;
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
  CLOSE v_result;
  
  -- Calculate execution time
  v_execution_time_ms := extract(epoch from clock_timestamp() - v_start_time) * 1000;
  
  -- Log performance data
  PERFORM log_query_performance(
    p_query_identifier,
    v_execution_time_ms,
    v_rows_affected,
    v_execution_plan,
    p_params
  );
  
  RETURN QUERY SELECT v_execution_time_ms, v_rows_affected;
END;
$$ LANGUAGE plpgsql;

-- Create performance analysis view
CREATE OR REPLACE VIEW query_performance_analysis AS
SELECT
  query_identifier,
  COUNT(*) AS execution_count,
  AVG(execution_time_ms) AS avg_execution_time_ms,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms) AS median_execution_time_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) AS p95_execution_time_ms,
  MAX(execution_time_ms) AS max_execution_time_ms,
  MIN(execution_time_ms) AS min_execution_time_ms,
  AVG(rows_processed) AS avg_rows_processed,
  MAX(logged_at) AS last_execution,
  MIN(logged_at) AS first_execution
FROM query_performance_logs
WHERE logged_at > NOW() - INTERVAL '7 days'
GROUP BY query_identifier
ORDER BY avg_execution_time_ms DESC;

-- Create a function to purge old performance logs
CREATE OR REPLACE FUNCTION purge_old_performance_logs(p_days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM query_performance_logs
  WHERE logged_at < NOW() - (p_days_to_keep || ' days')::INTERVAL;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Schedule automatic purging of old logs
SELECT cron.schedule(
  'purge_old_performance_logs',
  '0 1 * * 0', -- 1:00 AM every Sunday
  'SELECT purge_old_performance_logs();'
);

-- Grant permissions for monitoring functions
GRANT SELECT ON query_performance_analysis TO authenticated;
GRANT EXECUTE ON FUNCTION measure_query_performance TO authenticated;

COMMENT ON TABLE query_performance_logs IS 'Stores query performance metrics for monitoring and optimization';
COMMENT ON FUNCTION log_query_performance IS 'Internal function to log query performance data';
COMMENT ON FUNCTION measure_query_performance IS 'Wrapper function to measure and log query performance';
COMMENT ON VIEW query_performance_analysis IS 'Analysis of query performance metrics for identifying bottlenecks';
COMMENT ON FUNCTION purge_old_performance_logs IS 'Maintenance function to remove old performance logs';
