-- migration_3_auth_plumbing.sql
-- Phase 3: Auth setup - signup/sync triggers and custom JWT claims
-- -----------------------------------------------------------------------------
-- Applies on top of previous migrations and adds authentication integration
-- Note: This migration assumes no anonymous read access is required.
--       If public data exposure is needed later, policies will need modification.

-- ***************************
-- UP MIGRATION --------------
-- ***************************

-- 1. Helper functions --------------------------------------------------------

-- Helper to get the student role ID (used for default role assignment)
CREATE OR REPLACE FUNCTION get_student_role_id() 
RETURNS UUID AS $$
DECLARE
  student_role_id UUID;
BEGIN
  SELECT id INTO student_role_id FROM public.roles WHERE name = 'student';
  
  -- If student role doesn't exist, create it
  IF student_role_id IS NULL THEN
    INSERT INTO public.roles (name, description, permissions)
    VALUES ('student', 'Student role with basic access permissions', '{"student_features": true}'::jsonb)
    RETURNING id INTO student_role_id;
  END IF;
  
  RETURN student_role_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper to update JWT claims for a specific user
CREATE OR REPLACE FUNCTION public.update_user_claims(user_auth_id UUID)
RETURNS VOID AS $$
DECLARE
  person_id UUID;
  role_ids JSONB;
  user_permissions JSONB;
BEGIN
  -- Get the person_id for this auth_id
  SELECT id INTO person_id FROM public.people WHERE auth_id = user_auth_id;
  
  IF person_id IS NULL THEN
    -- No associated person record yet
    RETURN;
  END IF;
  
  -- Get the user's roles and aggregate permissions
  SELECT 
    jsonb_agg(pr.role_id),
    jsonb_build_object(
      'admin', bool_or((r.permissions->>'all')::boolean),
      'is_student', bool_or(r.name = 'student'),
      'is_mentor', bool_or(r.name = 'mentor'),
      'is_donor', bool_or(r.name = 'donor'),
      'is_alumni', bool_or(r.name = 'alumni'),
      'is_staff', bool_or(r.name = 'staff')
    ) INTO role_ids, user_permissions
  FROM public.people_roles pr
  JOIN public.roles r ON pr.role_id = r.id
  WHERE pr.person_id = person_id
  GROUP BY pr.person_id;
  
  -- Default to empty array if no roles
  IF role_ids IS NULL THEN
    role_ids := '[]'::jsonb;
  END IF;
  
  -- Default to empty object with false flags if no permissions
  IF user_permissions IS NULL THEN
    user_permissions := jsonb_build_object(
      'admin', false,
      'is_student', false,
      'is_mentor', false,
      'is_donor', false,
      'is_alumni', false,
      'is_staff', false
    );
  END IF;
  
  -- Update the user's metadata in auth.users
  UPDATE auth.users 
  SET raw_app_meta_data = 
    COALESCE(raw_app_meta_data, '{}'::jsonb) || 
    jsonb_build_object(
      'role_ids', role_ids,
      'permissions', user_permissions
    )
  WHERE id = user_auth_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Signup & Metadata Sync Triggers -----------------------------------------

-- Create a trigger to create a person record when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  student_role_id UUID;
  new_person_id UUID;
BEGIN
  -- Get student role ID
  student_role_id := get_student_role_id();
  
  -- Create a new person record for this user
  INSERT INTO public.people (
    auth_id, 
    first_name, 
    last_name, 
    email, 
    avatar_url
  ) VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'first_name', split_part(NEW.email, '@', 1)), 
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''), 
    NEW.email, 
    NEW.raw_user_meta_data->>'avatar_url'
  )
  RETURNING id INTO new_person_id;
  
  -- Assign the default student role to the new user
  INSERT INTO public.people_roles (person_id, role_id, primary_role)
  VALUES (new_person_id, student_role_id, true);
  
  -- Update the user's JWT claims
  PERFORM public.update_user_claims(NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on auth.users for new signups
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create a trigger to keep people data in sync with auth.users updates
CREATE OR REPLACE FUNCTION public.handle_user_metadata_sync()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update if values actually changed (prevents trigger loops)
  IF NEW.email IS DISTINCT FROM OLD.email OR 
     NEW.raw_user_meta_data IS DISTINCT FROM OLD.raw_user_meta_data THEN
    UPDATE public.people
    SET 
      email = NEW.email,
      avatar_url = COALESCE(NEW.raw_user_meta_data->>'avatar_url', avatar_url)
    WHERE auth_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on auth.users for metadata updates
CREATE TRIGGER on_auth_user_updated
AFTER UPDATE OF email, raw_user_meta_data ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_user_metadata_sync();

-- 3. Role Management & JWT Claims --------------------------------------------

-- Trigger to update user JWT claims when people_roles change
CREATE OR REPLACE FUNCTION public.handle_role_changes()
RETURNS TRIGGER AS $$
DECLARE
  person_id UUID;
  auth_user_id UUID;
BEGIN
  -- For INSERT or UPDATE, use NEW; for DELETE, use OLD
  IF TG_OP = 'DELETE' THEN
    person_id := OLD.person_id;
  ELSE 
    person_id := NEW.person_id;
  END IF;
  
  -- Get the auth.users ID for this person
  SELECT auth_id INTO auth_user_id FROM public.people WHERE id = person_id;
  
  -- Update the JWT claims for this user
  IF auth_user_id IS NOT NULL THEN
    PERFORM public.update_user_claims(auth_user_id);
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for role changes
CREATE TRIGGER on_people_role_change
AFTER INSERT OR UPDATE OR DELETE ON public.people_roles
FOR EACH ROW EXECUTE FUNCTION public.handle_role_changes();

-- Trigger for when role permissions change
CREATE OR REPLACE FUNCTION public.handle_role_permission_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if permissions actually changed
  IF NEW.permissions IS DISTINCT FROM OLD.permissions THEN
    -- Set-based update for all affected users
    UPDATE auth.users u
    SET raw_app_meta_data = 
      COALESCE(u.raw_app_meta_data, '{}'::jsonb) || 
      (
        WITH user_permissions AS (
          SELECT 
            p.auth_id,
            jsonb_agg(pr.role_id) as role_ids,
            jsonb_build_object(
              'admin', bool_or((r.permissions->>'all')::boolean),
              'is_student', bool_or(r.name = 'student'),
              'is_mentor', bool_or(r.name = 'mentor'),
              'is_donor', bool_or(r.name = 'donor'),
              'is_alumni', bool_or(r.name = 'alumni'),
              'is_staff', bool_or(r.name = 'staff')
            ) as permissions
          FROM public.people_roles pr
          JOIN public.roles r ON pr.role_id = r.id
          JOIN public.people p ON pr.person_id = p.id
          WHERE pr.role_id = NEW.id
          AND p.auth_id IS NOT NULL
          GROUP BY p.auth_id
        )
        SELECT 
          jsonb_build_object(
            'role_ids', COALESCE(up.role_ids, '[]'::jsonb),
            'permissions', COALESCE(up.permissions, '{}'::jsonb)
          )
        FROM user_permissions up
        WHERE up.auth_id = u.id
      )
    FROM public.people p
    JOIN public.people_roles pr ON pr.person_id = p.id
    WHERE pr.role_id = NEW.id AND p.auth_id = u.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on roles for permission changes
CREATE TRIGGER on_role_permission_change
AFTER UPDATE OF permissions ON public.roles
FOR EACH ROW EXECUTE FUNCTION public.handle_role_permission_changes();

-- ***************************
-- DOWN MIGRATION ------------
-- ***************************

-- To rollback this migration, run the following SQL:
/*
DROP TRIGGER IF EXISTS on_role_permission_change ON public.roles;
DROP FUNCTION IF EXISTS public.handle_role_permission_changes();

DROP TRIGGER IF EXISTS on_people_role_change ON public.people_roles;
DROP FUNCTION IF EXISTS public.handle_role_changes();

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
DROP FUNCTION IF EXISTS public.handle_user_metadata_sync();

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

DROP FUNCTION IF EXISTS public.update_user_claims(UUID);
DROP FUNCTION IF EXISTS get_student_role_id();
*/

-- -----------------------------------------------------------------------------
-- End migration_3_auth_plumbing.sql
