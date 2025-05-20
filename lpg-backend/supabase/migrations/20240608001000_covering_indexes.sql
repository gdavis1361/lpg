-- Create a new migration file: 20240608001000_covering_indexes.sql
BEGIN;

-- Timeline events covering indexes
CREATE INDEX IF NOT EXISTS idx_timeline_events_person_date_covering
ON public.timeline_events(person_id, event_date DESC)
INCLUDE (event_title, event_type, relationship_id)
WHERE NOT is_deleted;

-- Partial indexes for common event types
CREATE INDEX IF NOT EXISTS idx_timeline_events_milestone
ON public.timeline_events(person_id, event_date DESC)
INCLUDE (event_title, relationship_id)
WHERE event_type = 'milestone' AND NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_timeline_events_relationship
ON public.timeline_events(person_id, event_date DESC)
INCLUDE (event_title)
WHERE event_type IN ('relationship_created', 'relationship_updated') AND NOT is_deleted;

-- Relationship covering indexes
CREATE INDEX IF NOT EXISTS idx_relationships_covering
ON public.relationships(from_person_id, to_person_id)
INCLUDE (relationship_type_id, status, start_date)
WHERE status = 'active';

-- Interaction covering indexes for common queries
CREATE INDEX IF NOT EXISTS idx_interaction_participants_covering
ON public.interaction_participants(person_id, interaction_id)
INCLUDE (role, attended)
WHERE attended = TRUE;

COMMIT;
