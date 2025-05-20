-- Migration: 20250602000000_ai_functions_transaction_control.sql
-- Purpose: Enhances AI relationship functions with proper transaction control and performance optimizations

-- 1. Update relationship_suggestions schema with additional tracking fields
ALTER TABLE public.relationship_suggestions 
ADD COLUMN IF NOT EXISTS processed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS processing_result TEXT,
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS duplicate_of UUID REFERENCES relationship_suggestions(id);

-- 2. Create index for suggestion deduplication checks
CREATE INDEX IF NOT EXISTS idx_relationship_suggestions_for_target_pending ON relationship_suggestions
(for_person_id, target_person_id, suggestion_type)
WHERE status = 'pending';

-- 3. Reimplement generate_relationship_suggestions with proper transaction control
CREATE OR REPLACE FUNCTION generate_relationship_suggestions()
RETURNS INTEGER AS $$
DECLARE
  suggestion_count INTEGER := 0;
  error_message TEXT;
BEGIN
  -- Explicit transaction control
  BEGIN
    -- Stage potential suggestions in a temporary table for better performance
    CREATE TEMP TABLE potential_suggestions (
      from_person_id UUID,
      to_person_id UUID,
      first_name TEXT,
      urgency INTEGER,
      suggestion_type TEXT,
      suggestion_text TEXT,
      priority INTEGER,
      expires_at TIMESTAMPTZ
    ) ON COMMIT DROP;
    
    -- Find inactive relationships (haven't interacted in over 3 months)
    WITH relationship_last_interaction AS (
      SELECT
        r.id AS relationship_id,
        r.from_person_id,
        r.to_person_id,
        p.first_name,
        p.last_name,
        rt.name AS relationship_type,
        MAX(i.start_time) AS last_interaction
      FROM relationships r
      JOIN people p ON r.to_person_id = p.id
      JOIN relationship_types rt ON r.relationship_type_id = rt.id
      LEFT JOIN interaction_participants ip1 ON r.from_person_id = ip1.person_id
      LEFT JOIN interaction_participants ip2 ON r.to_person_id = ip2.person_id
      LEFT JOIN interactions i ON ip1.interaction_id = i.id AND ip2.interaction_id = i.id
      WHERE r.status = 'active'
      GROUP BY r.id, r.from_person_id, r.to_person_id, p.first_name, p.last_name, rt.name
    ),
    inactive_relationships AS (
      SELECT
        relationship_id,
        from_person_id,
        to_person_id,
        first_name,
        last_name,
        relationship_type,
        CASE
          WHEN last_interaction IS NULL OR NOW() - last_interaction > INTERVAL '1 year' THEN 10
          WHEN NOW() - last_interaction > INTERVAL '6 months' THEN 8
          WHEN NOW() - last_interaction > INTERVAL '3 months' THEN 5
          ELSE 3
        END AS urgency,
        CASE
          WHEN relationship_type = 'Mentor' THEN 10  -- Prioritize mentor relationships
          WHEN relationship_type = 'Teacher' THEN 8
          WHEN relationship_type = 'Advisor' THEN 7
          ELSE 5
        END AS priority
      FROM relationship_last_interaction
      WHERE last_interaction IS NULL OR NOW() - last_interaction > INTERVAL '3 months'
    )
    -- Insert inactive relationship follow-up suggestions
    INSERT INTO potential_suggestions (
      from_person_id,
      to_person_id,
      first_name,
      urgency,
      suggestion_type,
      suggestion_text,
      priority,
      expires_at
    )
    SELECT
      ir.from_person_id,
      ir.to_person_id,
      ir.first_name,
      ir.urgency,
      'follow_up',
      'You haven''t connected with ' || ir.first_name || ' ' || ir.last_name || ' in over ' || 
        CASE 
          WHEN ir.urgency >= 8 THEN '6 months' 
          ELSE '3 months' 
        END || '. Consider scheduling a check-in.',
      ir.priority,
      NOW() + INTERVAL '14 days'
    FROM inactive_relationships ir;
    
    -- Find missed milestones for mentor relationships
    INSERT INTO potential_suggestions (
      from_person_id,
      to_person_id,
      first_name,
      urgency,
      suggestion_type,
      suggestion_text,
      priority,
      expires_at
    )
    SELECT
      r.from_person_id,
      r.to_person_id,
      p.first_name,
      8 AS urgency,
      'milestone',
      'Your mentee ' || p.first_name || ' ' || p.last_name || ' is missing the "' || mm.name || '" milestone for year ' || mm.typical_year || '.',
      9 AS priority,
      NOW() + INTERVAL '30 days'
    FROM relationships r
    JOIN relationship_types rt ON r.relationship_type_id = rt.id
    JOIN people p ON r.to_person_id = p.id
    JOIN mentor_milestones mm ON mm.is_required = TRUE
    LEFT JOIN relationship_milestones rm ON r.id = rm.relationship_id AND mm.id = rm.milestone_id
    WHERE rt.code = 'mentor'
      AND r.status = 'active'
      AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.created_at)) >= mm.typical_year
      AND rm.id IS NULL;
    
    -- Find alumni who haven't checked in recently
    INSERT INTO potential_suggestions (
      from_person_id,
      to_person_id,
      first_name,
      urgency,
      suggestion_type,
      suggestion_text,
      priority,
      expires_at
    )
    SELECT
      acr.admin_id AS from_person_id,
      p.id AS to_person_id,
      p.first_name,
      7 AS urgency,
      'alumni_checkin',
      'Alumni ' || p.first_name || ' ' || p.last_name || ' hasn''t checked in for ' || 
        EXTRACT(DAY FROM NOW() - COALESCE(MAX(ac.check_date), p.graduation_date)) || ' days.',
      7 AS priority,
      NOW() + INTERVAL '14 days'
    FROM people p
    LEFT JOIN alumni_checkins ac ON p.id = ac.alumni_id
    -- Assume there's a table tracking which admin is responsible for which alumni
    JOIN alumni_coordinator_responsibility acr ON p.id = acr.alumni_id 
    JOIN roles r ON p.role_id = r.id
    WHERE r.code = 'alumni'
      AND (
        MAX(ac.check_date) IS NULL OR 
        NOW() - MAX(ac.check_date) > INTERVAL '6 months'
      )
    GROUP BY p.id, p.first_name, p.last_name, p.graduation_date, acr.admin_id;
    
    -- More efficient deduplication with LEFT JOIN instead of NOT EXISTS
    INSERT INTO relationship_suggestions (
      for_person_id,
      target_person_id,
      suggestion_type,
      suggestion_text,
      urgency,
      priority,
      expires_at
    )
    SELECT
      ps.from_person_id,
      ps.to_person_id,
      ps.suggestion_type,
      ps.suggestion_text,
      ps.urgency,
      ps.priority,
      ps.expires_at
    FROM potential_suggestions ps
    LEFT JOIN relationship_suggestions rs ON 
      rs.for_person_id = ps.from_person_id AND
      rs.target_person_id = ps.to_person_id AND
      rs.suggestion_type = ps.suggestion_type AND
      rs.status = 'pending'
    WHERE rs.id IS NULL;
    
    GET DIAGNOSTICS suggestion_count = ROW_COUNT;
    
    -- Commit the entire operation
    COMMIT;
    
    RETURN suggestion_count;
  EXCEPTION
    WHEN OTHERS THEN
      -- Get error message for logging
      GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
      
      -- Rollback to avoid partial transactions
      ROLLBACK;
      
      -- Log error to a dedicated error log table if it exists
      BEGIN
        INSERT INTO error_logs (
          function_name, 
          error_message, 
          occurred_at
        ) VALUES (
          'generate_relationship_suggestions',
          error_message,
          NOW()
        );
      EXCEPTION WHEN OTHERS THEN
        -- Silently fail if error logging fails
        NULL;
      END;
      
      -- Re-raise the exception
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a function to batch process relationship suggestions
CREATE OR REPLACE FUNCTION process_relationship_suggestions(batch_size INTEGER DEFAULT 100)
RETURNS TABLE (suggestions_processed INTEGER, suggestions_accepted INTEGER) AS $$
DECLARE
  processed_count INTEGER := 0;
  accepted_count INTEGER := 0;
  r RECORD;
BEGIN
  -- Use explicit transactions for batching
  BEGIN
    -- Get batch of oldest unprocessed suggestions
    FOR r IN (
      SELECT id, for_person_id, target_person_id, suggestion_type, suggestion_text, urgency, priority
      FROM relationship_suggestions
      WHERE processed_at IS NULL
      ORDER BY priority DESC, urgency DESC, created_at ASC
      LIMIT batch_size
    )
    LOOP
      -- Process each suggestion (example: check for duplicates, relevance, etc.)
      BEGIN
        -- Mark as processed
        UPDATE relationship_suggestions
        SET processed_at = NOW(),
            processing_result = 'auto_accept', -- Example result
            status = 'accepted'                -- Auto-accept high priority suggestions
        WHERE id = r.id;
        
        processed_count := processed_count + 1;
        accepted_count := accepted_count + 1;
      EXCEPTION
        WHEN OTHERS THEN
          -- Log processing error but continue with next suggestion
          UPDATE relationship_suggestions
          SET processed_at = NOW(),
              processing_result = 'error: ' || SQLERRM
          WHERE id = r.id;
          
          processed_count := processed_count + 1;
      END;
    END LOOP;
    
    COMMIT;
    
    RETURN QUERY SELECT processed_count, accepted_count;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- 5. Create a function to get personalized suggestions for a user
CREATE OR REPLACE FUNCTION get_personalized_suggestions(
  p_person_id UUID DEFAULT NULL, 
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  suggestion_type TEXT,
  suggestion_text TEXT,
  urgency INTEGER,
  target_person_id UUID,
  target_person_name TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
) AS $$
DECLARE
  v_person_id UUID;
BEGIN
  -- Get current user's person_id if none provided
  IF p_person_id IS NULL THEN
    v_person_id := get_current_user_person_id();
  ELSE
    v_person_id := p_person_id;
  END IF;
  
  -- Check that user has permission to view these suggestions
  IF v_person_id IS NULL OR (
    p_person_id IS NOT NULL AND 
    p_person_id != get_current_user_person_id() AND
    NOT (has_permission('admin') OR has_permission('staff'))
  ) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  -- Return personalized suggestions
  RETURN QUERY
  SELECT 
    rs.id,
    rs.suggestion_type,
    rs.suggestion_text,
    rs.urgency,
    rs.target_person_id,
    p.first_name || ' ' || p.last_name AS target_person_name,
    rs.expires_at,
    rs.created_at
  FROM relationship_suggestions rs
  JOIN people p ON rs.target_person_id = p.id
  WHERE rs.for_person_id = v_person_id
    AND rs.status = 'pending'
    AND rs.expires_at > NOW()
  ORDER BY rs.priority DESC, rs.urgency DESC, rs.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create a function to update suggestion status (accept/reject)
CREATE OR REPLACE FUNCTION update_suggestion_status(
  p_suggestion_id UUID,
  p_status TEXT,
  p_feedback TEXT DEFAULT NULL,
  p_feedback_rating INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_person_id UUID;
  v_for_person_id UUID;
BEGIN
  -- Get current user's person_id
  v_person_id := get_current_user_person_id();
  
  -- Check that suggestion exists and is for this user
  SELECT for_person_id INTO v_for_person_id
  FROM relationship_suggestions
  WHERE id = p_suggestion_id;
  
  -- Permission check
  IF v_for_person_id IS NULL OR (
    v_for_person_id != v_person_id AND
    NOT (has_permission('admin') OR has_permission('staff'))
  ) THEN
    RETURN FALSE;
  END IF;
  
  -- Validate status value
  IF p_status NOT IN ('accepted', 'rejected', 'completed') THEN
    RETURN FALSE;
  END IF;
  
  -- Update the suggestion
  UPDATE relationship_suggestions
  SET status = p_status,
      feedback = p_feedback,
      feedback_rating = p_feedback_rating,
      updated_at = NOW()
  WHERE id = p_suggestion_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Schedule suggestion generation to run nightly
SELECT cron.schedule('generate_suggestions_nightly', '0 1 * * *', $$
  DO $$
  DECLARE
    v_env TEXT;
    v_suggestions_added INTEGER;
  BEGIN
    -- Only run in production
    SELECT current_setting('app.environment', TRUE) INTO v_env;
    
    IF v_env = 'production' THEN
      SELECT generate_relationship_suggestions() INTO v_suggestions_added;
      
      -- Log the result to a system table
      INSERT INTO app_settings.system_logs (
        log_type, 
        log_message,
        details
      ) VALUES (
        'suggestion_generation',
        'Generated ' || v_suggestions_added || ' new relationship suggestions',
        jsonb_build_object('suggestions_added', v_suggestions_added, 'run_at', now())
      );
    END IF;
  END $$;
$$);

-- 8. Create AI pattern detection function for detecting communication patterns
CREATE OR REPLACE FUNCTION detect_relationship_patterns()
RETURNS INTEGER AS $$
DECLARE
  patterns_detected INTEGER := 0;
  error_message TEXT;
BEGIN
  -- Explicit transaction control
  BEGIN
    -- Detect engagement drop pattern
    WITH recent_interactions AS (
      SELECT 
        r.id AS relationship_id,
        r.from_person_id,
        r.to_person_id,
        COUNT(i.id) FILTER (WHERE i.start_time > NOW() - INTERVAL '6 months') AS recent_count,
        COUNT(i.id) FILTER (WHERE i.start_time > NOW() - INTERVAL '12 months' 
                            AND i.start_time <= NOW() - INTERVAL '6 months') AS previous_count
      FROM relationships r
      JOIN relationship_types rt ON r.relationship_type_id = rt.id
      LEFT JOIN interaction_participants ip1 ON r.from_person_id = ip1.person_id
      LEFT JOIN interaction_participants ip2 ON r.to_person_id = ip2.person_id
      LEFT JOIN interactions i ON ip1.interaction_id = i.id AND ip2.interaction_id = i.id
      WHERE r.status = 'active'
        AND rt.code IN ('mentor', 'teacher', 'advisor')
      GROUP BY r.id, r.from_person_id, r.to_person_id
    ),
    engagement_drops AS (
      SELECT
        relationship_id,
        from_person_id,
        to_person_id,
        recent_count,
        previous_count,
        CASE
          WHEN previous_count > 0 AND recent_count = 0 THEN 'critical' -- Complete drop
          WHEN previous_count >= 4 AND recent_count <= previous_count * 0.5 THEN 'warning' -- 50% or more decrease
          WHEN previous_count >= 2 AND recent_count <= previous_count * 0.7 THEN 'info' -- 30% or more decrease
          ELSE NULL -- No significant drop
        END AS alert_level,
        CASE
          WHEN previous_count > 0 AND recent_count = 0 THEN 1.0 -- Complete drop, 100% confidence
          WHEN previous_count >= 4 AND recent_count <= previous_count * 0.5 THEN 0.8 -- Significant drop
          WHEN previous_count >= 2 AND recent_count <= previous_count * 0.7 THEN 0.6 -- Moderate drop
          ELSE 0.0 -- No significant drop
        END AS confidence_score
      FROM recent_interactions
      WHERE 
        (previous_count > 0 AND recent_count = 0) OR
        (previous_count >= 4 AND recent_count <= previous_count * 0.5) OR
        (previous_count >= 2 AND recent_count <= previous_count * 0.7)
    )
    INSERT INTO relationship_pattern_detections (
      pattern_id,
      relationship_id,
      person_id,
      detected_at,
      detection_data,
      confidence_score,
      status
    )
    SELECT
      (SELECT id FROM relationship_patterns WHERE pattern_type = 'engagement_drop'),
      ed.relationship_id,
      ed.from_person_id, -- Detect for the mentor/teacher side
      NOW(),
      jsonb_build_object(
        'recent_count', ed.recent_count,
        'previous_count', ed.previous_count,
        'decrease_percentage', 
          CASE WHEN ed.previous_count > 0 
               THEN ROUND((1 - (ed.recent_count::FLOAT / ed.previous_count)) * 100)
               ELSE 0 
          END
      ),
      ed.confidence_score,
      'new'
    FROM engagement_drops ed
    -- Avoid duplicate detections for the same relationship within 30 days
    WHERE NOT EXISTS (
      SELECT 1 FROM relationship_pattern_detections rpd
      WHERE rpd.relationship_id = ed.relationship_id
        AND rpd.pattern_id = (SELECT id FROM relationship_patterns WHERE pattern_type = 'engagement_drop')
        AND rpd.detected_at > NOW() - INTERVAL '30 days'
    );
    
    GET DIAGNOSTICS patterns_detected = ROW_COUNT;
    
    -- More pattern detection logic could be added here
    
    -- Commit all changes
    COMMIT;
    
    RETURN patterns_detected;
  EXCEPTION
    WHEN OTHERS THEN
      -- Get error message
      GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
      
      -- Rollback to avoid partial state
      ROLLBACK;
      
      -- Log error
      BEGIN
        INSERT INTO error_logs (
          function_name, 
          error_message, 
          occurred_at
        ) VALUES (
          'detect_relationship_patterns',
          error_message,
          NOW()
        );
      EXCEPTION WHEN OTHERS THEN
        NULL; -- Silently fail if error logging fails
      END;
      
      -- Re-raise the exception
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- 9. Schedule pattern detection to run weekly
SELECT cron.schedule('detect_patterns_weekly', '0 3 * * 0', $$
  DO $$
  DECLARE
    v_env TEXT;
    v_patterns_detected INTEGER;
  BEGIN
    -- Only run in production
    SELECT current_setting('app.environment', TRUE) INTO v_env;
    
    IF v_env = 'production' THEN
      SELECT detect_relationship_patterns() INTO v_patterns_detected;
      
      -- Log the result
      INSERT INTO app_settings.system_logs (
        log_type, 
        log_message,
        details
      ) VALUES (
        'pattern_detection',
        'Detected ' || v_patterns_detected || ' relationship patterns',
        jsonb_build_object('patterns_detected', v_patterns_detected, 'run_at', now())
      );
    END IF;
  END $$;
$$);

-- 10. Grant permissions for API functions
GRANT EXECUTE ON FUNCTION get_personalized_suggestions TO authenticated;
GRANT EXECUTE ON FUNCTION update_suggestion_status TO authenticated;

COMMENT ON FUNCTION generate_relationship_suggestions IS 'Analyzes relationships and generates suggestions for follow-ups with proper transaction control';
COMMENT ON FUNCTION process_relationship_suggestions IS 'Batch processes relationship suggestions with error handling';
COMMENT ON FUNCTION get_personalized_suggestions IS 'API function to get personalized relationship suggestions for a user';
COMMENT ON FUNCTION update_suggestion_status IS 'API function to update the status of a relationship suggestion';
COMMENT ON FUNCTION detect_relationship_patterns IS 'Analyzes interaction data to detect relationship patterns that need attention';
