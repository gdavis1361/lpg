-- Migration: 20250518_validation_helpers.sql
-- Description: Adds helper functions for migration validation

-- Create function to check for unmapped relationship types
CREATE OR REPLACE FUNCTION check_unmapped_relationship_types()
RETURNS TABLE (
  unmapped_count INTEGER,
  sample_types TEXT
) SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER,
    array_to_string(array_agg(DISTINCT r.relationship_type), ', ')
  FROM relationships r
  LEFT JOIN relationship_types rt ON rt.code = r.relationship_type
  WHERE r.relationship_type IS NOT NULL AND rt.id IS NULL;
END;
$$;

-- Create function to check for duplicate active relationships
CREATE OR REPLACE FUNCTION check_duplicate_active_relationships()
RETURNS TABLE (
  duplicate_group_count INTEGER
) SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::INTEGER
  FROM (
    SELECT 1
    FROM relationships
    WHERE status = 'active'
      AND end_date IS NULL
      AND relationship_type_id IS NOT NULL
    GROUP BY from_person_id, to_person_id, relationship_type_id
    HAVING COUNT(*) > 1
  ) AS duplicate_groups;
END;
$$;

-- Create a generic validation function that runs all checks
CREATE OR REPLACE FUNCTION validate_migration_safety()
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  unmapped_result RECORD;
  duplicate_result RECORD;
  result JSONB = '{}'::JSONB;
BEGIN
  -- Check for unmapped relationship types
  SELECT * INTO unmapped_result FROM check_unmapped_relationship_types();
  
  result = jsonb_set(result, '{unmapped_relationship_types}', jsonb_build_object(
    'count', unmapped_result.unmapped_count,
    'sample_types', unmapped_result.sample_types,
    'success', unmapped_result.unmapped_count = 0
  ));
  
  -- Check for duplicate active relationships
  SELECT * INTO duplicate_result FROM check_duplicate_active_relationships();
  
  result = jsonb_set(result, '{duplicate_active_relationships}', jsonb_build_object(
    'count', duplicate_result.duplicate_group_count,
    'success', duplicate_result.duplicate_group_count = 0
  ));
  
  -- Set overall success flag
  result = jsonb_set(result, '{success}', to_jsonb(
    unmapped_result.unmapped_count = 0 AND
    duplicate_result.duplicate_group_count = 0
  ));
  
  RETURN result;
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION check_unmapped_relationship_types() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_active_relationships() TO authenticated;
GRANT EXECUTE ON FUNCTION validate_migration_safety() TO authenticated;

-- Comment on functions
COMMENT ON FUNCTION check_unmapped_relationship_types IS 'Checks for relationship_type values that cannot be mapped to the relationship_types table';
COMMENT ON FUNCTION check_duplicate_active_relationships IS 'Checks for duplicate active relationships that would violate the unique index';
COMMENT ON FUNCTION validate_migration_safety IS 'Runs all migration safety checks and returns results as JSON';
