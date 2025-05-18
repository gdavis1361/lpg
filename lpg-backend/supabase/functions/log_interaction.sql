-- log_interaction.sql
-- Creates a new interaction with associated participants and tags
-- To be loaded into Supabase as an RPC function

CREATE OR REPLACE FUNCTION log_interaction(
  interaction_type TEXT,
  title TEXT,
  description TEXT DEFAULT NULL,
  occurred_at TIMESTAMPTZ DEFAULT NULL,
  duration_minutes INT DEFAULT NULL,
  location TEXT DEFAULT NULL,
  participant_ids UUID[] DEFAULT '{}'::UUID[],
  tags TEXT[] DEFAULT '{}'::TEXT[]
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
    updated_at
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
    NOW()
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
