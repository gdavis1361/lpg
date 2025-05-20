-- Create a new migration file: 20240608002000_function_optimizations.sql
BEGIN;

-- Convert merge_timeline_event to SQL function (simplified version)
CREATE OR REPLACE FUNCTION merge_timeline_event_sql(
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
  INSERT INTO timeline_events (
    event_type, event_date, event_title, event_description,
    person_id, relationship_id, source_entity_type, source_entity_id, payload
  ) VALUES (
    p_event_type, p_event_date, p_event_title, p_event_description,
    p_person_id, p_relationship_id, p_source_entity_type, p_source_entity_id, p_payload
  )
  ON CONFLICT (source_entity_type, source_entity_id, event_type, person_id) 
  WHERE NOT is_deleted
  DO UPDATE SET 
    event_date = EXCLUDED.event_date,
    event_title = EXCLUDED.event_title,
    event_description = EXCLUDED.event_description,
    relationship_id = EXCLUDED.relationship_id,
    payload = EXCLUDED.payload,
    updated_at = NOW()
  RETURNING id;
$$ LANGUAGE sql;

-- Convert soft_delete_timeline_event to SQL function
CREATE OR REPLACE FUNCTION soft_delete_timeline_event_sql(
  p_source_entity_type TEXT,
  p_source_entity_id UUID
) RETURNS VOID AS $$
  UPDATE timeline_events
  SET is_deleted = TRUE,
      updated_at = NOW()
  WHERE source_entity_type = p_source_entity_type
    AND source_entity_id = p_source_entity_id;
$$ LANGUAGE sql;

-- Optimize get_primary_activity_id with STABLE marker
CREATE OR REPLACE FUNCTION get_primary_activity_id(p_person_id UUID)
RETURNS UUID AS $$
  SELECT activity_group_id
  FROM person_activities
  WHERE person_id = p_person_id AND primary_activity = TRUE
  LIMIT 1;
$$ LANGUAGE sql STABLE PARALLEL SAFE;

-- Create an optimized function for timeline batch processing
CREATE OR REPLACE FUNCTION process_timeline_events_batch(
  p_table_name TEXT,
  p_limit INTEGER DEFAULT 100
) RETURNS INTEGER AS $$
  WITH pending_events AS (
    SELECT id, payload, operation
    FROM timeline_event_queue
    WHERE table_name = p_table_name
      AND NOT processed
      AND processing_started_at IS NULL
    ORDER BY priority, created_at
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  ),
  marked_processing AS (
    UPDATE timeline_event_queue q
    SET processing_started_at = clock_timestamp()
    FROM pending_events p
    WHERE q.id = p.id
    RETURNING q.id, q.payload, q.operation
  ),
  processed_events AS (
    -- Process the events based on operation type
    SELECT
      id,
      (CASE
        WHEN operation = 'INSERT' OR operation = 'UPDATE' THEN
          -- Call appropriate handler based on table name
          CASE p_table_name
            WHEN 'interactions' THEN 
              merge_timeline_event_sql(
                'interaction',
                (payload->>'start_time')::TIMESTAMPTZ,
                payload->>'title',
                payload->>'description',
                (payload->>'person_id')::UUID,
                NULL, -- relationship_id determined later
                'interaction',
                (payload->>'id')::UUID,
                payload
              )
            -- Add more table handlers here
          END
        WHEN operation = 'DELETE' THEN
          -- Handle delete operations
          soft_delete_timeline_event_sql(p_table_name, (payload->>'id')::UUID)
      END) AS result
    FROM marked_processing
  )
  UPDATE timeline_event_queue q
  SET processed = TRUE,
      processing_started_at = NULL
  FROM processed_events p
  WHERE q.id = p.id
  RETURNING COUNT(*);
$$ LANGUAGE sql;

COMMENT ON FUNCTION merge_timeline_event_sql IS 'Optimized SQL version of merge_timeline_event for better JIT compilation';
COMMENT ON FUNCTION soft_delete_timeline_event_sql IS 'Optimized SQL version of soft_delete_timeline_event for better JIT compilation';
COMMENT ON FUNCTION process_timeline_events_batch IS 'Processes a batch of timeline events for a specific table using optimized SQL functions';

COMMIT;
