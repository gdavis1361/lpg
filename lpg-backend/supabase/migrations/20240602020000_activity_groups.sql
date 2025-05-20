-- 20240602020000_activity_groups.sql
-- Prerequisites:
--   - 20240601010000_core_foundation.sql (for people table)
-- Purpose: Creates activity_groups and person_activities tables for cross-cultural brotherhood tracking.

BEGIN;

-- Create activity_groups table for categorizing activities
CREATE TABLE IF NOT EXISTS public.activity_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL, -- e.g., 'sports', 'academic', 'arts'
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create junction table for person-activity relationships
CREATE TABLE IF NOT EXISTS public.person_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  activity_group_id UUID NOT NULL REFERENCES public.activity_groups(id) ON DELETE CASCADE,
  role TEXT, -- e.g., 'member', 'captain', 'leader'
  primary_activity BOOLEAN DEFAULT FALSE,
  joined_at DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(person_id, activity_group_id)
);

-- Create indexes
CREATE INDEX idx_activity_groups_category ON activity_groups(category);
CREATE INDEX idx_person_activities_person ON person_activities(person_id);
CREATE INDEX idx_person_activities_activity ON person_activities(activity_group_id);
CREATE INDEX idx_person_activities_primary ON person_activities(person_id, primary_activity)
  WHERE primary_activity = TRUE;

-- Create triggers for updated_at
CREATE TRIGGER set_activity_groups_updated_at
  BEFORE UPDATE ON public.activity_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_person_activities_updated_at
  BEFORE UPDATE ON public.person_activities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply RLS immediately
ALTER TABLE public.activity_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_activities ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for activity_groups
CREATE POLICY "activity_groups_read_authenticated" ON public.activity_groups
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "activity_groups_modify_admin" ON public.activity_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

-- Create RLS policies for person_activities
CREATE POLICY "person_activities_read_authenticated" ON public.person_activities
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "person_activities_insert_self" ON public.person_activities
  FOR INSERT WITH CHECK (
    -- People can add themselves to activities
    person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid())
    -- Or if they're an admin
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "person_activities_update_self" ON public.person_activities
  FOR UPDATE USING (
    -- People can update their own activities
    person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid())
    -- Or if they're an admin
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "person_activities_delete_admin" ON public.person_activities
  FOR DELETE USING (
    -- Only admins can delete activities
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

-- Seed some common activity groups
INSERT INTO public.activity_groups (name, category, description) VALUES
  ('Basketball Team', 'sports', 'School basketball team'),
  ('Football Team', 'sports', 'School football team'),
  ('Chess Club', 'academic', 'Chess club for strategic thinking'),
  ('Science Club', 'academic', 'Science exploration and experiments'),
  ('Art Club', 'arts', 'Visual arts and creative expression'),
  ('Music Program', 'arts', 'Music performance and education'),
  ('Student Leadership', 'leadership', 'Student government and leadership roles'),
  ('Debate Team', 'academic', 'Competitive debate and public speaking'),
  ('Volunteer Corps', 'service', 'Community service initiatives')
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE public.activity_groups IS 'Categorizes activities or groups students can participate in.';
COMMENT ON COLUMN public.activity_groups.name IS 'Unique name of the activity group.';
COMMENT ON COLUMN public.activity_groups.category IS 'Broad category of the activity (e.g., sports, academic, arts).';

COMMENT ON TABLE public.person_activities IS 'Junction table linking people to activity groups they participate in.';
COMMENT ON COLUMN public.person_activities.person_id IS 'Reference to the person involved in the activity.';
COMMENT ON COLUMN public.person_activities.activity_group_id IS 'Reference to the activity group.';
COMMENT ON COLUMN public.person_activities.role IS 'Role of the person within the activity (e.g., member, captain).';
COMMENT ON COLUMN public.person_activities.primary_activity IS 'Indicates if this is the person''s primary activity group.';

COMMIT; 