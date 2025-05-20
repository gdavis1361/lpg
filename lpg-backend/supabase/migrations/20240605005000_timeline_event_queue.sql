-- In a new migration file: 20240605005000_timeline_event_queue.sql
BEGIN;

CREATE TABLE timeline_event_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  payload JSONB NOT NULL,
  priority SMALLINT DEFAULT 5,
  retry_count SMALLINT DEFAULT 0,
  processed BOOLEAN DEFAULT FALSE,
  processing_started_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT timeline_event_queue_processing_lock 
    EXCLUDE USING gist (record_id WITH =) 
    WHERE (processing_started_at IS NOT NULL AND processed = FALSE)
);

CREATE INDEX idx_timeline_event_queue_unprocessed ON timeline_event_queue(priority, created_at)
WHERE processed = FALSE;

-- Statement-level trigger function
CREATE OR REPLACE FUNCTION queue_timeline_events()
RETURNS TRIGGER AS $$
DECLARE
  v_record RECORD;
  v_operation TEXT := TG_OP;
  v_table_name TEXT := TG_TABLE_NAME;
BEGIN
  IF v_operation = 'INSERT' OR v_operation = 'UPDATE' THEN
    FOR v_record IN SELECT * FROM new_table
    LOOP
      INSERT INTO timeline_event_queue(operation, table_name, record_id, payload)
      VALUES (v_operation, v_table_name, v_record.id, to_jsonb(v_record));
    END LOOP;
  ELSIF v_operation = 'DELETE' THEN
    FOR v_record IN SELECT * FROM old_table
    LOOP  
      INSERT INTO timeline_event_queue(operation, table_name, record_id, payload)
      VALUES (v_operation, v_table_name, v_record.id, to_jsonb(v_record));
    END LOOP;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMIT;
