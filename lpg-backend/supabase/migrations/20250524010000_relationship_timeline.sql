-- Prerequisites:
--   - Assumes 'interactions', 'interaction_participants', 'relationships', 'relationship_types',
--     'relationship_milestones', 'mentor_milestones', 'cross_group_participations',
--     'activity_groups', 'alumni_checkins', and 'people' tables/views exist from previous migrations.
-- Purpose: Implements the "Relationship Timeline Migration" by:
--          1. Creating 'relationship_timeline_events' unified view.
--          2. Creating 'person_relationship_timeline' view.
--          3. Creating 'relationship_pair_timeline' view.

-- Create unified relationship events view
CREATE OR REPLACE VIEW public.relationship_timeline_events AS
-- Interaction events: Assumes interactions are linked to people via interaction_participants
SELECT
  i.id AS event_unique_id, -- Use a consistent name for the source ID of the event
  'interaction' AS event_type,
  i.occurred_at AS event_date,
  COALESCE(i.title, 'Interaction') AS event_title,
  i.description AS event_description,
  ip.person_id, -- The person involved in this event entry
  -- For interactions, relationship_id might be harder to directly attribute here
  -- if an interaction can span multiple relationships or none.
  -- This could be enhanced if interactions are directly linked to a relationship.
  NULL::UUID AS relationship_id, 
  NULL::UUID AS milestone_id,
  i.id AS source_table_id, -- ID from the original table (interactions.id)
  'interactions' AS source_table_name,
  i.created_at AS event_record_created_at
FROM public.interactions i
JOIN public.interaction_participants ip ON i.id = ip.interaction_id

UNION ALL

-- Relationship creation events
SELECT
  r.id AS event_unique_id,
  'relationship_created' AS event_type,
  r.created_at AS event_date, -- Event date is the creation of the relationship itself
  'Relationship established: ' || COALESCE(rt.name, r.relationship_type::TEXT, 'Unknown Type') AS event_title,
  'New ' || COALESCE(rt.name, r.relationship_type::TEXT, 'Unknown Type') || ' relationship created' AS event_description,
  r.from_person_id AS person_id, -- Event is for the 'from_person'
  r.id AS relationship_id,
  NULL::UUID AS milestone_id,
  r.id AS source_table_id,
  'relationships' AS source_table_name,
  r.created_at AS event_record_created_at
FROM public.relationships r
LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id -- Assuming relationship_type_id

UNION ALL

-- Second entry for relationship_created for the 'to_person'
SELECT
  r.id AS event_unique_id, -- Same event_unique_id as for the 'from_person'
  'relationship_created' AS event_type,
  r.created_at AS event_date,
  'Relationship established: ' || COALESCE(rt.name, r.relationship_type::TEXT, 'Unknown Type') AS event_title,
  'New ' || COALESCE(rt.name, r.relationship_type::TEXT, 'Unknown Type') || ' relationship created' AS event_description,
  r.to_person_id AS person_id, -- Event is for the 'to_person'
  r.id AS relationship_id,
  NULL::UUID AS milestone_id,
  r.id AS source_table_id,
  'relationships' AS source_table_name,
  r.created_at AS event_record_created_at
FROM public.relationships r
LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id

UNION ALL

-- Relationship milestone events
-- Assumes relationship_milestones links a relationship to a mentor_milestone
-- and the event is relevant to both parties in the relationship.
SELECT
  rm.id AS event_unique_id,
  'milestone_achieved' AS event_type,
  rm.achieved_date AS event_date,
  mm.name AS event_title,
  mm.description AS event_description,
  r.from_person_id AS person_id, -- Event for 'from_person' in relationship
  r.id AS relationship_id,
  mm.id AS milestone_id,
  rm.id AS source_table_id,
  'relationship_milestones' AS source_table_name,
  rm.created_at AS event_record_created_at
FROM public.relationship_milestones rm
JOIN public.relationships r ON rm.relationship_id = r.id
JOIN public.mentor_milestones mm ON rm.milestone_id = mm.id

UNION ALL

-- Second entry for milestone_achieved for the 'to_person'
SELECT
  rm.id AS event_unique_id, -- Same event_unique_id
  'milestone_achieved' AS event_type,
  rm.achieved_date AS event_date,
  mm.name AS event_title,
  mm.description AS event_description,
  r.to_person_id AS person_id, -- Event for 'to_person' in relationship
  r.id AS relationship_id,
  mm.id AS milestone_id,
  rm.id AS source_table_id,
  'relationship_milestones' AS source_table_name,
  rm.created_at AS event_record_created_at
FROM public.relationship_milestones rm
JOIN public.relationships r ON rm.relationship_id = r.id
JOIN public.mentor_milestones mm ON rm.milestone_id = mm.id

UNION ALL

-- Cross-group participation events
SELECT
  cgp.id AS event_unique_id,
  'cross_group_participation' AS event_type,
  cgp.event_date AS event_date,
  'Cross-group participation: Visited ' || visited_ag.name || ' (from ' || home_ag.name || ')' AS event_title,
  cgp.event_description AS event_description,
  cgp.person_id,
  NULL::UUID AS relationship_id, -- Not directly tied to a dyadic relationship
  NULL::UUID AS milestone_id,
  cgp.id AS source_table_id,
  'cross_group_participations' AS source_table_name,
  cgp.created_at AS event_record_created_at
FROM public.cross_group_participations cgp
JOIN public.activity_groups visited_ag ON cgp.visited_activity_id = visited_ag.id
JOIN public.activity_groups home_ag ON cgp.home_activity_id = home_ag.id -- For context in title

UNION ALL

-- Alumni check-in events
SELECT
  ac.id AS event_unique_id,
  'alumni_checkin' AS event_type,
  ac.check_date AS event_date,
  'Alumni check-in' AS event_title,
  'Alumni check-in via ' || ac.check_method || COALESCE(': ' || ac.status_update, '') AS event_description,
  ac.alumni_id AS person_id,
  NULL::UUID AS relationship_id, -- Not directly tied to a dyadic relationship
  NULL::UUID AS milestone_id,
  ac.id AS source_table_id,
  'alumni_checkins' AS source_table_name,
  ac.created_at AS event_record_created_at
FROM public.alumni_checkins ac;

COMMENT ON VIEW public.relationship_timeline_events IS 'Unified view of various events that constitute a relationship or personal timeline.';
COMMENT ON COLUMN public.relationship_timeline_events.event_unique_id IS 'A unique ID for the event instance across different source tables (usually the source table''s primary key).';
COMMENT ON COLUMN public.relationship_timeline_events.event_type IS 'Type of the event (e.g., interaction, relationship_created, milestone_achieved).';
COMMENT ON COLUMN public.relationship_timeline_events.event_date IS 'Date the event occurred or was recorded.';
COMMENT ON COLUMN public.relationship_timeline_events.person_id IS 'ID of the person this event entry pertains to.';
COMMENT ON COLUMN public.relationship_timeline_events.relationship_id IS 'ID of the dyadic relationship this event is part of, if applicable.';
COMMENT ON COLUMN public.relationship_timeline_events.milestone_id IS 'ID of the milestone achieved, if applicable.';
COMMENT ON COLUMN public.relationship_timeline_events.source_table_id IS 'Primary key of the record in the source table.';
COMMENT ON COLUMN public.relationship_timeline_events.source_table_name IS 'Name of the table from which this event originated.';
COMMENT ON COLUMN public.relationship_timeline_events.event_record_created_at IS 'Timestamp when the source record for this event was created.';


-- Create person relationship timeline view
CREATE OR REPLACE VIEW public.person_relationship_timeline AS
SELECT
  p.id AS person_id,
  p.first_name,
  p.last_name,
  e.event_type,
  e.event_date,
  e.event_title,
  e.event_description,
  e.relationship_id, -- The specific relationship involved, if any
  -- If the event is about a relationship, identify the other person
  CASE 
    WHEN e.relationship_id IS NOT NULL THEN (
      SELECT CASE 
        WHEN r_partner.from_person_id = p.id THEN r_partner.to_person_id 
        ELSE r_partner.from_person_id 
      END 
      FROM public.relationships r_partner WHERE r_partner.id = e.relationship_id
    )
    ELSE NULL 
  END AS related_person_id,
  e.milestone_id,
  e.source_table_id,
  e.source_table_name,
  e.event_record_created_at
FROM public.people p
JOIN public.relationship_timeline_events e ON p.id = e.person_id
ORDER BY p.id, e.event_date DESC, e.event_record_created_at DESC;

COMMENT ON VIEW public.person_relationship_timeline IS 'Provides a timeline of all relevant events for each person, ordered by event date.';
COMMENT ON COLUMN public.person_relationship_timeline.related_person_id IS 'If the event is part of a dyadic relationship, this is the ID of the other person in that relationship.';


-- Create relationship pair timeline view
CREATE OR REPLACE VIEW public.relationship_pair_timeline AS
WITH relationship_context AS (
  SELECT
    r.id AS relationship_id,
    r.from_person_id,
    p_from.first_name || ' ' || p_from.last_name AS from_person_name,
    r.to_person_id,
    p_to.first_name || ' ' || p_to.last_name AS to_person_name,
    COALESCE(rt.name, r.relationship_type::TEXT, 'Unknown Type') as relationship_type_name
  FROM public.relationships r
  JOIN public.people p_from ON r.from_person_id = p_from.id
  JOIN public.people p_to ON r.to_person_id = p_to.id
  LEFT JOIN public.relationship_types rt ON r.relationship_type_id = rt.id
)
SELECT
  rc.relationship_id,
  rc.from_person_id,
  rc.from_person_name,
  rc.to_person_id,
  rc.to_person_name,
  rc.relationship_type_name,
  e.event_type,
  e.event_date,
  e.event_title,
  e.event_description,
  -- Determine which person in the relationship this specific event entry is primarily about, if applicable
  e.person_id AS event_primary_person_id, 
  e.milestone_id,
  e.source_table_id,
  e.source_table_name,
  e.event_record_created_at
FROM relationship_context rc
JOIN public.relationship_timeline_events e ON 
  -- Event is directly associated with this relationship
  e.relationship_id = rc.relationship_id OR
  -- Or, event is an interaction involving both people in this relationship
  (e.event_type = 'interaction' AND e.person_id = rc.from_person_id AND EXISTS (
    SELECT 1 FROM public.interaction_participants ip_check 
    WHERE ip_check.interaction_id = e.source_table_id AND ip_check.person_id = rc.to_person_id
  )) OR
  (e.event_type = 'interaction' AND e.person_id = rc.to_person_id AND EXISTS (
    SELECT 1 FROM public.interaction_participants ip_check 
    WHERE ip_check.interaction_id = e.source_table_id AND ip_check.person_id = rc.from_person_id
  ))
-- Deduplicate interaction events that would appear for both participants if not handled
-- This can be complex. A common approach is to pick one record or use DISTINCT ON if appropriate.
-- For simplicity here, we rely on the fact that relationship_timeline_events already has entries for each person.
-- The JOIN condition above tries to link events to a relationship.
-- We might still get "duplicate" conceptual events if an interaction is listed for both persons
-- and then joined to the relationship.
-- A more robust deduplication might be needed depending on exact display requirements.
ORDER BY rc.relationship_id, e.event_date DESC, e.event_record_created_at DESC;

COMMENT ON VIEW public.relationship_pair_timeline IS 'Provides a timeline of events relevant to a specific pair of people in a relationship.';
COMMENT ON COLUMN public.relationship_pair_timeline.event_primary_person_id IS 'The person_id from relationship_timeline_events, indicating who this specific event entry was for.';
