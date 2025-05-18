-- Migration: Test Supabase Branch Environment Workflow
-- Description: This is a simple migration to test the branch environment workflow
-- Date: 2025-05-18

-- Create a simple test function
CREATE OR REPLACE FUNCTION test_branch_workflow()
RETURNS TEXT
LANGUAGE sql
AS $$
  SELECT 'Branch environment workflow is working correctly!';
$$;

-- Add comment
COMMENT ON FUNCTION test_branch_workflow IS 'Test function to verify branch environment workflow';
