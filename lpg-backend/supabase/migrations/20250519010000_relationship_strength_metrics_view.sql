-- Prerequisites: 
--   - Assumes 'interactions', 'relationships', 'interaction_participants' tables exist.
--   - 20250519000200_add_status_to_relationships.sql (for relationships.status)
-- Purpose: Implements the initial "Relationship Strength Measurement System" by:
--          1. Altering 'interactions' table to add quality and reciprocity scores.
--          2. Creating 'relationship_strength_analytics' as a standard VIEW.

-- Add strength scoring to interactions table if columns don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'interactions' AND column_name = 'quality_score'
  ) THEN
    ALTER TABLE public.interactions 
      ADD COLUMN quality_score INTEGER CHECK (quality_score BETWEEN 1 AND 10) DEFAULT 5;
    COMMENT ON COLUMN public.interactions.quality_score IS 'Subjective quality score of the interaction (1-10).';
  ELSE
    RAISE NOTICE 'Column "quality_score" already exists in "interactions".';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'interactions' AND column_name = 'reciprocity_score'
  ) THEN
    ALTER TABLE public.interactions 
      ADD COLUMN reciprocity_score INTEGER CHECK (reciprocity_score BETWEEN 1 AND 10) DEFAULT 5;
    COMMENT ON COLUMN public.interactions.reciprocity_score IS 'Subjective reciprocity score of the interaction (1-10).';
  ELSE
    RAISE NOTICE 'Column "reciprocity_score" already exists in "interactions".';
  END IF;
END $$;

-- Create a view for relationship strength analytics
-- This view will be replaced by a materialized view in a later migration (20250525010000_create_materialized_views.sql)
CREATE OR REPLACE VIEW public.relationship_strength_analytics AS
SELECT 
  r.id as relationship_id,
  r.from_person_id,
  r.to_person_id,
  rt.name as relationship_type, -- Assuming relationship_type_id links to a relationship_types table
  COUNT(i.id) as interaction_count,
  COALESCE(AVG(i.quality_score), 5) as avg_quality, -- Default to 5 if no interactions or scores
  COALESCE(AVG(i.reciprocity_score), 5) as avg_reciprocity, -- Default to 5
  MAX(i.occurred_at) as last_interaction_at,
  CASE 
    WHEN MAX(i.occurred_at) IS NOT NULL THEN NOW() - MAX(i.occurred_at)
    ELSE NULL 
  END as time_since_last_interaction,
  -- Calculate an overall strength score based on frequency, recency, quality
  (
    COALESCE(
      CASE 
        WHEN MAX(i.occurred_at) IS NULL THEN 1 -- No interactions yet, low recency score
        WHEN NOW() - MAX(i.occurred_at) < INTERVAL '7 days' THEN 10
        WHEN NOW() - MAX(i.occurred_at) < INTERVAL '30 days' THEN 7
        WHEN NOW() - MAX(i.occurred_at) < INTERVAL '90 days' THEN 4
        ELSE 1
      END, 1) + -- Recency Score (default to 1 if no interactions)
    COALESCE(
      CASE 
        WHEN COUNT(i.id) = 0 THEN 1 -- No interactions, low frequency score
        WHEN COUNT(i.id) > 20 THEN 10
        WHEN COUNT(i.id) > 10 THEN 7
        WHEN COUNT(i.id) > 5 THEN 4
        ELSE 1
      END, 1) + -- Frequency Score (default to 1 if no interactions)
    COALESCE(AVG(i.quality_score), 5) -- Quality Score (default to 5)
  )/3.0 as strength_score -- Use 3.0 for floating point division
FROM public.relationships r
LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id -- Assumes relationship_types table and FK
LEFT JOIN public.interaction_participants ip_from ON r.from_person_id = ip_from.person_id
LEFT JOIN public.interaction_participants ip_to ON r.to_person_id = ip_to.person_id
-- Ensure the interaction is between the two specific people in the relationship
LEFT JOIN public.interactions i ON ip_from.interaction_id = i.id AND ip_to.interaction_id = i.id AND i.id = ip_from.interaction_id -- The interaction must involve both
WHERE r.status = 'active' -- Consider only active relationships for strength analytics
GROUP BY r.id, r.from_person_id, r.to_person_id, rt.name;

COMMENT ON VIEW public.relationship_strength_analytics IS 'Provides analytics on relationship strength based on interactions. This is a standard view, to be replaced by a materialized view.';
COMMENT ON COLUMN public.relationship_strength_analytics.relationship_id IS 'ID of the relationship.';
COMMENT ON COLUMN public.relationship_strength_analytics.from_person_id IS 'ID of the person initiating or from whom the relationship is viewed.';
COMMENT ON COLUMN public.relationship_strength_analytics.to_person_id IS 'ID of the person to whom the relationship is directed.';
COMMENT ON COLUMN public.relationship_strength_analytics.relationship_type IS 'Type of the relationship (e.g., mentor, friend).';
COMMENT ON COLUMN public.relationship_strength_analytics.interaction_count IS 'Total number of interactions between the two people in this relationship.';
COMMENT ON COLUMN public.relationship_strength_analytics.avg_quality IS 'Average quality score of interactions (1-10). Defaults to 5 if no scores.';
COMMENT ON COLUMN public.relationship_strength_analytics.avg_reciprocity IS 'Average reciprocity score of interactions (1-10). Defaults to 5 if no scores.';
COMMENT ON COLUMN public.relationship_strength_analytics.last_interaction_at IS 'Timestamp of the most recent interaction.';
COMMENT ON COLUMN public.relationship_strength_analytics.time_since_last_interaction IS 'Duration since the last interaction.';
COMMENT ON COLUMN public.relationship_strength_analytics.strength_score IS 'Calculated overall strength score for the relationship (composite of recency, frequency, quality).';
