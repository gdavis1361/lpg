-- Test seed data for branch environment workflow
-- This file adds a sample record to test the workflow
-- Updated on May 18, 2025 to trigger CI with new Doppler integration

-- Insert a test record (will only run if the table exists)
DO $$
BEGIN
  -- Only insert if the relationship_types table exists
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'relationship_types') THEN
    -- Check if test record already exists
    IF NOT EXISTS (SELECT 1 FROM relationship_types WHERE code = 'test_workflow') THEN
      INSERT INTO relationship_types (code, name, description, created_at)
      VALUES ('test_workflow', 'Test Workflow', 'This is a test entry to verify branch environment workflow', NOW());
      
      RAISE NOTICE 'Added test record to relationship_types table';
    ELSE
      RAISE NOTICE 'Test record already exists in relationship_types table';
    END IF;
  ELSE
    RAISE NOTICE 'relationship_types table does not exist, skipping test record insertion';
  END IF;
END;
$$;
