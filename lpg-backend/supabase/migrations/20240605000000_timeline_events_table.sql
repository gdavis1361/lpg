-- 20240605000000_timeline_events_table.sql
-- Timeline Events Table Structure
-- Extracted from 20250530000000_timeline_event_sourcing.sql

BEGIN;

-- 1. Create partitioned timeline_events table
-- Drop the original table if it exists and recreate as partitioned
DROP TABLE IF EXISTS public.timeline_events CASCADE;

CREATE TABLE public.timeline_events (
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
) PARTITION BY RANGE (event_date);

-- Create initial partitions (one per quarter for current + next year)
CREATE TABLE timeline_events_2024q1 PARTITION OF timeline_events
  FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE timeline_events_2024q2 PARTITION OF timeline_events
  FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
CREATE TABLE timeline_events_2024q3 PARTITION OF timeline_events
  FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');
CREATE TABLE timeline_events_2024q4 PARTITION OF timeline_events
  FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');
CREATE TABLE timeline_events_2025q1 PARTITION OF timeline_events
  FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

-- Create partition for older data
CREATE TABLE timeline_events_historical PARTITION OF timeline_events
  FOR VALUES FROM (MINVALUE) TO ('2024-01-01');

-- Create default partition for future data
CREATE TABLE timeline_events_future PARTITION OF timeline_events
  FOR VALUES FROM ('2025-04-01') TO (MAXVALUE);

-- Create indexes for timeline events
CREATE INDEX IF NOT EXISTS idx_timeline_events_person_date ON public.timeline_events(person_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_timeline_events_relationship_date ON public.timeline_events(relationship_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_timeline_events_source ON public.timeline_events(source_entity_type, source_entity_id);
CREATE INDEX IF NOT EXISTS idx_timeline_events_event_type_date ON public.timeline_events(event_type, event_date DESC);

-- Apply RLS immediately
ALTER TABLE public.timeline_events ENABLE ROW LEVEL SECURITY;

-- Basic RLS policy (users can see events for their own relationships)
CREATE POLICY "timeline_events_read_self" ON public.timeline_events
  FOR SELECT USING (
    -- User can view their own timeline events
    person_id IN (SELECT id FROM people WHERE auth_id = auth.uid())
    -- Or events for relationships they're part of
    OR relationship_id IN (
      SELECT id FROM relationships 
      WHERE from_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid())
      OR to_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid())
    )
    -- Admins can view all
    OR EXISTS (
      SELECT 1 FROM people
      JOIN roles ON people.role_id = roles.id
      WHERE people.auth_id = auth.uid() AND roles.name = 'admin'
    )
  );

-- Automatically bump updated_at on UPDATE
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

-- Create function to maintain timeline partitions
CREATE OR REPLACE FUNCTION maintain_timeline_partitions()
RETURNS VOID AS $$
DECLARE
  next_quarter_start DATE;
  partition_name TEXT;
  current_max_date DATE;
  partition_count INTEGER;
BEGIN
  -- Find the latest partition boundary (excluding future partition)
  SELECT to_date(substring(relname FROM 'timeline_events_([0-9]{4}q[1-4])$'), 'YYYYqQ') + INTERVAL '3 months'
  INTO current_max_date
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public'
    AND c.relname ~ '^timeline_events_[0-9]{4}q[1-4]$'
  ORDER BY to_date(substring(relname FROM 'timeline_events_([0-9]{4}q[1-4])$'), 'YYYYqQ') DESC
  LIMIT 1;
  
  -- If we're within 60 days of needing a new partition, create it
  IF current_max_date - CURRENT_DATE <= 60 THEN
    -- Determine the next quarter start date
    next_quarter_start := current_max_date;
    
    -- Get the year and quarter
    partition_name := 'timeline_events_' || 
                      to_char(next_quarter_start, 'YYYY') || 'q' || 
                      to_char(next_quarter_start, 'Q');
    
    -- Create the new partition
    EXECUTE format('
      CREATE TABLE %I PARTITION OF timeline_events
      FOR VALUES FROM (%L) TO (%L)',
      partition_name,
      next_quarter_start,
      next_quarter_start + INTERVAL '3 months'
    );
    
    RAISE NOTICE 'Created new partition: %', partition_name;
  END IF;

  -- Count total partitions and log
  SELECT count(*) INTO partition_count
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public'
    AND c.relname ~ '^timeline_events_';
  
  RAISE NOTICE 'Current timeline_events partition count: %', partition_count;
END;
$$ LANGUAGE plpgsql;

-- Helper functions for timeline events (merge, delete)
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

-- Function to mark event as deleted
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

-- Schedule quarterly maintenance
SELECT cron.schedule(
  'maintain_timeline_partitions_quarterly',
  '0 0 1 */3 *', -- First day of every quarter
  'SELECT maintain_timeline_partitions();'
);

COMMENT ON TABLE public.timeline_events IS 'Centralized table for storing various types of events related to people and relationships to build timelines.';
COMMENT ON COLUMN public.timeline_events.person_id IS 'The person this specific timeline entry is associated with. An event involving two people might have two entries.';
COMMENT ON COLUMN public.timeline_events.relationship_id IS 'If the event is specific to a relationship, this links to it.';
COMMENT ON COLUMN public.timeline_events.source_entity_type IS 'Name of the table from which this event originated (e.g., ''interactions'', ''relationships'').';
COMMENT ON COLUMN public.timeline_events.source_entity_id IS 'Primary key of the record in the source table.';
COMMENT ON COLUMN public.timeline_events.payload IS 'Stores additional event-specific data not fitting other columns.';
COMMENT ON FUNCTION merge_timeline_event IS 'Upserts a timeline event, merging with existing events of the same type/entity/person';
COMMENT ON FUNCTION soft_delete_timeline_event IS 'Marks timeline events as deleted without physically removing them';
COMMENT ON FUNCTION maintain_timeline_partitions IS 'Automatically creates new quarterly partitions for timeline_events';

COMMIT; 