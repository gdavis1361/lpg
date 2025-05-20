-- Prerequisites:
--   - 20250519000000_enable_extensions.sql (for uuid-ossp for uuid_generate_v4())
--   - Assumes 'relationships', 'people', 'interactions', 'interaction_participants' tables exist.
--   - Assumes 'relationship_types' table exists and 'relationships.relationship_type_id' links to it,
--     and that there's a 'mentor' type. Or, that 'relationships.relationship_type' is a TEXT field.
-- Purpose: Implements the "Mentor Relationship Enhancement System" by:
--          1. Creating 'mentor_milestones' table.
--          2. Creating 'relationship_milestones' junction table.
--          3. Seeding basic mentor milestones.
--          4. Creating 'mentor_relationship_health' as a standard VIEW.
--          RLS policies for these tables will be in a later, consolidated file (20250526010000_apply_rls_policies.sql).

-- Create mentor_milestones table
CREATE TABLE IF NOT EXISTS public.mentor_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  typical_year INTEGER, -- Year in the 6-year journey (1-6) when this typically occurs
  is_required BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.mentor_milestones IS 'Defines standard milestones for mentor-student relationships.';
COMMENT ON COLUMN public.mentor_milestones.name IS 'Unique name of the milestone.';
COMMENT ON COLUMN public.mentor_milestones.typical_year IS 'Typical year in a 6-year mentor journey this milestone occurs (1-6).';
COMMENT ON COLUMN public.mentor_milestones.is_required IS 'Indicates if this milestone is considered mandatory.';

-- Create relationship_milestones junction table
CREATE TABLE IF NOT EXISTS public.relationship_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
  milestone_id UUID NOT NULL REFERENCES public.mentor_milestones(id) ON DELETE CASCADE,
  achieved_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  evidence_url TEXT, -- Optional link to photo or other evidence
  created_by UUID REFERENCES public.people(id) ON DELETE SET NULL, -- Who recorded this milestone achievement
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(relationship_id, milestone_id)
);
COMMENT ON TABLE public.relationship_milestones IS 'Tracks achieved milestones for specific mentor-student relationships.';
COMMENT ON COLUMN public.relationship_milestones.relationship_id IS 'Reference to the specific relationship.';
COMMENT ON COLUMN public.relationship_milestones.milestone_id IS 'Reference to the achieved mentor milestone.';
COMMENT ON COLUMN public.relationship_milestones.evidence_url IS 'Optional URL to evidence of milestone achievement.';

-- Create mentor relationship health view
-- This view will be replaced by a materialized view in a later migration (20250525010000_create_materialized_views.sql)
CREATE OR REPLACE VIEW public.mentor_relationship_health AS
SELECT
  r.id AS relationship_id,
  r.from_person_id AS mentor_id,
  pm.first_name AS mentor_first_name,
  pm.last_name AS mentor_last_name,
  r.to_person_id AS student_id,
  ps.first_name AS student_first_name,
  ps.last_name AS student_last_name,
  r.start_date,
  COALESCE(EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.start_date)), 0) AS relationship_years,
  COUNT(DISTINCT i.id) AS total_interactions,
  COUNT(DISTINCT i.id) FILTER (WHERE i.occurred_at > (CURRENT_DATE - INTERVAL '90 days')) AS recent_interactions_90_days,
  COUNT(DISTINCT rm.milestone_id) AS total_milestones_achieved,
  (SELECT COUNT(*) FROM public.mentor_milestones mm_req WHERE mm_req.is_required = TRUE) AS total_required_milestones_overall,
  COUNT(DISTINCT rm.milestone_id) FILTER (WHERE mm.is_required = TRUE) AS required_milestones_achieved_count,
  -- Health indicators
  CASE
    WHEN COUNT(DISTINCT i.id) FILTER (WHERE i.occurred_at > (CURRENT_DATE - INTERVAL '90 days')) = 0 THEN 'inactive'
    WHEN 
      (SELECT COUNT(mm_req.id) 
       FROM public.mentor_milestones mm_req 
       WHERE mm_req.is_required = TRUE 
         AND mm_req.typical_year <= COALESCE(EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.start_date)), 0)
      ) > COUNT(DISTINCT rm.milestone_id) FILTER (WHERE mm.is_required = TRUE AND mm.typical_year <= COALESCE(EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.start_date)), 0))
    THEN 'behind_required_milestones'
    ELSE 'healthy'
  END AS health_status
FROM public.relationships r
JOIN public.people pm ON r.from_person_id = pm.id -- mentor
JOIN public.people ps ON r.to_person_id = ps.id -- student
LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id -- Assuming relationship_type_id
-- If relationship_type is a text field directly on relationships table:
-- LEFT JOIN (SELECT 'mentor' as name) rt_static ON r.relationship_type = rt_static.name
LEFT JOIN public.interaction_participants ip_mentor ON r.from_person_id = ip_mentor.person_id
LEFT JOIN public.interaction_participants ip_student ON r.to_person_id = ip_student.person_id
LEFT JOIN public.interactions i ON ip_mentor.interaction_id = i.id AND ip_student.interaction_id = i.id AND i.id = ip_mentor.interaction_id -- Interaction between mentor and student
LEFT JOIN public.relationship_milestones rm ON r.id = rm.relationship_id
LEFT JOIN public.mentor_milestones mm ON rm.milestone_id = mm.id
WHERE rt.name = 'mentor' -- Or: WHERE r.relationship_type = 'mentor'
  AND r.status = 'active'
GROUP BY 
  r.id, r.from_person_id, pm.first_name, pm.last_name, 
  r.to_person_id, ps.first_name, ps.last_name, r.start_date;

COMMENT ON VIEW public.mentor_relationship_health IS 'Provides a health assessment for active mentor relationships. This is a standard view, to be replaced by a materialized view.';
COMMENT ON COLUMN public.mentor_relationship_health.relationship_years IS 'Number of full years the mentor relationship has been active.';
COMMENT ON COLUMN public.mentor_relationship_health.recent_interactions_90_days IS 'Number of interactions in the last 90 days.';
COMMENT ON COLUMN public.mentor_relationship_health.total_required_milestones_overall IS 'Total number of milestones marked as required in the system.';
COMMENT ON COLUMN public.mentor_relationship_health.required_milestones_achieved_count IS 'Number of required milestones achieved for this relationship.';
COMMENT ON COLUMN public.mentor_relationship_health.health_status IS 'Calculated health status of the mentor relationship (e.g., inactive, behind_required_milestones, healthy).';

-- Seed some basic milestones
-- These are inserted if the table is empty or these specific milestones don't exist.
INSERT INTO public.mentor_milestones (name, description, typical_year, is_required) VALUES
('Initial Mentor-Student Meeting', 'First formal meeting between mentor and student to establish rapport and expectations.', 1, TRUE),
('Personal Goals Setting', 'Collaborative session to define student''s academic, personal, and/or career goals for the year.', 1, TRUE),
('First School Event Attended by Mentor', 'Mentor attends a school event (e.g., sports game, performance, academic fair) with or in support of the student.', 1, FALSE),
('Academic Year 1 Review & Planning', 'End-of-year reflection on progress towards goals and planning for the next academic year.', 1, TRUE),
('Career Interests Exploration', 'Discussion about student''s career interests, potential pathways, and necessary skills.', 2, TRUE),
('Mentor Workplace Visit by Student', 'Student visits the mentor''s workplace to gain exposure to a professional environment.', 3, FALSE),
('Early College Awareness & Planning', 'Initial discussions about college options, types of institutions, and early preparation steps.', 4, TRUE),
('College Application Support & Review', 'Mentor provides guidance and feedback on college applications, essays, or interview preparation.', 6, TRUE),
('Student Graduation Attended by Mentor', 'Mentor attends the student''s high school graduation ceremony.', 6, TRUE),
('Post-Graduation Relationship Plan', 'Discussion and agreement on how the mentor-student relationship will continue post-graduation.', 6, TRUE)
ON CONFLICT (name) DO NOTHING;
COMMENT ON TABLE public.mentor_milestones IS 'Defines standard milestones for mentor-student relationships. Includes initial seed data.';

-- Note: RLS policies (ALTER TABLE ... ENABLE ROW LEVEL SECURITY; CREATE POLICY ...) 
-- for mentor_milestones and relationship_milestones
-- will be added in the consolidated RLS migration file: 20250526010000_apply_rls_policies.sql.
