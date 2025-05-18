-- 20250517213359_relationship_strength.sql
-- Migration for Phase 2: Relationship Intelligence (Consolidated)
-- -----------------------------------------------------------------------------
-- This migration adds:
-- 1. calculate_relationship_strength: Calculates a strength score for a relationship.
-- 2. Trigger on interaction_participants to update relationship strength.
-- 3. aggregate_timeline: Aggregates interactions and key relationship lifecycle events.
-- 4. Supporting indexes for performance.

BEGIN; -- Start transaction

-- 1. calculate_relationship_strength FUNCTION ----------------------------------
CREATE OR REPLACE FUNCTION public.calculate_relationship_strength(p_relationship_id UUID)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_score INTEGER := 0;
  v_interaction_count_last_30_days INTEGER := 0;
  v_interaction_count_31_to_90_days INTEGER := 0;
  v_interaction_count_91_to_180_days INTEGER := 0;
  v_total_interactions_last_180_days INTEGER := 0;
  v_from_person_id UUID;
  v_to_person_id UUID;
BEGIN
  SELECT from_person_id, to_person_id
  INTO v_from_person_id, v_to_person_id
  FROM public.relationships
  WHERE id = p_relationship_id;

  IF v_from_person_id IS NULL OR v_to_person_id IS NULL THEN
    RETURN 0;
  END IF;

  WITH relevant_interactions AS (
    SELECT i.id, i.occurred_at
    FROM public.interactions i
    JOIN public.interaction_participants ip1 ON i.id = ip1.interaction_id
    JOIN public.interaction_participants ip2 ON i.id = ip2.interaction_id
    WHERE ip1.person_id = v_from_person_id
      AND ip2.person_id = v_to_person_id
      AND i.status = 'completed'
      AND i.occurred_at IS NOT NULL
    GROUP BY i.id, i.occurred_at
  )
  SELECT
    COUNT(CASE WHEN occurred_at >= NOW() - INTERVAL '30 days' THEN 1 END),
    COUNT(CASE WHEN occurred_at >= NOW() - INTERVAL '90 days' AND occurred_at < NOW() - INTERVAL '30 days' THEN 1 END),
    COUNT(CASE WHEN occurred_at >= NOW() - INTERVAL '180 days' AND occurred_at < NOW() - INTERVAL '90 days' THEN 1 END),
    COUNT(CASE WHEN occurred_at >= NOW() - INTERVAL '180 days' THEN 1 END)
  INTO
    v_interaction_count_last_30_days,
    v_interaction_count_31_to_90_days,
    v_interaction_count_91_to_180_days,
    v_total_interactions_last_180_days
  FROM relevant_interactions;

  IF v_interaction_count_last_30_days > 0 THEN
    v_score := v_score + 30;
  ELSIF v_interaction_count_31_to_90_days > 0 THEN
    v_score := v_score + 15;
  ELSIF v_interaction_count_91_to_180_days > 0 THEN
    v_score := v_score + 5;
  END IF;

  v_score := v_score + LEAST(v_total_interactions_last_180_days * 5, 50);
  
  RETURN GREATEST(0, LEAST(v_score, 100));
EXCEPTION
  WHEN others THEN
    RAISE LOG 'Error in calculate_relationship_strength for relationship_id %: %', p_relationship_id, SQLERRM;
    RETURN 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.calculate_relationship_strength(UUID) TO authenticated;

-- 2. TRIGGER FUNCTION & TRIGGER for relationship strength update ---------------
CREATE OR REPLACE FUNCTION public.handle_interaction_change_for_strength_update()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_interaction_id UUID;
  v_participant_ids UUID[];
  v_person1_id UUID;
  v_person2_id UUID;
  v_relationship_record RECORD;
  i INTEGER;
  j INTEGER;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_interaction_id := OLD.interaction_id;
  ELSE -- INSERT or UPDATE
    v_interaction_id := NEW.interaction_id;
  END IF;

  IF v_interaction_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT array_agg(DISTINCT person_id)
  INTO v_participant_ids
  FROM public.interaction_participants
  WHERE interaction_id = v_interaction_id;

  IF v_participant_ids IS NULL OR array_length(v_participant_ids, 1) < 2 THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  FOR i IN 1 .. array_length(v_participant_ids, 1) LOOP
    v_person1_id := v_participant_ids[i];
    FOR j IN (i + 1) .. array_length(v_participant_ids, 1) LOOP
      v_person2_id := v_participant_ids[j];

      FOR v_relationship_record IN
          SELECT id FROM public.relationships
          WHERE (from_person_id = v_person1_id AND to_person_id = v_person2_id)
             OR (from_person_id = v_person2_id AND to_person_id = v_person1_id)
      LOOP
          UPDATE public.relationships
          SET strength_score = public.calculate_relationship_strength(v_relationship_record.id)
          WHERE id = v_relationship_record.id;
      END LOOP;
    END LOOP;
  END LOOP;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trigger_update_relationship_strength_on_interaction_participant_change
AFTER INSERT OR UPDATE OR DELETE ON public.interaction_participants
FOR EACH ROW
EXECUTE FUNCTION public.handle_interaction_change_for_strength_update();

-- 3. aggregate_timeline FUNCTION -----------------------------------------------
CREATE OR REPLACE FUNCTION public.aggregate_timeline(
  p_relationship_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS SETOF JSONB LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_from_person_id UUID;
  v_to_person_id UUID;
  v_relationship_created_at TIMESTAMPTZ;
  v_relationship_start_date DATE;
  v_relationship_end_date DATE;
  v_relationship_type_code TEXT;
BEGIN
  SELECT r.from_person_id, r.to_person_id, r.created_at, r.start_date, r.end_date, rt.code
  INTO v_from_person_id, v_to_person_id, v_relationship_created_at, v_relationship_start_date, v_relationship_end_date, v_relationship_type_code
  FROM public.relationships r
  LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id
  WHERE r.id = p_relationship_id;

  IF v_from_person_id IS NULL OR v_to_person_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH interaction_events AS (
    SELECT
      i.id AS event_id,
      'interaction' AS event_type,
      i.occurred_at AS event_timestamp,
      jsonb_build_object(
        'title', i.title,
        'description', i.description,
        'interaction_type', i.interaction_type,
        'duration_minutes', i.duration_minutes,
        'location', i.location,
        'status', i.status,
        'created_by_person_id', i.created_by,
        'participant_ids', (SELECT array_agg(ip.person_id) FROM public.interaction_participants ip WHERE ip.interaction_id = i.id)
      ) AS event_data
    FROM public.interactions i
    WHERE i.status = 'completed' AND i.occurred_at IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.interaction_participants ipa
        WHERE ipa.interaction_id = i.id AND ipa.person_id = v_from_person_id
      )
      AND EXISTS (
        SELECT 1 FROM public.interaction_participants ipb
        WHERE ipb.interaction_id = i.id AND ipb.person_id = v_to_person_id
      )
  ),
  relationship_lifecycle_events AS (
    SELECT
      p_relationship_id AS event_id,
      'relationship_started' AS event_type,
      COALESCE(v_relationship_start_date::TIMESTAMPTZ, v_relationship_created_at) AS event_timestamp,
      jsonb_build_object(
          'status', 'started',
          'type_code', v_relationship_type_code
      ) AS event_data
    UNION ALL
    SELECT
      p_relationship_id AS event_id,
      'relationship_ended' AS event_type,
      v_relationship_end_date::TIMESTAMPTZ AS event_timestamp,
      jsonb_build_object(
          'status', 'ended',
          'type_code', v_relationship_type_code
      ) AS event_data
    WHERE v_relationship_end_date IS NOT NULL
  ),
  all_events AS (
    SELECT event_id, event_type, event_timestamp, event_data FROM interaction_events
    UNION ALL
    SELECT event_id, event_type, event_timestamp, event_data FROM relationship_lifecycle_events WHERE event_timestamp IS NOT NULL
  )
  SELECT jsonb_build_object('id', event_id, 'type', event_type, 'timestamp', event_timestamp, 'data', event_data)
  FROM all_events
  ORDER BY event_timestamp DESC NULLS LAST, event_type
  LIMIT p_limit
  OFFSET p_offset;

EXCEPTION
  WHEN others THEN
    RAISE LOG 'Error in aggregate_timeline for relationship_id %: %', p_relationship_id, SQLERRM;
    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION public.aggregate_timeline(UUID, INT, INT) TO authenticated;

-- 4. Supporting Indexes for Performance Optimization ---------------------
-- Covering index for participant look-ups (person → interaction)
CREATE INDEX IF NOT EXISTS idx_interaction_participants_person_interaction
    ON public.interaction_participants (person_id, interaction_id);

-- Recency filter index for "completed" interactions
CREATE INDEX IF NOT EXISTS idx_interactions_status_occurred_at
    ON public.interactions (status, occurred_at DESC NULLS LAST)
    WHERE status = 'completed';

COMMIT; -- End transaction
