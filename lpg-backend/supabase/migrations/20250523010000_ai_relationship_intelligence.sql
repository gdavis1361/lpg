-- Prerequisites:
--   - 20250519000000_enable_extensions.sql (for uuid-ossp, pg_cron)
--   - 20250519000200_add_status_to_relationships.sql (for relationships.status)
--   - Assumes 'relationships', 'people', 'interactions', 'interaction_participants' tables exist.
-- Purpose: Implements the "AI Relationship Intelligence System" by:
--          1. Creating 'relationship_patterns' table.
--          2. Creating 'relationship_pattern_detections' table.
--          3. Creating 'relationship_suggestions' table.
--          4. Creating/Replacing the 'generate_relationship_suggestions' function (fixed version).
--          5. Scheduling the suggestion generation function.
--          RLS policies for these tables will be in a later, consolidated file (20250526010000_apply_rls_policies.sql).

-- Create table for storing relationship patterns
CREATE TABLE IF NOT EXISTS public.relationship_patterns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pattern_type TEXT NOT NULL, -- e.g., 'communication_frequency', 'engagement_drop', 'cross_boundary'
  description TEXT,
  detection_threshold JSONB, -- Configurable thresholds for pattern detection
  alert_level TEXT NOT NULL DEFAULT 'info' CHECK (alert_level IN ('info', 'warning', 'critical')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.relationship_patterns IS 'Defines types of relationship patterns that can be detected by the AI system.';
COMMENT ON COLUMN public.relationship_patterns.pattern_type IS 'Unique identifier for the type of pattern (e.g., communication_frequency).';
COMMENT ON COLUMN public.relationship_patterns.detection_threshold IS 'JSONB object storing configurable thresholds for detecting this pattern.';
COMMENT ON COLUMN public.relationship_patterns.alert_level IS 'Severity level of the detected pattern (info, warning, critical).';

-- Create table for detected pattern instances
CREATE TABLE IF NOT EXISTS public.relationship_pattern_detections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pattern_id UUID NOT NULL REFERENCES public.relationship_patterns(id) ON DELETE CASCADE,
  relationship_id UUID REFERENCES public.relationships(id) ON DELETE SET NULL, -- Can be null if pattern applies to a person generally
  person_id UUID REFERENCES public.people(id) ON DELETE CASCADE, -- Person primarily associated with the detection
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  detection_data JSONB, -- Specific data related to this detection instance
  confidence_score FLOAT CHECK (confidence_score BETWEEN 0 AND 1), -- Confidence of the detection (0-1)
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'acknowledged', 'resolved', 'dismissed')),
  resolution_notes TEXT,
  resolved_by UUID REFERENCES public.people(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.relationship_pattern_detections IS 'Stores instances of detected relationship patterns.';
COMMENT ON COLUMN public.relationship_pattern_detections.relationship_id IS 'Optional reference to a specific relationship involved in the pattern.';
COMMENT ON COLUMN public.relationship_pattern_detections.person_id IS 'Reference to the person primarily associated with this detected pattern.';
COMMENT ON COLUMN public.relationship_pattern_detections.detection_data IS 'JSONB data specific to this instance of pattern detection.';
COMMENT ON COLUMN public.relationship_pattern_detections.confidence_score IS 'AI-assessed confidence in the accuracy of this detection (0.0 to 1.0).';
COMMENT ON COLUMN public.relationship_pattern_detections.status IS 'Lifecycle status of the detected pattern (new, acknowledged, resolved, dismissed).';

-- Create table for AI-suggested relationship actions
CREATE TABLE IF NOT EXISTS public.relationship_suggestions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  for_person_id UUID NOT NULL REFERENCES public.people(id) ON DELETE CASCADE, -- The person who should see/action this suggestion
  target_person_id UUID REFERENCES public.people(id) ON DELETE CASCADE, -- The person the suggestion is about (if applicable)
  suggestion_type TEXT NOT NULL, -- e.g., 'connect', 'follow_up', 'celebrate_milestone', 'offer_support'
  suggestion_text TEXT NOT NULL,
  urgency INTEGER DEFAULT 5 CHECK (urgency BETWEEN 1 AND 10), -- 1-10 scale
  detection_id UUID REFERENCES public.relationship_pattern_detections(id) ON DELETE SET NULL, -- Optional link to a pattern that triggered this
  expires_at TIMESTAMPTZ, -- When the suggestion is no longer relevant
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'completed', 'expired')),
  feedback TEXT, -- User feedback on the suggestion
  feedback_rating INTEGER CHECK (feedback_rating BETWEEN 1 AND 5), -- 1-5 rating on suggestion quality
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.relationship_suggestions IS 'Stores AI-generated suggestions for relationship actions.';
COMMENT ON COLUMN public.relationship_suggestions.for_person_id IS 'The person for whom this suggestion is intended.';
COMMENT ON COLUMN public.relationship_suggestions.target_person_id IS 'The person who is the target or subject of the suggestion, if applicable.';
COMMENT ON COLUMN public.relationship_suggestions.suggestion_type IS 'Categorizes the type of suggestion (e.g., connect, follow_up).';
COMMENT ON COLUMN public.relationship_suggestions.urgency IS 'Urgency of the suggestion on a 1-10 scale.';
COMMENT ON COLUMN public.relationship_suggestions.detection_id IS 'Optional link to a specific pattern detection that triggered this suggestion.';
COMMENT ON COLUMN public.relationship_suggestions.status IS 'Lifecycle status of the suggestion (pending, accepted, etc.).';

-- Fixed generate_relationship_suggestions function
CREATE OR REPLACE FUNCTION public.generate_relationship_suggestions()
RETURNS INTEGER AS $$
DECLARE
  suggestion_count INTEGER := 0;
  -- Cursors or record variables can be declared here if needed for more complex logic
BEGIN
  -- Use CTEs for clarity and to handle the MAX aggregation correctly
  WITH relationship_last_interaction AS (
    SELECT
      r.id AS relationship_id,
      r.from_person_id, -- Person who might initiate follow-up
      r.to_person_id,   -- Person to follow-up with
      p_to.first_name AS to_person_first_name, -- Name of the person to follow-up with
      MAX(i.occurred_at) AS last_interaction_at
    FROM public.relationships r
    JOIN public.people p_to ON r.to_person_id = p_to.id -- Join to get the name of the 'to_person'
    -- Join to interactions involving BOTH participants of the relationship
    LEFT JOIN public.interaction_participants ip_from ON r.from_person_id = ip_from.person_id
    LEFT JOIN public.interaction_participants ip_to_rel ON r.to_person_id = ip_to_rel.person_id
    LEFT JOIN public.interactions i ON ip_from.interaction_id = i.id AND ip_to_rel.interaction_id = i.id AND i.id = ip_from.interaction_id
    WHERE r.status = 'active' -- Only consider active relationships
    GROUP BY r.id, r.from_person_id, r.to_person_id, p_to.first_name
  ),
  inactive_relationships AS (
    SELECT
      rli.relationship_id,
      rli.from_person_id,
      rli.to_person_id,
      rli.to_person_first_name,
      rli.last_interaction_at,
      CASE
        WHEN rli.last_interaction_at IS NULL OR NOW() - rli.last_interaction_at > INTERVAL '6 months' THEN 8 -- Very inactive
        WHEN NOW() - rli.last_interaction_at > INTERVAL '3 months' THEN 5 -- Moderately inactive
        ELSE 3 -- Slightly inactive (though the WHERE clause below filters for > 3 months)
      END AS urgency
    FROM relationship_last_interaction rli
    WHERE rli.last_interaction_at IS NULL OR NOW() - rli.last_interaction_at > INTERVAL '3 months' -- Inactive for over 3 months
  )
  INSERT INTO public.relationship_suggestions (
    for_person_id,    -- Suggestion is for the 'from_person_id'
    target_person_id, -- Suggestion is about the 'to_person_id'
    suggestion_type,
    suggestion_text,
    urgency,
    expires_at,
    created_at,
    updated_at
  )
  SELECT
    ir.from_person_id,
    ir.to_person_id,
    'follow_up',
    'You haven''t connected with ' || ir.to_person_first_name || 
      (CASE WHEN ir.last_interaction_at IS NULL THEN '' ELSE ' since ' || TO_CHAR(ir.last_interaction_at, 'Month DD, YYYY') END) ||
      '. Consider scheduling a check-in.',
    ir.urgency,
    NOW() + INTERVAL '14 days', -- Suggestion expires in 14 days
    NOW(),
    NOW()
  FROM inactive_relationships ir
  -- Avoid duplicating existing pending suggestions for the same pair and type
  WHERE NOT EXISTS (
    SELECT 1 FROM public.relationship_suggestions rs
    WHERE rs.for_person_id = ir.from_person_id
      AND rs.target_person_id = ir.to_person_id
      AND rs.suggestion_type = 'follow_up'
      AND rs.status = 'pending'
  );
  
  GET DIAGNOSTICS suggestion_count = ROW_COUNT;
  
  RETURN suggestion_count;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION public.generate_relationship_suggestions() IS 'Generates relationship suggestions, e.g., for inactive relationships. Returns count of new suggestions.';

-- Schedule the suggestion generator to run daily at 1 AM server time.
-- The function itself should be environment-aware if needed, or the cron job can be conditional.
SELECT cron.schedule(
  'generate_suggestions_daily', -- name of the cron job
  '0 1 * * *',                  -- cron schedule: daily at 1:00 AM
  $$
  SELECT public.generate_relationship_suggestions();
  $$
);
COMMENT ON FUNCTION cron.schedule(TEXT, TEXT, TEXT) IS 'Schedules the daily generation of AI relationship suggestions.';

-- Note: RLS policies for relationship_patterns, relationship_pattern_detections, and relationship_suggestions
-- will be added in the consolidated RLS migration file: 20250526010000_apply_rls_policies.sql.
