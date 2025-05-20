-- 20240603010000_relationship_milestones.sql
-- Prerequisites:
--   - 20240601010000_core_foundation.sql (for people table)
--   - 20240602010000_mentoring_tables.sql (for mentor_milestones table)
--   - 20240603000000_relationships.sql (for relationships table)
-- Purpose: Creates the relationship_milestones junction table with proper RLS.

BEGIN;

-- Create relationship_milestones junction table
CREATE TABLE IF NOT EXISTS public.relationship_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
  milestone_id UUID NOT NULL REFERENCES public.mentor_milestones(id) ON DELETE CASCADE,
  achieved_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  evidence_url TEXT, -- Optional link to photo or other evidence
  evidence_description TEXT,
  created_by UUID REFERENCES public.people(id) ON DELETE SET NULL, -- Who recorded this milestone achievement
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(relationship_id, milestone_id)
);

-- Create indexes for relationship_milestones
CREATE INDEX idx_relationship_milestones_relationship ON relationship_milestones(relationship_id);
CREATE INDEX idx_relationship_milestones_milestone ON relationship_milestones(milestone_id);
CREATE INDEX idx_relationship_milestones_date ON relationship_milestones(achieved_date);

-- Automatically set updated_at on UPDATE
CREATE TRIGGER set_relationship_milestones_updated_at
  BEFORE UPDATE ON public.relationship_milestones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply RLS immediately
ALTER TABLE public.relationship_milestones ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for relationship_milestones
CREATE POLICY "relationship_milestones_read_participant" ON public.relationship_milestones
  FOR SELECT USING (
    -- People can view milestones for their own relationships
    EXISTS (
      SELECT 1 FROM public.relationships r
      WHERE r.id = relationship_milestones.relationship_id
      AND (
        r.from_person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid()) OR
        r.to_person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid())
      )
    )
    -- Or if they're an admin or staff
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "relationship_milestones_insert_participant" ON public.relationship_milestones
  FOR INSERT WITH CHECK (
    -- People can add milestones to their own relationships
    EXISTS (
      SELECT 1 FROM public.relationships r
      WHERE r.id = relationship_milestones.relationship_id
      AND (
        r.from_person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid()) OR
        r.to_person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid())
      )
    )
    -- Or if they're an admin or staff
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "relationship_milestones_update_participant" ON public.relationship_milestones
  FOR UPDATE USING (
    -- People can update milestones for their own relationships
    EXISTS (
      SELECT 1 FROM public.relationships r
      WHERE r.id = relationship_milestones.relationship_id
      AND (
        r.from_person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid()) OR
        r.to_person_id IN (SELECT id FROM public.people WHERE auth_id = auth.uid())
      )
    )
    -- Or if they're an admin or staff
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "relationship_milestones_delete_admin" ON public.relationship_milestones
  FOR DELETE USING (
    -- Only admins and staff can delete milestones
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

COMMENT ON TABLE public.relationship_milestones IS 'Tracks achieved milestones for specific relationships.';
COMMENT ON COLUMN public.relationship_milestones.relationship_id IS 'Reference to the specific relationship.';
COMMENT ON COLUMN public.relationship_milestones.milestone_id IS 'Reference to the achieved milestone.';
COMMENT ON COLUMN public.relationship_milestones.achieved_date IS 'Date when the milestone was achieved.';
COMMENT ON COLUMN public.relationship_milestones.evidence_url IS 'Optional URL to evidence of milestone achievement.';
COMMENT ON COLUMN public.relationship_milestones.evidence_description IS 'Description of the milestone achievement evidence.';

COMMIT; 