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
