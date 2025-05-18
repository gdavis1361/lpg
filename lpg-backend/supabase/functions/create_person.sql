-- create_person.sql
-- Creates a new person with validation and optional role assignment
-- To be loaded into Supabase as an RPC function

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
