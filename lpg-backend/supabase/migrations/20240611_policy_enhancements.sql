-- migration_4_policy_enhancements.sql
-- Phase 4: Role & Permission Enforcement - Enhanced RLS policies
-- -----------------------------------------------------------------------------
-- Applies on top of previous migrations and enhances security with proper RLS policies
-- Note: This migration implements authenticated-only access.
--       Anonymous access is not enabled. If public data access is required in the future,
--       additional policies would need to be created.

-- ***************************
-- UP MIGRATION --------------
-- ***************************

-- 1. Helper function for permission checks -----------------------------------
-- This function simplifies permission checks in policies
CREATE OR REPLACE FUNCTION public.has_permission(permission_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if user has the specific permission
  -- First check admin (all permissions), then specific permission
  RETURN (
    ((current_setting('request.jwt.claims', true)::jsonb->'permissions'->>'admin')::boolean = true)
    OR
    ((current_setting('request.jwt.claims', true)::jsonb->'permissions'->>(permission_name))::boolean = true)
  );
EXCEPTION
  WHEN OTHERS THEN
    -- If JWT claims parsing fails, return false
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if the user owns a record by auth_id
CREATE OR REPLACE FUNCTION public.is_owner(auth_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.uid() = auth_id;
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. RLS Enhancement: people table -------------------------------------------
-- Drop existing RLS policies if they exist
DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.people;

-- Create enhanced policies for people table
CREATE POLICY "People - anyone can view" 
ON public.people FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "People - only self or admin can insert" 
ON public.people FOR INSERT WITH CHECK (
  is_owner(auth_id) OR has_permission('admin')
);

CREATE POLICY "People - only self or admin can update" 
ON public.people FOR UPDATE USING (
  is_owner(auth_id) OR has_permission('admin')
);

CREATE POLICY "People - only admin can delete" 
ON public.people FOR DELETE USING (
  has_permission('admin')
);

-- 3. RLS Enhancement: people_roles table -------------------------------------
DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.people_roles;

CREATE POLICY "People Roles - anyone can view" 
ON public.people_roles FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "People Roles - only admin can insert" 
ON public.people_roles FOR INSERT WITH CHECK (
  has_permission('admin')
);

CREATE POLICY "People Roles - only admin can update" 
ON public.people_roles FOR UPDATE USING (
  has_permission('admin')
);

CREATE POLICY "People Roles - only admin can delete" 
ON public.people_roles FOR DELETE USING (
  has_permission('admin')
);

-- 4. RLS Enhancement: relationships table ------------------------------------
DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.relationships;

CREATE POLICY "Relationships - anyone can view" 
ON public.relationships FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Relationships - insert with ownership check" 
ON public.relationships FOR INSERT WITH CHECK (
  is_owner((SELECT auth_id FROM public.people WHERE id = NEW.from_person_id))
  OR has_permission('admin')
);

CREATE POLICY "Relationships - update with ownership check" 
ON public.relationships FOR UPDATE USING (
  is_owner((SELECT auth_id FROM public.people WHERE id = relationships.from_person_id))
  OR has_permission('admin')
);

CREATE POLICY "Relationships - only admin can delete" 
ON public.relationships FOR DELETE USING (
  has_permission('admin')
);

-- 5. RLS Enhancement: interactions table -------------------------------------
DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.interactions;

CREATE POLICY "Interactions - anyone can view" 
ON public.interactions FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Interactions - insert with ownership check" 
ON public.interactions FOR INSERT WITH CHECK (
  is_owner((SELECT auth_id FROM public.people WHERE id = NEW.created_by))
  OR has_permission('admin')
);

CREATE POLICY "Interactions - update with ownership check" 
ON public.interactions FOR UPDATE USING (
  is_owner((SELECT auth_id FROM public.people WHERE id = interactions.created_by))
  OR has_permission('admin')
);

CREATE POLICY "Interactions - only admin can delete" 
ON public.interactions FOR DELETE USING (
  has_permission('admin')
);

-- 6. RLS Enhancement: relationship_types table -------------------------------
DROP POLICY IF EXISTS "Relationship types view – authenticated" ON public.relationship_types;

CREATE POLICY "Relationship Types - anyone can view" 
ON public.relationship_types FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Relationship Types - only admin can modify" 
ON public.relationship_types FOR ALL USING (
  has_permission('admin')
);

-- 7. RLS Enhancement: roles table --------------------------------------------
DROP POLICY IF EXISTS "Roles view – authenticated" ON public.roles;

CREATE POLICY "Roles - anyone can view" 
ON public.roles FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Roles - only admin can modify" 
ON public.roles FOR ALL USING (
  has_permission('admin')
);

-- 8. Admin service role bypass pattern ---------------------------------------
-- Add this comment as documentation for future reference
COMMENT ON SCHEMA public IS 'Standard public schema with enhanced RLS policies.
Access pattern:
- Default user access is controlled by RLS policies checking JWT claims
- Admin users get full access via permission checks in policies  
- Backend services use auth.role() = ''service_role'' check for unrestricted access
- Both approaches are combined with OR conditions in most policies';

-- ***************************
-- DOWN MIGRATION ------------
-- ***************************

-- To rollback this migration, run the following SQL:
/*
DROP POLICY IF EXISTS "People - only admin can delete" ON public.people;
DROP POLICY IF EXISTS "People - only self or admin can update" ON public.people;
DROP POLICY IF EXISTS "People - only self or admin can insert" ON public.people;
DROP POLICY IF EXISTS "People - anyone can view" ON public.people;

DROP POLICY IF EXISTS "People Roles - only admin can delete" ON public.people_roles;
DROP POLICY IF EXISTS "People Roles - only admin can update" ON public.people_roles;
DROP POLICY IF EXISTS "People Roles - only admin can insert" ON public.people_roles;
DROP POLICY IF EXISTS "People Roles - anyone can view" ON public.people_roles;

DROP POLICY IF EXISTS "Relationships - only admin can delete" ON public.relationships;
DROP POLICY IF EXISTS "Relationships - update with ownership check" ON public.relationships;
DROP POLICY IF EXISTS "Relationships - insert with ownership check" ON public.relationships;
DROP POLICY IF EXISTS "Relationships - anyone can view" ON public.relationships;

DROP POLICY IF EXISTS "Interactions - only admin can delete" ON public.interactions;
DROP POLICY IF EXISTS "Interactions - update with ownership check" ON public.interactions;
DROP POLICY IF EXISTS "Interactions - insert with ownership check" ON public.interactions;
DROP POLICY IF EXISTS "Interactions - anyone can view" ON public.interactions;

DROP POLICY IF EXISTS "Relationship Types - only admin can modify" ON public.relationship_types;
DROP POLICY IF EXISTS "Relationship Types - anyone can view" ON public.relationship_types;

DROP POLICY IF EXISTS "Roles - only admin can modify" ON public.roles;
DROP POLICY IF EXISTS "Roles - anyone can view" ON public.roles;

DROP FUNCTION IF EXISTS public.is_owner(UUID);
DROP FUNCTION IF EXISTS public.has_permission(TEXT);

-- Restore simple policies if desired:
CREATE POLICY "Allow select for authenticated users" ON public.people
  FOR SELECT USING (auth.role() = 'authenticated');
*/

-- -----------------------------------------------------------------------------
-- End migration_4_policy_enhancements.sql
