-- Prerequisites:
--   - All migrations that create or alter the tables mentioned below, including:
--     - Existing tables: people, interactions
--     - 20250520010000_cross_cultural_participation_view.sql (for activity_groups, person_activities, cross_group_participations)
--     - 20250521010000_alumni_continuity.sql (for alumni_checkins)
--     - 20250522010000_mentor_relationship_milestones_view.sql (for mentor_milestones, relationship_milestones)
--     - 20250523010000_ai_relationship_intelligence.sql (for relationship_patterns, relationship_pattern_detections, relationship_suggestions)
--   - Assumes a 'has_permission(TEXT)' function exists for role checking.
-- Purpose: Applies Row Level Security (RLS) policies to various tables for data protection and access control.

-- === People Table ===
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.people IS 'RLS enabled. Stores information about individuals in the system.';

CREATE POLICY "People - staff and admins can view all"
ON public.people FOR SELECT
USING (
  public.has_permission('staff') OR public.has_permission('admin')
);
COMMENT ON POLICY "People - staff and admins can view all" ON public.people IS 'Allows users with ''staff'' or ''admin'' permissions to view all records in the people table.';

CREATE POLICY "People - users can view themselves"
ON public.people FOR SELECT
USING (
  id = (SELECT p.id FROM public.people p WHERE p.auth_id = auth.uid() LIMIT 1)
);
COMMENT ON POLICY "People - users can view themselves" ON public.people IS 'Allows authenticated users to view their own record in the people table.';

CREATE POLICY "People - mentors can view their mentees"
ON public.people FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.relationships r
    JOIN public.relationship_types rt ON r.relationship_type_id = rt.id -- Assuming relationship_type_id
    WHERE r.to_person_id = public.people.id 
    AND r.from_person_id = (SELECT p.id FROM public.people p WHERE p.auth_id = auth.uid() LIMIT 1)
    AND rt.name = 'mentor' -- Or r.relationship_type = 'mentor' if it's a direct text field
    AND r.status = 'active'
  )
);
COMMENT ON POLICY "People - mentors can view their mentees" ON public.people IS 'Allows authenticated mentors to view the records of their active mentees.';

-- === Interactions Table ===
ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.interactions IS 'RLS enabled. Stores records of interactions between people.';

CREATE POLICY "Interactions - staff and admins can view all"
ON public.interactions FOR SELECT
USING (
  public.has_permission('staff') OR public.has_permission('admin')
);
COMMENT ON POLICY "Interactions - staff and admins can view all" ON public.interactions IS 'Allows users with ''staff'' or ''admin'' permissions to view all interactions.';

CREATE POLICY "Interactions - users can view their own"
ON public.interactions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.interaction_participants ip
    JOIN public.people p ON ip.person_id = p.id
    WHERE ip.interaction_id = public.interactions.id
    AND p.auth_id = auth.uid()
  )
);
COMMENT ON POLICY "Interactions - users can view their own" ON public.interactions IS 'Allows authenticated users to view interactions they participated in.';

-- === Activity Groups Table ===
ALTER TABLE public.activity_groups ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.activity_groups IS 'RLS enabled. Categorizes activities or groups students can participate in.';

CREATE POLICY "Activity Groups - anyone can view" 
ON public.activity_groups FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Activity Groups - anyone can view" ON public.activity_groups IS 'Allows any authenticated user to view activity groups.';

-- === Person Activities Table ===
ALTER TABLE public.person_activities ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.person_activities IS 'RLS enabled. Junction table linking people to activity groups.';

CREATE POLICY "Person Activities - anyone can view" 
ON public.person_activities FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Person Activities - anyone can view" ON public.person_activities IS 'Allows any authenticated user to view person-activity links.';

-- === Cross Group Participations Table ===
ALTER TABLE public.cross_group_participations ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.cross_group_participations IS 'RLS enabled. Tracks cross-group participation events.';

CREATE POLICY "Cross Group Participations - anyone can view" 
ON public.cross_group_participations FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Cross Group Participations - anyone can view" ON public.cross_group_participations IS 'Allows any authenticated user to view cross-group participation records.';

-- === Alumni Checkins Table ===
ALTER TABLE public.alumni_checkins ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.alumni_checkins IS 'RLS enabled. Records of check-ins with alumni.';

CREATE POLICY "Alumni Checkins - anyone can view" -- Consider if this should be more restrictive, e.g., staff/admin only
ON public.alumni_checkins FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Alumni Checkins - anyone can view" ON public.alumni_checkins IS 'Allows any authenticated user to view alumni check-ins. Review if more restrictive access is needed.';

-- === Mentor Milestones Table ===
ALTER TABLE public.mentor_milestones ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.mentor_milestones IS 'RLS enabled. Defines standard milestones for mentor-student relationships.';

CREATE POLICY "Mentor Milestones - anyone can view" 
ON public.mentor_milestones FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Mentor Milestones - anyone can view" ON public.mentor_milestones IS 'Allows any authenticated user to view defined mentor milestones.';

-- === Relationship Milestones Table ===
ALTER TABLE public.relationship_milestones ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.relationship_milestones IS 'RLS enabled. Tracks achieved milestones for specific mentor-student relationships.';

CREATE POLICY "Relationship Milestones - anyone can view" -- Consider if this should be more restrictive
ON public.relationship_milestones FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Relationship Milestones - anyone can view" ON public.relationship_milestones IS 'Allows any authenticated user to view achieved relationship milestones. Review if more restrictive access is needed.';

-- === Relationship Patterns Table ===
ALTER TABLE public.relationship_patterns ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.relationship_patterns IS 'RLS enabled. Defines types of relationship patterns for AI system.';

CREATE POLICY "Relationship Patterns - anyone can view" 
ON public.relationship_patterns FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Relationship Patterns - anyone can view" ON public.relationship_patterns IS 'Allows any authenticated user to view defined relationship patterns.';

-- === Relationship Pattern Detections Table ===
ALTER TABLE public.relationship_pattern_detections ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.relationship_pattern_detections IS 'RLS enabled. Stores instances of detected relationship patterns.';

CREATE POLICY "Relationship Pattern Detections - anyone can view" -- Consider if this should be more restrictive
ON public.relationship_pattern_detections FOR SELECT 
USING (auth.role() = 'authenticated');
COMMENT ON POLICY "Relationship Pattern Detections - anyone can view" ON public.relationship_pattern_detections IS 'Allows any authenticated user to view detected relationship patterns. Review if more restrictive access is needed.';

-- === Relationship Suggestions Table ===
ALTER TABLE public.relationship_suggestions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.relationship_suggestions IS 'RLS enabled. Stores AI-generated suggestions for relationship actions.';

CREATE POLICY "Relationship Suggestions - view own suggestions or admin" 
ON public.relationship_suggestions FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.people p
    WHERE p.id = public.relationship_suggestions.for_person_id
    AND p.auth_id = auth.uid()
  )
  OR public.has_permission('admin')
);
COMMENT ON POLICY "Relationship Suggestions - view own suggestions or admin" ON public.relationship_suggestions IS 'Allows users to view suggestions intended for them, or admins to view all suggestions.';
