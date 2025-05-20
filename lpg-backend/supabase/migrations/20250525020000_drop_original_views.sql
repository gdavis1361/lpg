-- Prerequisites:
--   - 20250525010000_create_materialized_views.sql (ensures MVs have been created)
-- Purpose: Drops the original standard views now that their corresponding materialized views are in place and populated.

DROP VIEW IF EXISTS public.relationship_strength_analytics;
COMMENT ON VIEW public.relationship_strength_analytics IS E'@deprecated: Dropped. Use relationship_strength_analytics_mv instead.';

DROP VIEW IF EXISTS public.brotherhood_visibility;
COMMENT ON VIEW public.brotherhood_visibility IS E'@deprecated: Dropped. Use brotherhood_visibility_mv instead.';

DROP VIEW IF EXISTS public.mentor_relationship_health;
COMMENT ON VIEW public.mentor_relationship_health IS E'@deprecated: Dropped. Use mentor_relationship_health_mv instead.';
