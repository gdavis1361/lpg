-- Migration: 20250530000000_timeline_event_sourcing.sql
-- Purpose: Implements a centralized event log table for relationship timelines.

-- 1. Create timeline_events table
CREATE TABLE IF NOT EXISTS public.timeline_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL,                           -- e.g., 'interaction_created', 'relationship_started', 'milestone_achieved'
  event_date TIMESTAMPTZ NOT NULL,                    -- Timestamp of when the actual event occurred
  event_title TEXT NOT NULL,                          -- A concise title for the event
  event_description TEXT,                             -- More detailed description of the event
  person_id UUID REFERENCES public.people(id) ON DELETE CASCADE, -- The primary person this event entry is for
  relationship_id UUID REFERENCES public.relationships(id) ON DELETE SET NULL, -- Associated relationship, if applicable
  source_entity_type TEXT NOT NULL,                   -- The type of the source entity (e.g., 'interactions', 'relationships')
  source_entity_id UUID NOT NULL,                     -- The ID of the record in the source table
  payload JSONB,                                      -- Additional context-specific data for the event
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),      -- When this timeline_event record was created
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),      -- When this record was last updated
  is_deleted BOOLEAN DEFAULT FALSE,                   -- Soft delete flag
  UNIQUE(source_entity_type, source_entity_id, event_type, person_id) -- Ensures no duplicate events for same entity/type/person
);

-- 2. Create indexes for efficient querying
CREATE INDEX idx_timeline_events_person_date ON timeline_events(person_id, event_date DESC);
CREATE INDEX idx_timeline_events_relationship_date ON timeline_events(relationship_id, event_date DESC);
CREATE INDEX idx_timeline_events_source ON timeline_events(source_entity_type, source_entity_id);
CREATE INDEX idx_timeline_events_type_date ON timeline_events(event_type, event_date DESC);
CREATE INDEX idx_timeline_events_active ON timeline_events(source_entity_type, source_entity_id) WHERE NOT is_deleted;

-- 3. Create function to handle event modifications
CREATE OR REPLACE FUNCTION merge_timeline_event(
  p_event_type TEXT,
  p_event_date TIMESTAMPTZ,
  p_event_title TEXT,
  p_event_description TEXT,
  p_person_id UUID,
  p_relationship_id UUID,
  p_source_entity_type TEXT,
  p_source_entity_id UUID,
  p_payload JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_event_id UUID;
BEGIN
  -- Try to find an existing event of this type for this entity and person
  SELECT id INTO v_event_id
  FROM timeline_events
  WHERE source_entity_type = p_source_entity_type
    AND source_entity_id = p_source_entity_id
    AND event_type = p_event_type
    AND person_id = p_person_id
    AND NOT is_deleted;
  
  -- If event exists, update it
  IF v_event_id IS NOT NULL THEN
    UPDATE timeline_events
    SET event_date = p_event_date,
        event_title = p_event_title,
        event_description = p_event_description,
        relationship_id = p_relationship_id,
        payload = p_payload,
        updated_at = NOW()
    WHERE id = v_event_id;
    
    RETURN v_event_id;
  ELSE
    -- Otherwise insert a new event
    INSERT INTO timeline_events (
      event_type,
      event_date,
      event_title,
      event_description,
      person_id,
      relationship_id,
      source_entity_type,
      source_entity_id,
      payload
    ) VALUES (
      p_event_type,
      p_event_date,
      p_event_title,
      p_event_description,
      p_person_id,
      p_relationship_id,
      p_source_entity_type,
      p_source_entity_id,
      p_payload
    )
    RETURNING id INTO v_event_id;
    
    RETURN v_event_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. Create function to mark event as deleted
CREATE OR REPLACE FUNCTION soft_delete_timeline_event(
  p_source_entity_type TEXT,
  p_source_entity_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE timeline_events
  SET is_deleted = TRUE,
      updated_at = NOW()
  WHERE source_entity_type = p_source_entity_type
    AND source_entity_id = p_source_entity_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Create function to populate timeline from interaction events
CREATE OR REPLACE FUNCTION populate_interaction_timeline() RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_description TEXT;
  v_person_record RECORD;
  v_relationship_id UUID;
BEGIN
  -- Determine event type based on operation
  IF TG_OP = 'DELETE' THEN
    -- Mark related events as deleted for deleted interactions
    PERFORM soft_delete_timeline_event('interaction', OLD.id);
    RETURN OLD;
  END IF;
  
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    -- Get the title and description
    v_title := NEW.title;
    v_description := NEW.description;
    
    -- For each participant, create a timeline event
    FOR v_person_record IN 
      SELECT ip.person_id 
      FROM interaction_participants ip 
      WHERE ip.interaction_id = NEW.id
    LOOP
      -- Try to determine the relationship_id
      -- If the interaction has exactly two participants who have a relationship
      SELECT r.id INTO v_relationship_id
      FROM relationships r
      JOIN interaction_participants ip1 ON ip1.person_id = r.from_person_id
      JOIN interaction_participants ip2 ON ip2.person_id = r.to_person_id
      WHERE ip1.interaction_id = NEW.id
        AND ip2.interaction_id = NEW.id
        AND (r.from_person_id = v_person_record.person_id OR r.to_person_id = v_person_record.person_id)
        AND r.status = 'active'
      LIMIT 1;
      
      -- Create or update the timeline event
      PERFORM merge_timeline_event(
        'interaction',
        NEW.start_time,
        v_title,
        v_description,
        v_person_record.person_id,
        v_relationship_id,
        'interaction',
        NEW.id,
        jsonb_build_object(
          'location', NEW.location,
          'interaction_type', NEW.interaction_type,
          'duration_minutes', EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time))/60
        )
      );
    END LOOP;
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 6. Create function to populate timeline from relationship events
CREATE OR REPLACE FUNCTION populate_relationship_timeline() RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_description TEXT;
  v_from_person_name TEXT;
  v_to_person_name TEXT;
  v_relationship_type TEXT;
BEGIN
  -- Determine event type based on operation
  IF TG_OP = 'DELETE' THEN
    -- Mark related events as deleted for deleted relationships
    PERFORM soft_delete_timeline_event('relationship', OLD.id);
    RETURN OLD;
  END IF;
  
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    -- Get names and relationship type for the title/description
    SELECT 
      CONCAT(p1.first_name, ' ', p1.last_name),
      CONCAT(p2.first_name, ' ', p2.last_name),
      rt.name
    INTO 
      v_from_person_name,
      v_to_person_name,
      v_relationship_type
    FROM people p1, people p2, relationship_types rt
    WHERE p1.id = NEW.from_person_id
      AND p2.id = NEW.to_person_id
      AND rt.id = NEW.relationship_type_id;
    
    -- Set title and description based on operation
    IF TG_OP = 'INSERT' THEN
      v_title := 'Relationship established: ' || v_relationship_type;
      v_description := v_from_person_name || ' and ' || v_to_person_name || ' established a ' || v_relationship_type || ' relationship';
    ELSIF TG_OP = 'UPDATE' AND NEW.status != OLD.status THEN
      v_title := 'Relationship status changed to: ' || NEW.status;
      v_description := 'The ' || v_relationship_type || ' relationship between ' || v_from_person_name || ' and ' || v_to_person_name || ' changed status to ' || NEW.status;
    ELSE
      -- Skip other updates that don't change status
      RETURN NEW;
    END IF;
    
    -- Create or update the timeline event for the "from" person
    PERFORM merge_timeline_event(
      CASE 
        WHEN TG_OP = 'INSERT' THEN 'relationship_created'
        ELSE 'relationship_updated'
      END,
      NEW.created_at,
      v_title,
      v_description,
      NEW.from_person_id,
      NEW.id,
      'relationship',
      NEW.id,
      jsonb_build_object(
        'status', NEW.status,
        'relationship_type', v_relationship_type
      )
    );
    
    -- Create or update the timeline event for the "to" person
    PERFORM merge_timeline_event(
      CASE 
        WHEN TG_OP = 'INSERT' THEN 'relationship_created'
        ELSE 'relationship_updated'
      END,
      NEW.created_at,
      v_title,
      v_description,
      NEW.to_person_id,
      NEW.id,
      'relationship',
      NEW.id,
      jsonb_build_object(
        'status', NEW.status,
        'relationship_type', v_relationship_type
      )
    );
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 7. Create function to populate timeline from milestone events
CREATE OR REPLACE FUNCTION populate_milestone_timeline() RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_description TEXT;
  v_milestone_name TEXT;
  v_from_person_id UUID;
  v_to_person_id UUID;
BEGIN
  -- Determine event type based on operation
  IF TG_OP = 'DELETE' THEN
    -- Mark related events as deleted for deleted milestones
    PERFORM soft_delete_timeline_event('milestone', OLD.id);
    RETURN OLD;
  END IF;
  
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    -- Get milestone name and relationship persons
    SELECT 
      mm.name,
      r.from_person_id,
      r.to_person_id
    INTO 
      v_milestone_name,
      v_from_person_id,
      v_to_person_id
    FROM mentor_milestones mm
    JOIN relationships r ON r.id = NEW.relationship_id
    WHERE mm.id = NEW.milestone_id;
    
    -- Set title and description
    v_title := 'Milestone achieved: ' || v_milestone_name;
    v_description := v_milestone_name || ' milestone achieved on ' || to_char(NEW.achieved_date, 'YYYY-MM-DD');
    IF NEW.notes IS NOT NULL AND NEW.notes != '' THEN
      v_description := v_description || '. ' || NEW.notes;
    END IF;
    
    -- Create or update the timeline event for the mentor (from_person)
    PERFORM merge_timeline_event(
      'milestone',
      NEW.achieved_date,
      v_title,
      v_description,
      v_from_person_id,
      NEW.relationship_id,
      'milestone',
      NEW.id,
      jsonb_build_object(
        'milestone_name', v_milestone_name,
        'evidence_url', NEW.evidence_url
      )
    );
    
    -- Create or update the timeline event for the student (to_person)
    PERFORM merge_timeline_event(
      'milestone',
      NEW.achieved_date,
      v_title,
      v_description,
      v_to_person_id,
      NEW.relationship_id,
      'milestone',
      NEW.id,
      jsonb_build_object(
        'milestone_name', v_milestone_name,
        'evidence_url', NEW.evidence_url
      )
    );
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 8. Create function to populate timeline from cross-group participation events
CREATE OR REPLACE FUNCTION populate_cross_group_timeline() RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_description TEXT;
  v_group_name TEXT;
BEGIN
  -- Determine event type based on operation
  IF TG_OP = 'DELETE' THEN
    -- Mark related events as deleted for deleted participations
    PERFORM soft_delete_timeline_event('cross_group', OLD.id);
    RETURN OLD;
  END IF;
  
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    -- Get visited group name
    SELECT name INTO v_group_name
    FROM activity_groups
    WHERE id = NEW.visited_activity_id;
    
    -- Set title and description
    v_title := 'Cross-group participation: ' || v_group_name;
    v_description := COALESCE(NEW.event_description, 'Participated in ' || v_group_name || ' activity');
    
    -- Create or update the timeline event
    PERFORM merge_timeline_event(
      'cross_group',
      NEW.event_date,
      v_title,
      v_description,
      NEW.person_id,
      NULL, -- No specific relationship
      'cross_group',
      NEW.id,
      jsonb_build_object(
        'home_activity_id', NEW.home_activity_id,
        'visited_activity_id', NEW.visited_activity_id
      )
    );
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 9. Create function to populate timeline from alumni check-in events
CREATE OR REPLACE FUNCTION populate_alumni_checkin_timeline() RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_description TEXT;
BEGIN
  -- Determine event type based on operation
  IF TG_OP = 'DELETE' THEN
    -- Mark related events as deleted for deleted check-ins
    PERFORM soft_delete_timeline_event('alumni_checkin', OLD.id);
    RETURN OLD;
  END IF;
  
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    -- Set title and description
    v_title := 'Alumni check-in';
    v_description := 'Alumni check-in via ' || NEW.check_method || ': ' || COALESCE(NEW.status_update, '');
    
    -- Create or update the timeline event
    PERFORM merge_timeline_event(
      'alumni_checkin',
      NEW.check_date,
      v_title,
      v_description,
      NEW.alumni_id,
      NULL, -- No specific relationship
      'alumni_checkin',
      NEW.id,
      jsonb_build_object(
        'check_method', NEW.check_method,
        'support_needed', NEW.support_needed
      )
    );
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 10. Create triggers for all relevant source tables
DROP TRIGGER IF EXISTS interaction_timeline_trigger ON interactions;
CREATE TRIGGER interaction_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON interactions
FOR EACH ROW EXECUTE FUNCTION populate_interaction_timeline();

DROP TRIGGER IF EXISTS relationship_timeline_trigger ON relationships;
CREATE TRIGGER relationship_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON relationships
FOR EACH ROW EXECUTE FUNCTION populate_relationship_timeline();

DROP TRIGGER IF EXISTS milestone_timeline_trigger ON relationship_milestones;
CREATE TRIGGER milestone_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON relationship_milestones
FOR EACH ROW EXECUTE FUNCTION populate_milestone_timeline();

DROP TRIGGER IF EXISTS cross_group_timeline_trigger ON cross_group_participations;
CREATE TRIGGER cross_group_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON cross_group_participations
FOR EACH ROW EXECUTE FUNCTION populate_cross_group_timeline();

DROP TRIGGER IF EXISTS alumni_checkin_timeline_trigger ON alumni_checkins;
CREATE TRIGGER alumni_checkin_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON alumni_checkins
FOR EACH ROW EXECUTE FUNCTION populate_alumni_checkin_timeline();

-- 11. Create a function to backfill timeline data from existing records
CREATE OR REPLACE FUNCTION backfill_timeline_events() 
RETURNS TABLE (entity_type TEXT, records_processed INTEGER) AS $$
DECLARE
  interaction_count INTEGER := 0;
  relationship_count INTEGER := 0;
  milestone_count INTEGER := 0;
  cross_group_count INTEGER := 0;
  alumni_checkin_count INTEGER := 0;
  r RECORD;
BEGIN
  -- First clean up any existing timeline events to avoid duplicates
  DELETE FROM timeline_events;
  
  -- Backfill interactions
  FOR r IN SELECT * FROM interactions ORDER BY created_at LOOP
    PERFORM populate_interaction_timeline_for_record(r);
    interaction_count := interaction_count + 1;
  END LOOP;
  
  -- Backfill relationships
  FOR r IN SELECT * FROM relationships ORDER BY created_at LOOP
    PERFORM populate_relationship_timeline_for_record(r);
    relationship_count := relationship_count + 1;
  END LOOP;
  
  -- Backfill milestones
  FOR r IN SELECT * FROM relationship_milestones ORDER BY created_at LOOP
    PERFORM populate_milestone_timeline_for_record(r);
    milestone_count := milestone_count + 1;
  END LOOP;
  
  -- Backfill cross-group participations
  FOR r IN SELECT * FROM cross_group_participations ORDER BY created_at LOOP
    PERFORM populate_cross_group_timeline_for_record(r);
    cross_group_count := cross_group_count + 1;
  END LOOP;
  
  -- Backfill alumni check-ins
  FOR r IN SELECT * FROM alumni_checkins ORDER BY created_at LOOP
    PERFORM populate_alumni_checkin_timeline_for_record(r);
    alumni_checkin_count := alumni_checkin_count + 1;
  END LOOP;
  
  -- Return summary of processed records
  RETURN QUERY 
    SELECT 'interactions'::TEXT, interaction_count
    UNION ALL SELECT 'relationships'::TEXT, relationship_count
    UNION ALL SELECT 'milestones'::TEXT, milestone_count
    UNION ALL SELECT 'cross_group'::TEXT, cross_group_count
    UNION ALL SELECT 'alumni_checkins'::TEXT, alumni_checkin_count;
END;
$$ LANGUAGE plpgsql;

-- 12. Create helper functions for backfill process
CREATE OR REPLACE FUNCTION populate_interaction_timeline_for_record(r interactions) 
RETURNS VOID AS $$
BEGIN
  -- Set NEW to the record and simulate INSERT
  PERFORM populate_interaction_timeline() 
  FROM (SELECT 'INSERT'::TEXT AS op, r AS old, r AS new) AS trigger_info
  WHERE trigger_info.op = 'INSERT';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION populate_relationship_timeline_for_record(r relationships) 
RETURNS VOID AS $$
BEGIN
  -- Set NEW to the record and simulate INSERT
  PERFORM populate_relationship_timeline() 
  FROM (SELECT 'INSERT'::TEXT AS op, r AS old, r AS new) AS trigger_info
  WHERE trigger_info.op = 'INSERT';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION populate_milestone_timeline_for_record(r relationship_milestones) 
RETURNS VOID AS $$
BEGIN
  -- Set NEW to the record and simulate INSERT
  PERFORM populate_milestone_timeline() 
  FROM (SELECT 'INSERT'::TEXT AS op, r AS old, r AS new) AS trigger_info
  WHERE trigger_info.op = 'INSERT';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION populate_cross_group_timeline_for_record(r cross_group_participations) 
RETURNS VOID AS $$
BEGIN
  -- Set NEW to the record and simulate INSERT
  PERFORM populate_cross_group_timeline() 
  FROM (SELECT 'INSERT'::TEXT AS op, r AS old, r AS new) AS trigger_info
  WHERE trigger_info.op = 'INSERT';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION populate_alumni_checkin_timeline_for_record(r alumni_checkins) 
RETURNS VOID AS $$
BEGIN
  -- Set NEW to the record and simulate INSERT
  PERFORM populate_alumni_checkin_timeline() 
  FROM (SELECT 'INSERT'::TEXT AS op, r AS old, r AS new) AS trigger_info
  WHERE trigger_info.op = 'INSERT';
END;
$$ LANGUAGE plpgsql;

-- 13. Create view for relationship timeline based on the new architecture
CREATE OR REPLACE VIEW relationship_timeline_unified AS
SELECT
  te.id,
  te.event_type,
  te.event_date,
  te.event_title,
  te.event_description,
  te.person_id,
  p.first_name || ' ' || p.last_name AS person_name,
  te.relationship_id,
  r.from_person_id,
  r.to_person_id,
  p_from.first_name || ' ' || p_from.last_name AS from_person_name,
  p_to.first_name || ' ' || p_to.last_name AS to_person_name,
  rt.name AS relationship_type_name,
  te.source_entity_type,
  te.source_entity_id,
  te.payload,
  te.created_at
FROM timeline_events te
LEFT JOIN people p ON te.person_id = p.id
LEFT JOIN relationships r ON te.relationship_id = r.id
LEFT JOIN people p_from ON r.from_person_id = p_from.id
LEFT JOIN people p_to ON r.to_person_id = p_to.id
LEFT JOIN relationship_types rt ON r.relationship_type_id = rt.id
WHERE NOT te.is_deleted
ORDER BY te.event_date DESC;

-- 14. Backfill the timeline events table with existing data (commented out for safety)
-- To execute the backfill, run this command after reviewing the migration:
-- SELECT * FROM backfill_timeline_events();

COMMENT ON TABLE timeline_events IS 'Centralized timeline events table for tracking all relationship-related activities';
COMMENT ON FUNCTION merge_timeline_event IS 'Upserts a timeline event, merging with existing events of the same type/entity/person';
COMMENT ON FUNCTION soft_delete_timeline_event IS 'Marks timeline events as deleted without physically removing them';
COMMENT ON FUNCTION backfill_timeline_events IS 'Populates timeline_events with historical data from all source tables';
COMMENT ON VIEW relationship_timeline_unified IS 'Unified view of all timeline events with enriched relationship context';
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()       -- When this timeline_event record was last updated
);

COMMENT ON TABLE public.timeline_events IS 'Centralized table for storing various types of events related to people and relationships to build timelines.';
COMMENT ON COLUMN public.timeline_events.person_id IS 'The person this specific timeline entry is associated with. An event involving two people might have two entries.';
COMMENT ON COLUMN public.timeline_events.relationship_id IS 'If the event is specific to a relationship, this links to it.';
COMMENT ON COLUMN public.timeline_events.source_entity_type IS 'Name of the table from which this event originated (e.g., ''interactions'', ''relationships'').';
COMMENT ON COLUMN public.timeline_events.source_entity_id IS 'Primary key of the record in the source table.';
COMMENT ON COLUMN public.timeline_events.payload IS 'Stores additional event-specific data not fitting other columns.';

-- Automatically bump updated_at on UPDATE for timeline_events.
CREATE OR REPLACE FUNCTION update_timeline_events_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timeline_events_updated_at
  BEFORE UPDATE ON public.timeline_events
  FOR EACH ROW EXECUTE FUNCTION update_timeline_events_updated_at_column();

-- 2. Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_timeline_events_person_date ON public.timeline_events(person_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_timeline_events_relationship_date ON public.timeline_events(relationship_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_timeline_events_source ON public.timeline_events(source_entity_type, source_entity_id);
CREATE INDEX IF NOT EXISTS idx_timeline_events_event_type_date ON public.timeline_events(event_type, event_date DESC);

-- 3. Trigger function to populate timeline_events
CREATE OR REPLACE FUNCTION public.populate_timeline_from_source()
RETURNS TRIGGER AS $$
DECLARE
  evt_title TEXT;
  evt_desc TEXT;
  evt_payload JSONB;
  rel_people RECORD;
  participant_id UUID;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Handle 'interactions' table
    IF TG_TABLE_NAME = 'interactions' THEN
      evt_title := COALESCE(NEW.title, 'Interaction');
      evt_desc := NEW.description;
      evt_payload := jsonb_build_object(
        'duration_minutes', NEW.duration_minutes,
        'location', NEW.location,
        'interaction_type', NEW.interaction_type,
        'follow_up_needed', NEW.follow_up_needed
      );

      -- Create an event for each participant
      FOR participant_id IN SELECT ip.person_id FROM public.interaction_participants ip WHERE ip.interaction_id = NEW.id LOOP
        INSERT INTO public.timeline_events (
          event_type, event_date, event_title, event_description, person_id,
          source_entity_type, source_entity_id, payload
        ) VALUES (
          'interaction_created', NEW.occurred_at, evt_title, evt_desc, participant_id,
          'interactions', NEW.id, evt_payload
        );
      END LOOP;

    -- Handle 'relationships' table
    ELSIF TG_TABLE_NAME = 'relationships' THEN
      SELECT COALESCE(rt.name, NEW.relationship_type::TEXT, 'Unknown Type') INTO evt_title
      FROM public.relationship_types rt WHERE rt.id = NEW.relationship_type_id;
      IF evt_title IS NULL THEN -- Fallback if relationship_type_id is not used or not found
          evt_title := NEW.relationship_type::TEXT;
      END IF;

      evt_desc := 'New ' || evt_title || ' relationship started.';
      evt_payload := jsonb_build_object('status', NEW.status, 'start_date', NEW.start_date);

      -- Event for the 'from_person'
      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id, relationship_id,
        source_entity_type, source_entity_id, payload
      ) VALUES (
        'relationship_started', NEW.created_at, 'Relationship with ' || (SELECT p.first_name || ' ' || p.last_name FROM public.people p WHERE p.id = NEW.to_person_id), evt_desc, NEW.from_person_id, NEW.id,
        'relationships', NEW.id, evt_payload
      );
      -- Event for the 'to_person'
      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id, relationship_id,
        source_entity_type, source_entity_id, payload
      ) VALUES (
        'relationship_started', NEW.created_at, 'Relationship with ' || (SELECT p.first_name || ' ' || p.last_name FROM public.people p WHERE p.id = NEW.from_person_id), evt_desc, NEW.to_person_id, NEW.id,
        'relationships', NEW.id, evt_payload
      );

    -- Handle 'relationship_milestones' table
    ELSIF TG_TABLE_NAME = 'relationship_milestones' THEN
      SELECT mm.name, mm.description, r.from_person_id, r.to_person_id
      INTO evt_title, evt_desc, rel_people.from_person_id, rel_people.to_person_id
      FROM public.mentor_milestones mm
      JOIN public.relationships r ON r.id = NEW.relationship_id
      WHERE mm.id = NEW.milestone_id;

      evt_payload := jsonb_build_object('notes', NEW.notes, 'evidence_url', NEW.evidence_url);

      -- Event for 'from_person' in relationship
      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id, relationship_id,
        source_entity_type, source_entity_id, payload
      ) VALUES (
        'milestone_achieved', NEW.achieved_date, evt_title, evt_desc, rel_people.from_person_id, NEW.relationship_id,
        'relationship_milestones', NEW.id, evt_payload || jsonb_build_object('milestone_id', NEW.milestone_id)
      );
      -- Event for 'to_person' in relationship
      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id, relationship_id,
        source_entity_type, source_entity_id, payload
      ) VALUES (
        'milestone_achieved', NEW.achieved_date, evt_title, evt_desc, rel_people.to_person_id, NEW.relationship_id,
        'relationship_milestones', NEW.id, evt_payload || jsonb_build_object('milestone_id', NEW.milestone_id)
      );

    -- Handle 'cross_group_participations' table
    ELSIF TG_TABLE_NAME = 'cross_group_participations' THEN
      SELECT 'Visited ' || visited_ag.name || ' (from ' || home_ag.name || ')'
      INTO evt_title
      FROM public.activity_groups visited_ag, public.activity_groups home_ag
      WHERE visited_ag.id = NEW.visited_activity_id AND home_ag.id = NEW.home_activity_id;

      evt_desc := NEW.event_description;
      evt_payload := jsonb_build_object('recognition_points', NEW.recognition_points);

      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id,
        source_entity_type, source_entity_id, payload
      ) VALUES (
        'cross_group_participation', NEW.event_date, 'Cross-group: ' || evt_title, evt_desc, NEW.person_id,
        'cross_group_participations', NEW.id, evt_payload
      );

    -- Handle 'alumni_checkins' table
    ELSIF TG_TABLE_NAME = 'alumni_checkins' THEN
      evt_title := 'Alumni Check-in via ' || NEW.check_method;
      evt_desc := NEW.status_update;
      evt_payload := jsonb_build_object('wellbeing_score', NEW.wellbeing_score, 'needs_followup', NEW.needs_followup);

      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id,
        source_entity_type, source_entity_id, payload
      ) VALUES (
        'alumni_checkin', NEW.check_date, evt_title, evt_desc, NEW.alumni_id,
        'alumni_checkins', NEW.id, evt_payload
      );
    END IF;
  -- ELSIF (TG_OP = 'UPDATE') THEN
    -- Consider logic for updates, e.g., 'relationship_status_changed', 'interaction_details_updated'
    -- This might involve creating new events or, more complexly, updating existing ones.
    -- For simplicity, initial focus is on INSERTs.
  -- ELSIF (TG_OP = 'DELETE') THEN
    -- Consider logic for deletes, e.g., 'relationship_ended', 'interaction_deleted'
    -- This might involve creating a new event indicating the deletion.
  END IF;
  RETURN NULL; -- Trigger function returns NULL as it's an AFTER trigger not modifying the row.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.populate_timeline_from_source() IS 'Trigger function to populate the timeline_events table based on operations on source tables.';

-- 4. Create triggers for relevant source tables
-- Note: Ensure these tables exist before creating triggers.
-- Order of creation might matter if tables are created in the same overall transaction.

CREATE TRIGGER trigger_interactions_to_timeline
AFTER INSERT ON public.interactions
FOR EACH ROW EXECUTE FUNCTION public.populate_timeline_from_source();

CREATE TRIGGER trigger_relationships_to_timeline
AFTER INSERT ON public.relationships
FOR EACH ROW EXECUTE FUNCTION public.populate_timeline_from_source();

CREATE TRIGGER trigger_relationship_milestones_to_timeline
AFTER INSERT ON public.relationship_milestones
FOR EACH ROW EXECUTE FUNCTION public.populate_timeline_from_source();

CREATE TRIGGER trigger_cross_group_participations_to_timeline
AFTER INSERT ON public.cross_group_participations
FOR EACH ROW EXECUTE FUNCTION public.populate_timeline_from_source();

CREATE TRIGGER trigger_alumni_checkins_to_timeline
AFTER INSERT ON public.alumni_checkins
FOR EACH ROW EXECUTE FUNCTION public.populate_timeline_from_source();

-- Add more triggers for other relevant tables or operations (UPDATE, DELETE) as needed.

-- 5. Backfilling Historical Data (Manual Step or Separate Script)
-- Triggers only capture new events. Existing data needs to be backfilled.
-- This is a one-time operation and should be run carefully.
-- Example (conceptual - to be run as a separate script or one-off function call):
/*
CREATE OR REPLACE FUNCTION backfill_all_timeline_events()
RETURNS VOID AS $$
DECLARE
  interaction_record RECORD;
  relationship_record RECORD;
  milestone_record RECORD;
  cross_group_record RECORD;
  alumni_checkin_record RECORD;
  participant_id UUID;
  evt_title TEXT;
  evt_desc TEXT;
  evt_payload JSONB;
  rel_people RECORD;
BEGIN
  RAISE NOTICE 'Starting timeline events backfill...';

  -- Backfill from interactions
  RAISE NOTICE 'Backfilling interactions...';
  FOR interaction_record IN SELECT * FROM public.interactions LOOP
    evt_title := COALESCE(interaction_record.title, 'Interaction');
    evt_desc := interaction_record.description;
    evt_payload := jsonb_build_object(
      'duration_minutes', interaction_record.duration_minutes,
      'location', interaction_record.location,
      'interaction_type', interaction_record.interaction_type,
      'follow_up_needed', interaction_record.follow_up_needed
    );
    FOR participant_id IN SELECT ip.person_id FROM public.interaction_participants ip WHERE ip.interaction_id = interaction_record.id LOOP
      INSERT INTO public.timeline_events (
        event_type, event_date, event_title, event_description, person_id,
        source_entity_type, source_entity_id, payload, created_at, updated_at
      ) VALUES (
        'interaction_created', interaction_record.occurred_at, evt_title, evt_desc, participant_id,
        'interactions', interaction_record.id, evt_payload, interaction_record.created_at, interaction_record.updated_at
      ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'interaction_created' DO NOTHING; -- Basic idempotency
    END LOOP;
  END LOOP;

  -- Backfill from relationships
  RAISE NOTICE 'Backfilling relationships...';
  FOR relationship_record IN SELECT r.*, rt.name as type_name FROM public.relationships r LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id LOOP
    evt_title := COALESCE(relationship_record.type_name, relationship_record.relationship_type::TEXT, 'Unknown Type');
    evt_desc := 'New ' || evt_title || ' relationship started.';
    evt_payload := jsonb_build_object('status', relationship_record.status, 'start_date', relationship_record.start_date);

    INSERT INTO public.timeline_events (
      event_type, event_date, event_title, event_description, person_id, relationship_id,
      source_entity_type, source_entity_id, payload, created_at, updated_at
    ) VALUES (
      'relationship_started', relationship_record.created_at, 'Relationship with ' || (SELECT p.first_name || ' ' || p.last_name FROM public.people p WHERE p.id = relationship_record.to_person_id), evt_desc, relationship_record.from_person_id, relationship_record.id,
      'relationships', relationship_record.id, evt_payload, relationship_record.created_at, relationship_record.updated_at
    ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'relationship_started' AND person_id = relationship_record.from_person_id DO NOTHING;

    INSERT INTO public.timeline_events (
      event_type, event_date, event_title, event_description, person_id, relationship_id,
      source_entity_type, source_entity_id, payload, created_at, updated_at
    ) VALUES (
      'relationship_started', relationship_record.created_at, 'Relationship with ' || (SELECT p.first_name || ' ' || p.last_name FROM public.people p WHERE p.id = relationship_record.from_person_id), evt_desc, relationship_record.to_person_id, relationship_record.id,
      'relationships', relationship_record.id, evt_payload, relationship_record.created_at, relationship_record.updated_at
    ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'relationship_started' AND person_id = relationship_record.to_person_id DO NOTHING;
  END LOOP;

  -- Backfill from relationship_milestones
  RAISE NOTICE 'Backfilling relationship_milestones...';
  FOR milestone_record IN
    SELECT rm.*, mm.name as milestone_name, mm.description as milestone_desc, r.from_person_id, r.to_person_id
    FROM public.relationship_milestones rm
    JOIN public.mentor_milestones mm ON rm.milestone_id = mm.id
    JOIN public.relationships r ON r.id = rm.relationship_id
  LOOP
    evt_payload := jsonb_build_object('notes', milestone_record.notes, 'evidence_url', milestone_record.evidence_url, 'milestone_id', milestone_record.milestone_id);
    INSERT INTO public.timeline_events (
      event_type, event_date, event_title, event_description, person_id, relationship_id,
      source_entity_type, source_entity_id, payload, created_at, updated_at
    ) VALUES (
      'milestone_achieved', milestone_record.achieved_date, milestone_record.milestone_name, milestone_record.milestone_desc, milestone_record.from_person_id, milestone_record.relationship_id,
      'relationship_milestones', milestone_record.id, evt_payload, milestone_record.created_at, milestone_record.updated_at
    ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'milestone_achieved' AND person_id = milestone_record.from_person_id DO NOTHING;

    INSERT INTO public.timeline_events (
      event_type, event_date, event_title, event_description, person_id, relationship_id,
      source_entity_type, source_entity_id, payload, created_at, updated_at
    ) VALUES (
      'milestone_achieved', milestone_record.achieved_date, milestone_record.milestone_name, milestone_record.milestone_desc, milestone_record.to_person_id, milestone_record.relationship_id,
      'relationship_milestones', milestone_record.id, evt_payload, milestone_record.created_at, milestone_record.updated_at
    ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'milestone_achieved' AND person_id = milestone_record.to_person_id DO NOTHING;
  END LOOP;

  -- Backfill from cross_group_participations
  RAISE NOTICE 'Backfilling cross_group_participations...';
  FOR cross_group_record IN
    SELECT cgp.*, visited_ag.name as visited_name, home_ag.name as home_name
    FROM public.cross_group_participations cgp
    JOIN public.activity_groups visited_ag ON cgp.visited_activity_id = visited_ag.id
    JOIN public.activity_groups home_ag ON cgp.home_activity_id = home_ag.id
  LOOP
    evt_title := 'Cross-group: Visited ' || cross_group_record.visited_name || ' (from ' || cross_group_record.home_name || ')';
    evt_payload := jsonb_build_object('recognition_points', cross_group_record.recognition_points);
    INSERT INTO public.timeline_events (
      event_type, event_date, event_title, event_description, person_id,
      source_entity_type, source_entity_id, payload, created_at, updated_at
    ) VALUES (
      'cross_group_participation', cross_group_record.event_date, evt_title, cross_group_record.event_description, cross_group_record.person_id,
      'cross_group_participations', cross_group_record.id, evt_payload, cross_group_record.created_at, cross_group_record.updated_at
    ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'cross_group_participation' DO NOTHING;
  END LOOP;

  -- Backfill from alumni_checkins
  RAISE NOTICE 'Backfilling alumni_checkins...';
  FOR alumni_checkin_record IN SELECT * FROM public.alumni_checkins LOOP
    evt_title := 'Alumni Check-in via ' || alumni_checkin_record.check_method;
    evt_payload := jsonb_build_object('wellbeing_score', alumni_checkin_record.wellbeing_score, 'needs_followup', alumni_checkin_record.needs_followup);
    INSERT INTO public.timeline_events (
      event_type, event_date, event_title, event_description, person_id,
      source_entity_type, source_entity_id, payload, created_at, updated_at
    ) VALUES (
      'alumni_checkin', alumni_checkin_record.check_date, evt_title, alumni_checkin_record.status_update, alumni_checkin_record.alumni_id,
      'alumni_checkins', alumni_checkin_record.id, evt_payload, alumni_checkin_record.created_at, alumni_checkin_record.updated_at
    ) ON CONFLICT (source_entity_type, source_entity_id, person_id, event_type) WHERE event_type = 'alumni_checkin' DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Timeline events backfill completed.';
END;
$$ LANGUAGE plpgsql;

-- To run the backfill:
-- SELECT backfill_all_timeline_events();
-- Drop the function after use if it's a one-time script:
-- DROP FUNCTION backfill_all_timeline_events();
*/
COMMENT ON FUNCTION public.populate_timeline_from_source() IS 'Trigger function to populate the timeline_events table based on INSERT operations on source tables. Backfill of historical data must be handled separately.';

-- Note: The original `relationship_timeline_events` VIEW (from 20250524010000_relationship_timeline.sql)
-- should eventually be refactored to select from `timeline_events` or dropped if applications query `timeline_events` directly.
