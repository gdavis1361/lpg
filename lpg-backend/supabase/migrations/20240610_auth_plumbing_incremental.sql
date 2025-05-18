-- migration_3_auth_plumbing_incremental.sql
-- Phase 3: Auth setup - JWT claims and role management (incremental version)
-- -----------------------------------------------------------------------------
-- This is a modified version that only applies new components
-- and skips existing triggers detected on auth.users

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

-- Note: Skipping creation of handle_new_user and handle_user_metadata_sync triggers
-- since they appear to already exist in the database.

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
DECLARE
  affected_auth_id UUID;
BEGIN
  -- Only process if permissions actually changed
  IF NEW.permissions IS DISTINCT FROM OLD.permissions THEN
    -- Loop through all users affected by this role's permission change
    -- and call update_user_claims for each.
    -- This ensures their entire claim set is rebuilt correctly.
    FOR affected_auth_id IN
      SELECT p.auth_id
      FROM public.people p
      JOIN public.people_roles pr ON pr.person_id = p.id
      WHERE pr.role_id = NEW.id AND p.auth_id IS NOT NULL
    LOOP
      PERFORM public.update_user_claims(affected_auth_id);
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on roles for permission changes
CREATE TRIGGER on_role_permission_change
AFTER UPDATE OF permissions ON public.roles
FOR EACH ROW EXECUTE FUNCTION public.handle_role_permission_changes();
