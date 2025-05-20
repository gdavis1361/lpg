-- 20240603000000_relationships.sql
-- Prerequisites: 
--   - 20240601010000_core_foundation.sql (for people table)
--   - 20240602000000_relationship_types.sql (for relationship_types table)
-- Purpose: Creates the relationships table with status field and immediate RLS.

BEGIN;

-- Create relationships table 
CREATE TABLE IF NOT EXISTS public.relationships (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_person_id UUID NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  to_person_id   UUID NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  relationship_type_id UUID NOT NULL REFERENCES public.relationship_types(id),
  relationship_type TEXT, -- Legacy field for backward compatibility
  start_date     DATE DEFAULT CURRENT_DATE,
  end_date       DATE,
  status         TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'potential', 'archived')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by     UUID REFERENCES public.people(id),
  notes          TEXT,
  strength_score INT,
  metadata       JSONB DEFAULT '{}'::JSONB,
  CONSTRAINT no_self_relationships CHECK (from_person_id <> to_person_id)
);

-- Create partial unique index enforcing one active relationship of each type
CREATE UNIQUE INDEX uniq_active_relationship
  ON relationships (from_person_id, to_person_id, relationship_type_id)
  WHERE status = 'active' AND end_date IS NULL;

-- Create indexes for relationships
CREATE INDEX idx_relationships_from ON relationships(from_person_id);
CREATE INDEX idx_relationships_to ON relationships(to_person_id);
CREATE INDEX idx_relationships_type ON relationships(relationship_type_id);
CREATE INDEX idx_relationships_status ON relationships(status);

-- Automatically set updated_at on UPDATE
CREATE TRIGGER set_relationships_updated_at
  BEFORE UPDATE ON public.relationships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply RLS immediately
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for relationships
CREATE POLICY "relationships_read_self" ON public.relationships
  FOR SELECT USING (
    -- People can view relationships they're part of
    from_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid()) OR
    to_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid()) OR
    -- Or if they're an admin
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "relationships_insert_self" ON public.relationships
  FOR INSERT WITH CHECK (
    -- People can only create relationships where they are the from_person
    from_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid()) OR
    -- Or if they're an admin
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "relationships_update_self" ON public.relationships
  FOR UPDATE USING (
    -- People can only update relationships they're part of
    from_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid()) OR
    -- Or if they're an admin
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

CREATE POLICY "relationships_delete_admin" ON public.relationships
  FOR DELETE USING (
    -- Only admins can delete relationships
    EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND (roles.name = 'admin' OR roles.name = 'staff')
    )
  );

COMMENT ON TABLE public.relationships IS 'Defines relationships between people in the system.';
COMMENT ON COLUMN public.relationships.from_person_id IS 'The person initiating or from whom the relationship is viewed.';
COMMENT ON COLUMN public.relationships.to_person_id IS 'The person to whom the relationship is directed.';
COMMENT ON COLUMN public.relationships.relationship_type_id IS 'Reference to the type of relationship (FK to relationship_types).';
COMMENT ON COLUMN public.relationships.relationship_type IS 'Legacy field for backward compatibility.';
COMMENT ON COLUMN public.relationships.status IS 'Current status of the relationship (active, inactive, potential, archived).';
COMMENT ON COLUMN public.relationships.strength_score IS 'Calculated or manually entered strength score for the relationship.';

COMMIT; 