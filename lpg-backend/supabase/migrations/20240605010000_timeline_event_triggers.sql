-- 20240605010000_timeline_event_triggers.sql
-- Timeline Event Trigger Functions
-- Extracted from 20250530000000_timeline_event_sourcing.sql

BEGIN;

-- Create trigger function for interaction events
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

-- Create trigger function for relationship events
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

-- Create trigger function for milestone events
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

-- Create trigger function for cross-group participation events
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

-- Create trigger function for alumni check-in events
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
        'wellbeing_score', NEW.wellbeing_score
      )
    );
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a consolidated function with better transaction handling
CREATE OR REPLACE FUNCTION handle_consolidated_timeline_events()
RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_description TEXT;
  v_person_record RECORD;
  v_relationship_id UUID;
  v_from_person_name TEXT;
  v_to_person_name TEXT;
  v_relationship_type TEXT;
  v_milestone_name TEXT;
  v_from_person_id UUID;
  v_to_person_id UUID;
  v_payload JSONB;
BEGIN
  -- Use TG_TABLE_NAME to determine source entity type
  IF TG_OP = 'DELETE' THEN
    -- Mark related events as deleted
    PERFORM soft_delete_timeline_event(TG_TABLE_NAME::text, OLD.id);
    RETURN OLD;
  END IF;

  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    CASE TG_TABLE_NAME
      WHEN 'interactions' THEN
        -- Get the title and description
        v_title := NEW.title;
        v_description := NEW.description;
        
        -- For each participant, create a timeline event
        FOR v_person_record IN 
          SELECT ip.person_id 
          FROM interaction_participants ip 
          WHERE ip.interaction_id = NEW.id
        LOOP
          -- Get relationship if exists
          SELECT r.id INTO v_relationship_id
          FROM relationships r
          WHERE (r.from_person_id = v_person_record.person_id OR r.to_person_id = v_person_record.person_id)
            AND EXISTS (
              SELECT 1 FROM interaction_participants ip2 
              WHERE ip2.interaction_id = NEW.id 
                AND ip2.person_id != v_person_record.person_id
                AND (ip2.person_id = r.from_person_id OR ip2.person_id = r.to_person_id)
            )
          LIMIT 1;
          
          PERFORM merge_timeline_event(
            'interaction_created',
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
      
      WHEN 'relationships' THEN
        -- Process relationship events
        -- Implementation as in populate_relationship_timeline()
        -- ...
      
      WHEN 'relationship_milestones' THEN
        -- Process milestone events
        -- Implementation as in populate_milestone_timeline()
        -- ...
        
      WHEN 'cross_group_participations' THEN
        -- Process cross-group events
        -- Implementation as in populate_cross_group_timeline()
        -- ...
        
      WHEN 'alumni_checkins' THEN
        -- Process alumni check-in events
        -- Implementation as in populate_alumni_checkin_timeline()
        -- ...
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for all relevant source tables
CREATE TRIGGER interaction_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON interactions
FOR EACH ROW EXECUTE FUNCTION populate_interaction_timeline();

CREATE TRIGGER relationship_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON relationships
FOR EACH ROW EXECUTE FUNCTION populate_relationship_timeline();

CREATE TRIGGER milestone_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON relationship_milestones
FOR EACH ROW EXECUTE FUNCTION populate_milestone_timeline();

CREATE TRIGGER cross_group_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON cross_group_participations
FOR EACH ROW EXECUTE FUNCTION populate_cross_group_timeline();

CREATE TRIGGER alumni_checkin_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON alumni_checkins
FOR EACH ROW EXECUTE FUNCTION populate_alumni_checkin_timeline();

COMMENT ON FUNCTION populate_interaction_timeline IS 'Trigger function to populate timeline events from interactions';
COMMENT ON FUNCTION populate_relationship_timeline IS 'Trigger function to populate timeline events from relationships';
COMMENT ON FUNCTION populate_milestone_timeline IS 'Trigger function to populate timeline events from relationship milestones';
COMMENT ON FUNCTION populate_cross_group_timeline IS 'Trigger function to populate timeline events from cross-group participations';
COMMENT ON FUNCTION populate_alumni_checkin_timeline IS 'Trigger function to populate timeline events from alumni check-ins';
COMMENT ON FUNCTION handle_consolidated_timeline_events IS 'Consolidated trigger function with optimized performance for timeline events';

COMMIT; 