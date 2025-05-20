-- Migration: 20250601000000_optimize_rls_policies.sql
-- Purpose: Optimizes Row Level Security (RLS) policy implementation for better performance

-- 1. Create an efficient helper function for current user lookup with caching
CREATE OR REPLACE FUNCTION get_current_user_person_id()
RETURNS UUID AS $$
DECLARE
  current_person_id UUID;
BEGIN
  -- Get current user ID from Supabase auth.uid()
  SELECT id INTO current_person_id 
  FROM people 
  WHERE auth_id = auth.uid()
  LIMIT 1;
  
  RETURN current_person_id;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE SECURITY DEFINER;

-- 2. Create a lookup table to optimize mentor/mentee relationship access checks
CREATE TABLE IF NOT EXISTS public.mentor_student_relationships (
  mentor_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (mentor_id, student_id)
);

-- Create indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_mentor_student_mentor_id ON mentor_student_relationships(mentor_id);
CREATE INDEX IF NOT EXISTS idx_mentor_student_student_id ON mentor_student_relationships(student_id);
CREATE INDEX IF NOT EXISTS idx_mentor_student_relationship_id ON mentor_student_relationships(relationship_id);

-- 3. Create a function to maintain the mentor_student_relationships table
CREATE OR REPLACE FUNCTION update_mentor_student_table()
RETURNS TRIGGER AS $$
DECLARE
  mentor_type_id UUID;
BEGIN
  -- Get mentor relationship type ID
  SELECT id INTO mentor_type_id FROM relationship_types WHERE code = 'mentor';
  
  IF TG_OP = 'DELETE' THEN
    -- Remove record if relationship is deleted
    DELETE FROM mentor_student_relationships 
    WHERE relationship_id = OLD.id;
    
    RETURN OLD;
  ELSIF TG_OP = 'INSERT' THEN
    -- Insert new record for new mentor relationships
    IF NEW.relationship_type_id = mentor_type_id AND NEW.status = 'active' THEN
      INSERT INTO mentor_student_relationships (mentor_id, student_id, relationship_id)
      VALUES (NEW.from_person_id, NEW.to_person_id, NEW.id)
      ON CONFLICT (mentor_id, student_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle relationship type or status changes
    
    -- If changing to a mentor relationship and active, add to table
    IF NEW.relationship_type_id = mentor_type_id AND NEW.status = 'active' AND 
       (OLD.relationship_type_id != mentor_type_id OR OLD.status != 'active') THEN
      INSERT INTO mentor_student_relationships (mentor_id, student_id, relationship_id)
      VALUES (NEW.from_person_id, NEW.to_person_id, NEW.id)
      ON CONFLICT (mentor_id, student_id) DO NOTHING;
    
    -- If changing from a mentor relationship or no longer active, remove from table
    ELSIF (OLD.relationship_type_id = mentor_type_id AND OLD.status = 'active') AND 
          (NEW.relationship_type_id != mentor_type_id OR NEW.status != 'active') THEN
      DELETE FROM mentor_student_relationships 
      WHERE relationship_id = NEW.id;
    END IF;
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for the relationships table
DROP TRIGGER IF EXISTS maintain_mentor_student_table ON relationships;
CREATE TRIGGER maintain_mentor_student_table
AFTER INSERT OR UPDATE OR DELETE ON relationships
FOR EACH ROW EXECUTE FUNCTION update_mentor_student_table();

-- 4. Backfill the mentor_student_relationships table with existing data
INSERT INTO mentor_student_relationships (mentor_id, student_id, relationship_id)
SELECT r.from_person_id, r.to_person_id, r.id
FROM relationships r
JOIN relationship_types rt ON r.relationship_type_id = rt.id
WHERE rt.code = 'mentor' AND r.status = 'active'
ON CONFLICT (mentor_id, student_id) DO NOTHING;

-- 5. Refine the profiles table permissions for better performance
-- Drop and recreate the RLS policies with optimized checks
ALTER TABLE public.people DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;

-- Everybody can see themselves
DROP POLICY IF EXISTS people_self_view_policy ON people;
CREATE POLICY people_self_view_policy ON people
  FOR SELECT 
  USING (id = get_current_user_person_id());

-- Admins can see and manage all people
DROP POLICY IF EXISTS people_admin_policy ON people;
CREATE POLICY people_admin_policy ON people
  FOR ALL
  USING (has_permission('admin') OR has_permission('staff'));

-- Mentors can view their mentees
DROP POLICY IF EXISTS people_mentors_view_policy ON people;
CREATE POLICY people_mentors_view_policy ON people
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM mentor_student_relationships 
      WHERE mentor_id = get_current_user_person_id() 
        AND student_id = people.id
    )
  );

-- 6. Optimize relationship timeline view access
DROP POLICY IF EXISTS relationship_timeline_view_policy ON relationship_timeline_unified;
CREATE POLICY relationship_timeline_view_policy ON relationship_timeline_unified
  FOR SELECT
  USING (
    -- Allow viewing timelines for any relationship the user is part of
    person_id = get_current_user_person_id()
    OR from_person_id = get_current_user_person_id()
    OR to_person_id = get_current_user_person_id()
    -- Mentors can view their mentees' timelines
    OR EXISTS (
      SELECT 1 FROM mentor_student_relationships
      WHERE mentor_id = get_current_user_person_id()
        AND (student_id = person_id OR student_id = from_person_id OR student_id = to_person_id)
    )
    -- Admins/staff can view all timelines
    OR has_permission('admin')
    OR has_permission('staff')
  );

-- 7. Optimize the relationship_milestones table policies
DROP POLICY IF EXISTS relationship_milestones_select_policy ON relationship_milestones;
CREATE POLICY relationship_milestones_select_policy ON relationship_milestones
  FOR SELECT 
  USING (
    -- People can view milestones for their own relationships
    EXISTS (
      SELECT 1 FROM relationships r
      WHERE r.id = relationship_milestones.relationship_id
        AND (r.from_person_id = get_current_user_person_id() OR r.to_person_id = get_current_user_person_id())
    )
    -- Admins/staff can view all milestones
    OR has_permission('admin')
    OR has_permission('staff')
    -- Mentors can view their mentees' milestones
    OR EXISTS (
      SELECT 1 FROM relationships r
      JOIN mentor_student_relationships msr ON r.id = msr.relationship_id
      WHERE r.id = relationship_milestones.relationship_id
        AND msr.mentor_id = get_current_user_person_id()
    )
  );

DROP POLICY IF EXISTS relationship_milestones_insert_policy ON relationship_milestones;
CREATE POLICY relationship_milestones_insert_policy ON relationship_milestones
  FOR INSERT 
  WITH CHECK (
    -- People can add milestones to relationships they are part of
    EXISTS (
      SELECT 1 FROM relationships r
      WHERE r.id = relationship_milestones.relationship_id
        AND (r.from_person_id = get_current_user_person_id() OR r.to_person_id = get_current_user_person_id())
    )
    -- Admins/staff can add milestones to any relationship
    OR has_permission('admin')
    OR has_permission('staff')
    -- Mentors can add milestones to their mentees' relationships
    OR EXISTS (
      SELECT 1 FROM relationships r
      JOIN mentor_student_relationships msr ON r.id = msr.relationship_id
      WHERE r.id = relationship_milestones.relationship_id
        AND msr.mentor_id = get_current_user_person_id()
    )
  );

DROP POLICY IF EXISTS relationship_milestones_update_policy ON relationship_milestones;
CREATE POLICY relationship_milestones_update_policy ON relationship_milestones
  FOR UPDATE
  USING (
    -- People can update milestones to relationships they are part of
    EXISTS (
      SELECT 1 FROM relationships r
      WHERE r.id = relationship_milestones.relationship_id
        AND (r.from_person_id = get_current_user_person_id() OR r.to_person_id = get_current_user_person_id())
    )
    -- Admins/staff can update any milestone
    OR has_permission('admin')
    OR has_permission('staff')
    -- Mentors can update their mentees' milestones
    OR EXISTS (
      SELECT 1 FROM relationships r
      JOIN mentor_student_relationships msr ON r.id = msr.relationship_id
      WHERE r.id = relationship_milestones.relationship_id
        AND msr.mentor_id = get_current_user_person_id()
    )
  );

DROP POLICY IF EXISTS relationship_milestones_delete_policy ON relationship_milestones;
CREATE POLICY relationship_milestones_delete_policy ON relationship_milestones
  FOR DELETE
  USING (
    -- Only admins/staff can delete milestones
    has_permission('admin')
    OR has_permission('staff')
  );

-- 8. Optimize alumni_checkins table policies
DROP POLICY IF EXISTS alumni_checkins_select_policy ON alumni_checkins;
CREATE POLICY alumni_checkins_select_policy ON alumni_checkins
  FOR SELECT 
  USING (
    -- Alumni can view their own check-ins
    alumni_id = get_current_user_person_id()
    -- Admins/staff can view all check-ins
    OR has_permission('admin')
    OR has_permission('staff')
    -- Mentors can view their mentees' check-ins
    OR EXISTS (
      SELECT 1 FROM mentor_student_relationships
      WHERE mentor_id = get_current_user_person_id()
        AND student_id = alumni_checkins.alumni_id
    )
  );

DROP POLICY IF EXISTS alumni_checkins_insert_policy ON alumni_checkins;
CREATE POLICY alumni_checkins_insert_policy ON alumni_checkins
  FOR INSERT 
  WITH CHECK (
    -- Alumni can add their own check-ins
    alumni_id = get_current_user_person_id()
    -- Admins/staff can add check-ins for anyone
    OR has_permission('admin')
    OR has_permission('staff')
  );

DROP POLICY IF EXISTS alumni_checkins_update_policy ON alumni_checkins;
CREATE POLICY alumni_checkins_update_policy ON alumni_checkins
  FOR UPDATE
  USING (
    -- Alumni can update their own check-ins
    alumni_id = get_current_user_person_id()
    -- Admins/staff can update any check-in
    OR has_permission('admin')
    OR has_permission('staff')
  );

DROP POLICY IF EXISTS alumni_checkins_delete_policy ON alumni_checkins;
CREATE POLICY alumni_checkins_delete_policy ON alumni_checkins
  FOR DELETE
  USING (
    -- Only admins/staff can delete check-ins
    has_permission('admin')
    OR has_permission('staff')
  );

-- 9. Optimize cross_group_participations table policies
DROP POLICY IF EXISTS cross_group_participations_select_policy ON cross_group_participations;
CREATE POLICY cross_group_participations_select_policy ON cross_group_participations
  FOR SELECT 
  USING (
    -- Everyone can view cross-group participations
    auth.uid() IS NOT NULL
  );

DROP POLICY IF EXISTS cross_group_participations_insert_policy ON cross_group_participations;
CREATE POLICY cross_group_participations_insert_policy ON cross_group_participations
  FOR INSERT 
  WITH CHECK (
    -- People can add their own participations
    person_id = get_current_user_person_id()
    -- Admins/staff can add participations for anyone
    OR has_permission('admin')
    OR has_permission('staff')
  );

DROP POLICY IF EXISTS cross_group_participations_update_policy ON cross_group_participations;
CREATE POLICY cross_group_participations_update_policy ON cross_group_participations
  FOR UPDATE
  USING (
    -- People can update their own participations if they created them
    (person_id = get_current_user_person_id() AND created_by = get_current_user_person_id())
    -- Admins/staff can update any participation
    OR has_permission('admin')
    OR has_permission('staff')
  );

DROP POLICY IF EXISTS cross_group_participations_delete_policy ON cross_group_participations;
CREATE POLICY cross_group_participations_delete_policy ON cross_group_participations
  FOR DELETE
  USING (
    -- Only admins/staff can delete participations
    has_permission('admin')
    OR has_permission('staff')
  );

-- 10. Create a view for role-based permissions to simplify policy definitions
CREATE OR REPLACE VIEW user_permissions AS
SELECT 
  p.id AS person_id,
  p.auth_id,
  r.code AS role_code,
  r.name AS role_name,
  r.code = 'admin' AS is_admin,
  r.code = 'staff' AS is_staff,
  r.code = 'mentor' AS is_mentor,
  r.code = 'teacher' AS is_teacher,
  r.code = 'student' AS is_student,
  r.code = 'alumni' AS is_alumni,
  (SELECT array_agg(student_id) FROM mentor_student_relationships WHERE mentor_id = p.id) AS mentee_ids
FROM people p
JOIN roles r ON p.role_id = r.id;

-- Create a function to check if a user is a mentor for a specific student
CREATE OR REPLACE FUNCTION is_mentor_for(student_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM mentor_student_relationships
    WHERE mentor_id = get_current_user_person_id()
      AND student_id = is_mentor_for.student_id
  );
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE SECURITY DEFINER;

COMMENT ON FUNCTION get_current_user_person_id IS 'Efficient cached lookup of the current user''s person_id';
COMMENT ON TABLE mentor_student_relationships IS 'Denormalized lookup table for mentor-student relationships to optimize permissions checks';
COMMENT ON FUNCTION update_mentor_student_table IS 'Trigger function to maintain the mentor_student_relationships table';
COMMENT ON FUNCTION is_mentor_for IS 'Check if the current user is a mentor for a specific student';
COMMENT ON VIEW user_permissions IS 'Consolidated view of user permissions based on roles and relationships';

-- Apply RLS to materialized views to avoid security policy bypass

-- Enable RLS on relationship_strength_analytics_mv
ALTER MATERIALIZED VIEW relationship_strength_analytics_mv ENABLE ROW LEVEL SECURITY;

CREATE POLICY relationship_strength_mv_access ON relationship_strength_analytics_mv
  FOR SELECT 
  USING (
    from_person_id = get_current_user_person_id()
    OR to_person_id = get_current_user_person_id()
    OR EXISTS (
      SELECT 1 FROM mentor_student_relationships msr
      WHERE msr.mentor_id = get_current_user_person_id()
        AND (msr.student_id = from_person_id OR msr.student_id = to_person_id)
    )
    OR has_permission('admin')
    OR has_permission('staff')
  );

-- Enable RLS on mentor_relationship_health_mv
ALTER MATERIALIZED VIEW mentor_relationship_health_mv ENABLE ROW LEVEL SECURITY;

CREATE POLICY mentor_relationship_health_mv_access ON mentor_relationship_health_mv
  FOR SELECT 
  USING (
    mentor_id = get_current_user_person_id()
    OR student_id = get_current_user_person_id()
    OR has_permission('admin')
    OR has_permission('staff')
  );

-- Enable RLS on brotherhood_visibility_mv
ALTER MATERIALIZED VIEW brotherhood_visibility_mv ENABLE ROW LEVEL SECURITY;

CREATE POLICY brotherhood_visibility_mv_access ON brotherhood_visibility_mv
  FOR SELECT 
  USING (
    person_id = get_current_user_person_id()
    OR EXISTS (
      SELECT 1 FROM mentor_student_relationships msr
      WHERE msr.mentor_id = get_current_user_person_id()
        AND msr.student_id = person_id
    )
    OR has_permission('admin')
    OR has_permission('staff')
  );

-- Enable RLS on alumni_risk_assessment_mv
ALTER MATERIALIZED VIEW alumni_risk_assessment_mv ENABLE ROW LEVEL SECURITY;

CREATE POLICY alumni_risk_assessment_mv_access ON alumni_risk_assessment_mv
  FOR SELECT 
  USING (
    alumni_id = get_current_user_person_id()
    OR has_permission('admin')
    OR has_permission('staff')
  );

COMMENT ON POLICY relationship_strength_mv_access ON relationship_strength_analytics_mv IS 'Controls access to relationship strength analytics';
COMMENT ON POLICY mentor_relationship_health_mv_access ON mentor_relationship_health_mv IS 'Controls access to mentor relationship health analysis';
COMMENT ON POLICY brotherhood_visibility_mv_access ON brotherhood_visibility_mv IS 'Controls access to brotherhood visibility analysis';
COMMENT ON POLICY alumni_risk_assessment_mv_access ON alumni_risk_assessment_mv IS 'Controls access to alumni risk assessment data';
