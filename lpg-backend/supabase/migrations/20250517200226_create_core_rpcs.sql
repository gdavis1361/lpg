-- 20250517200226_create_core_rpcs.sql
-- Migration to create core RPC functions for Chattanooga Prep Relationship Platform
-- -----------------------------------------------------------------------------
-- This migration adds the core RPC functions needed for Phase 1:
-- 1. create_person: Creates a new person with validation and optional role assignment
-- 2. log_interaction: Creates a new interaction with associated participants and tags

-- 1. create_person RPC ----------------------------------------------------------
CREATE OR REPLACE FUNCTION create_person(
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT DEFAULT NULL,
  auth_id UUID DEFAULT NULL,
  role_codes TEXT[] DEFAULT '{}'::TEXT[]
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_person_id UUID;
  role_id UUID;
  role_code TEXT;
BEGIN
  -- Input validation
  IF first_name IS NULL OR first_name = '' THEN
    RAISE EXCEPTION 'first_name cannot be empty';
  END IF;
  
  IF last_name IS NULL OR last_name = '' THEN
    RAISE EXCEPTION 'last_name cannot be empty';
  END IF;
  
  IF email IS NULL OR email = '' OR email !~ '^[^@]+@[^@]+\.[^@]+$' THEN
    RAISE EXCEPTION 'email must be valid';
  END IF;
  
  -- Check for duplicate email
  IF EXISTS (SELECT 1 FROM people WHERE email = create_person.email) THEN
    RAISE EXCEPTION 'A person with this email already exists';
  END IF;
  
  -- Insert new person
  INSERT INTO people (
    first_name, 
    last_name, 
    email, 
    phone,
    auth_id,
    created_at,
    updated_at
  ) 
  VALUES (
    first_name, 
    last_name, 
    email, 
    phone,
    auth_id,
    NOW(),
    NOW()
  )
  RETURNING id INTO new_person_id;
  
  -- Assign roles if provided
  IF array_length(role_codes, 1) > 0 THEN
    FOREACH role_code IN ARRAY role_codes
    LOOP
      -- Get role ID from code
      SELECT id INTO role_id FROM roles WHERE name = role_code;
      
      IF role_id IS NULL THEN
        RAISE WARNING 'Role % not found, skipping assignment', role_code;
        CONTINUE;
      END IF;
      
      -- Assign role to person
      INSERT INTO people_roles (person_id, role_id, assigned_at)
      VALUES (new_person_id, role_id, NOW());
    END LOOP;
  END IF;
  
  RETURN new_person_id;
EXCEPTION
  WHEN others THEN
    -- Log error details for debugging
    RAISE LOG 'Error in create_person: %', SQLERRM;
    -- Re-raise the exception
    RAISE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_person(TEXT, TEXT, TEXT, TEXT, UUID, TEXT[]) TO authenticated;

-- 2. log_interaction RPC --------------------------------------------------------
CREATE OR REPLACE FUNCTION log_interaction(
  interaction_type TEXT,
  title TEXT,
  description TEXT DEFAULT NULL,
  occurred_at TIMESTAMPTZ DEFAULT NULL,
  duration_minutes INT DEFAULT NULL,
  location TEXT DEFAULT NULL,
  participant_ids UUID[] DEFAULT '{}'::UUID[],
  tags TEXT[] DEFAULT '{}'::TEXT[],
  status TEXT DEFAULT 'completed' -- Added status parameter with default 'completed'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_interaction_id UUID;
  participant_id UUID;
  tag_id UUID;
  tag_name TEXT;
  created_by_id UUID;
BEGIN
  -- Input validation
  IF interaction_type IS NULL OR interaction_type = '' THEN
    RAISE EXCEPTION 'interaction_type cannot be empty';
  END IF;
  
  IF title IS NULL OR title = '' THEN
    RAISE EXCEPTION 'title cannot be empty';
  END IF;
  
  -- Validate status is one of the allowed values
  IF status NOT IN ('scheduled', 'completed', 'canceled', 'rescheduled') THEN
    RAISE EXCEPTION 'Invalid status. Must be one of: scheduled, completed, canceled, rescheduled';
  END IF;
  
  -- Default occurred_at to now if not provided
  IF occurred_at IS NULL THEN
    occurred_at := NOW();
  END IF;
  
  -- Get current user's person ID
  SELECT id INTO created_by_id FROM people WHERE auth_id = auth.uid();
  
  -- If no person record matches the auth ID, log warning but continue
  IF created_by_id IS NULL THEN
    RAISE WARNING 'No person record found for authenticated user (auth_id: %)', auth.uid();
  END IF;
  
  -- Insert interaction
  INSERT INTO interactions (
    interaction_type,
    title,
    description,
    occurred_at,
    duration_minutes,
    location,
    created_by,
    created_at,
    updated_at,
    status -- Added status field
  )
  VALUES (
    interaction_type,
    title,
    description,
    occurred_at,
    duration_minutes,
    location,
    created_by_id,
    NOW(),
    NOW(),
    status -- Use the provided status
  )
  RETURNING id INTO new_interaction_id;
  
  -- Associate participants
  IF array_length(participant_ids, 1) > 0 THEN
    FOREACH participant_id IN ARRAY participant_ids
    LOOP
      -- Validate participant exists
      IF NOT EXISTS (SELECT 1 FROM people WHERE id = participant_id) THEN
        RAISE WARNING 'Person with ID % not found, skipping participant', participant_id;
        CONTINUE;
      END IF;
      
      -- Add participant
      INSERT INTO interaction_participants (interaction_id, person_id, created_at)
      VALUES (new_interaction_id, participant_id, NOW());
    END LOOP;
  END IF;
  
  -- Add the creator as a participant if they're not already included
  IF created_by_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM interaction_participants 
    WHERE interaction_id = new_interaction_id AND person_id = created_by_id
  ) THEN
    INSERT INTO interaction_participants (interaction_id, person_id, role, created_at)
    VALUES (new_interaction_id, created_by_id, 'creator', NOW());
  END IF;
  
  -- Associate tags
  IF array_length(tags, 1) > 0 THEN
    FOREACH tag_name IN ARRAY tags
    LOOP
      -- Check if tag exists, create if not
      SELECT id INTO tag_id FROM tags WHERE name = tag_name;
      
      IF tag_id IS NULL THEN
        INSERT INTO tags (name, created_at) VALUES (tag_name, NOW()) RETURNING id INTO tag_id;
      END IF;
      
      -- Associate tag with interaction
      INSERT INTO interaction_tags (interaction_id, tag_id, created_at, created_by)
      VALUES (new_interaction_id, tag_id, NOW(), created_by_id);
    END LOOP;
  END IF;
  
  RETURN new_interaction_id;
EXCEPTION
  WHEN others THEN
    -- Log error details for debugging
    RAISE LOG 'Error in log_interaction: %', SQLERRM;
    -- Re-raise the exception
    RAISE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION log_interaction(TEXT, TEXT, TEXT, TIMESTAMPTZ, INT, TEXT, UUID[], TEXT[], TEXT) TO authenticated;
