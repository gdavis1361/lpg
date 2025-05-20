-- Prerequisites: Assumes 'relationships' table exists (e.g., from 20240603_relationship_framework.sql)
-- Purpose: Adds a 'status' column to the 'relationships' table.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' -- Assuming 'public' schema, adjust if different
      AND table_name = 'relationships' 
      AND column_name = 'status'
  ) THEN
    ALTER TABLE public.relationships ADD COLUMN status TEXT NOT NULL DEFAULT 'active';
    
    ALTER TABLE public.relationships 
      ADD CONSTRAINT check_relationship_status 
      CHECK (status IN ('active', 'inactive', 'potential', 'archived')); -- Added 'archived' as a common status
      
    COMMENT ON COLUMN public.relationships.status IS 'The current status of the relationship (e.g., active, inactive, potential, archived).';
    COMMENT ON CONSTRAINT check_relationship_status ON public.relationships IS 'Ensures the relationship status is one of the predefined values.';
  ELSE
    -- If the column exists, ensure the CHECK constraint includes all desired values
    -- This part is more complex as modifying CHECK constraints can be tricky.
    -- For simplicity, this example assumes if 'status' exists, the constraint is either correct or will be handled manually if issues arise.
    -- A more robust solution might involve dropping and re-adding the constraint with all desired values.
    RAISE NOTICE 'Column "status" already exists in "relationships". Ensure CHECK constraint includes all desired values (active, inactive, potential, archived).';
  END IF;
END $$;
