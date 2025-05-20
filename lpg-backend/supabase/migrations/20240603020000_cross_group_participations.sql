-- 20240603020000_cross_group_participations.sql
-- Prerequisites:
--   - 20240601010000_core_foundation.sql (for people table)
--   - 20240602020000_activity_groups.sql (for activity_groups table)
-- Purpose: Creates cross_group_participations table for brotherhood tracking.

BEGIN;

-- Create a table to track cross-group participation events
CREATE TABLE IF NOT EXISTS public.cross_group_participations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  home_activity_id UUID NOT NULL REFERENCES public.activity_groups(id) ON DELETE CASCADE,
  visited_activity_id UUID NOT NULL REFERENCES public.activity_groups(id) ON DELETE CASCADE,
  event_date DATE NOT NULL DEFAULT CURRENT_DATE,
  event_description TEXT,
  recognition_points INTEGER DEFAULT 1,
  created_by UUID REFERENCES public.people(id) ON DELETE SET NULL, -- Who recorded this participation
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT different_activities CHECK (home_activity_id <> visited_activity_id)
);

-- Create indexes
CREATE INDEX idx_cross_group_person ON cross_group_participations(person_id);
CREATE INDEX idx_cross_group_home ON cross_group_participations(home_activity_id);
CREATE INDEX idx_cross_group_visited ON cross_group_participations(visited_activity_id);
CREATE INDEX idx_cross_group_date ON cross_group_participations(event_date);

-- Automatically set updated_at on UPDATE
CREATE TRIGGER set_cross_group_participations_updated_at
  BEFORE UPDATE ON public.cross_group_participations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply RLS immediately
ALTER TABLE public.cross_group_participations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "cross_group_participations_read_authenticated" ON public.cross_group_participations
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "cross_group_participations_insert_self" ON public.cross_group_participations
  FOR INSERT WITH CHECK (
    -- People can add their own participations
    person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid())
    -- Or if they're an admin or staff
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "cross_group_participations_update_self" ON public.cross_group_participations
  FOR UPDATE USING (
    -- People can update their own participations if they created them
    (person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid()) AND
     created_by IN (SELECT id FROM public.people WHERE auth_id = auth.uid()))
    -- Or if they're an admin or staff
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "cross_group_participations_delete_admin" ON public.cross_group_participations
  FOR DELETE USING (
    -- Only admins can delete participations
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

-- Create a helper function to find a person's primary activity
CREATE OR REPLACE FUNCTION get_primary_activity_id(p_person_id UUID)
RETURNS UUID AS $$
DECLARE
  v_activity_id UUID;
BEGIN
  SELECT activity_group_id INTO v_activity_id
  FROM person_activities
  WHERE person_id = p_person_id AND primary_activity = TRUE
  LIMIT 1;
  
  RETURN v_activity_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Create a function to record cross-group participation with automatic primary activity detection
CREATE OR REPLACE FUNCTION record_cross_group_participation(
  p_person_id UUID,
  p_visited_activity_id UUID,
  p_event_description TEXT DEFAULT NULL,
  p_event_date DATE DEFAULT CURRENT_DATE,
  p_recognition_points INTEGER DEFAULT 1
)
RETURNS UUID AS $$
DECLARE
  v_home_activity_id UUID;
  v_participation_id UUID;
  v_created_by UUID;
BEGIN
  -- Get the person's primary activity
  v_home_activity_id := get_primary_activity_id(p_person_id);
  
  -- Get the current user's person_id
  SELECT id INTO v_created_by 
  FROM people
  WHERE auth_id = auth.uid()
  LIMIT 1;
  
  IF v_home_activity_id IS NULL THEN
    RAISE EXCEPTION 'Person does not have a primary activity assigned';
  END IF;
  
  IF v_home_activity_id = p_visited_activity_id THEN
    RAISE EXCEPTION 'Home and visited activities cannot be the same';
  END IF;
  
  -- Insert the cross-group participation
  INSERT INTO cross_group_participations (
    person_id,
    home_activity_id,
    visited_activity_id,
    event_date,
    event_description,
    recognition_points,
    created_by
  ) VALUES (
    p_person_id,
    v_home_activity_id,
    p_visited_activity_id,
    p_event_date,
    p_event_description,
    p_recognition_points,
    v_created_by
  ) RETURNING id INTO v_participation_id;
  
  RETURN v_participation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_primary_activity_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION record_cross_group_participation(UUID, UUID, TEXT, DATE, INTEGER) TO authenticated;

COMMENT ON TABLE public.cross_group_participations IS 'Tracks instances of a person participating in an activity outside their primary group.';
COMMENT ON COLUMN public.cross_group_participations.home_activity_id IS 'The person''s primary or home activity group.';
COMMENT ON COLUMN public.cross_group_participations.visited_activity_id IS 'The activity group the person visited or participated in.';
COMMENT ON COLUMN public.cross_group_participations.recognition_points IS 'Points awarded for this cross-group participation.';
COMMENT ON CONSTRAINT different_activities ON public.cross_group_participations IS 'Ensures home and visited activities are different.';

COMMENT ON FUNCTION get_primary_activity_id IS 'Helper function to find a person''s primary activity group.';
COMMENT ON FUNCTION record_cross_group_participation IS 'Creates a cross-group participation record with automatic primary activity detection.';

COMMIT; 