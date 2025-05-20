-- Prerequisites:
--   - 20250519000000_enable_extensions.sql (for uuid-ossp for uuid_generate_v4())
--   - Assumes 'people' table exists.
-- Purpose: Implements the "Cross-Cultural Brotherhood Tracking System" by:
--          1. Creating 'activity_groups' table.
--          2. Creating 'person_activities' junction table.
--          3. Creating 'cross_group_participations' table.
--          4. Creating 'brotherhood_visibility' as a standard VIEW.
--          RLS policies for these tables will be in a later, consolidated file (20250526010000_apply_rls_policies.sql).

-- Create activity_groups table for categorizing activities
CREATE TABLE IF NOT EXISTS public.activity_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL, -- e.g., 'sports', 'academic', 'arts'
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.activity_groups IS 'Categorizes activities or groups students can participate in.';
COMMENT ON COLUMN public.activity_groups.name IS 'Unique name of the activity group.';
COMMENT ON COLUMN public.activity_groups.category IS 'Broad category of the activity (e.g., sports, academic, arts).';

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
COMMENT ON TABLE public.person_activities IS 'Junction table linking people to activity groups they participate in.';
COMMENT ON COLUMN public.person_activities.person_id IS 'Reference to the person involved in the activity.';
COMMENT ON COLUMN public.person_activities.activity_group_id IS 'Reference to the activity group.';
COMMENT ON COLUMN public.person_activities.role IS 'Role of the person within the activity (e.g., member, captain).';
COMMENT ON COLUMN public.person_activities.primary_activity IS 'Indicates if this is the person''s primary activity group.';

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
COMMENT ON TABLE public.cross_group_participations IS 'Tracks instances of a person participating in an activity outside their primary group.';
COMMENT ON COLUMN public.cross_group_participations.home_activity_id IS 'The person''s primary or home activity group.';
COMMENT ON COLUMN public.cross_group_participations.visited_activity_id IS 'The activity group the person visited or participated in.';
COMMENT ON COLUMN public.cross_group_participations.recognition_points IS 'Points awarded for this cross-group participation.';
COMMENT ON CONSTRAINT different_activities ON public.cross_group_participations IS 'Ensures home and visited activities are different.';

-- Create a view for brotherhood visualization
-- This view will be replaced by a materialized view in a later migration (20250525010000_create_materialized_views.sql)
CREATE OR REPLACE VIEW public.brotherhood_visibility AS
SELECT 
  p.id as person_id,
  p.first_name,
  p.last_name,
  home_ag.id as home_activity_id,
  home_ag.name as home_activity_name,
  home_ag.category as home_activity_category,
  visited_ag.id as visited_activity_id,
  visited_ag.name as visited_activity_name,
  visited_ag.category as visited_activity_category,
  COUNT(cgp.id) as visit_count,
  SUM(cgp.recognition_points) as total_recognition_points
FROM public.people p
JOIN public.person_activities pa ON p.id = pa.person_id AND pa.primary_activity = TRUE
JOIN public.activity_groups home_ag ON pa.activity_group_id = home_ag.id
JOIN public.cross_group_participations cgp ON p.id = cgp.person_id AND home_ag.id = cgp.home_activity_id
JOIN public.activity_groups visited_ag ON cgp.visited_activity_id = visited_ag.id
GROUP BY 
  p.id, p.first_name, p.last_name, 
  home_ag.id, home_ag.name, home_ag.category, 
  visited_ag.id, visited_ag.name, visited_ag.category;

COMMENT ON VIEW public.brotherhood_visibility IS 'Provides a view for analyzing cross-group participation and "brotherhood visibility". This is a standard view, to be replaced by a materialized view.';
COMMENT ON COLUMN public.brotherhood_visibility.visit_count IS 'Number of times a person from a home activity visited a specific other activity.';
COMMENT ON COLUMN public.brotherhood_visibility.total_recognition_points IS 'Total recognition points accumulated for visits between specific home and visited activities by a person.';

-- Note: RLS policies (ALTER TABLE ... ENABLE ROW LEVEL SECURITY; CREATE POLICY ...) 
-- for activity_groups, person_activities, and cross_group_participations
-- will be added in the consolidated RLS migration file: 20250526010000_apply_rls_policies.sql.
