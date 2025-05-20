-- In 20240605006000_convert_timeline_triggers.sql
BEGIN;

-- Create batch processing function
CREATE OR REPLACE FUNCTION process_timeline_event_queue(batch_size INT DEFAULT 100)
RETURNS INTEGER AS $$
DECLARE
  v_processed INTEGER := 0;
  v_record RECORD;
  v_lock_acquired BOOLEAN;
BEGIN
  -- Try to acquire advisory lock to prevent concurrent processing
  SELECT pg_try_advisory_lock(hashtext('process_timeline_events')) INTO v_lock_acquired;
  
  IF NOT v_lock_acquired THEN
    RETURN 0; -- Another process is already handling the queue
  END IF;

  FOR v_record IN
    SELECT * FROM timeline_event_queue
    WHERE NOT processed AND processing_started_at IS NULL
    ORDER BY priority, created_at
    LIMIT batch_size
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      -- Mark as processing
      UPDATE timeline_event_queue
      SET processing_started_at = clock_timestamp()
      WHERE id = v_record.id;
      
      -- Process based on operation and table
      IF v_record.table_name = 'interactions' THEN
        IF v_record.operation = 'INSERT' OR v_record.operation = 'UPDATE' THEN
          PERFORM handle_interaction_event(
            (v_record.payload->>'id')::UUID,
            v_record.payload
          );
        ELSIF v_record.operation = 'DELETE' THEN
          PERFORM soft_delete_timeline_event('interaction', (v_record.payload->>'id')::UUID);
        END IF;
      ELSIF v_record.table_name = 'relationships' THEN
        -- Handle relationships similarly
        -- ...
      END IF;
      
      -- Mark as processed
      UPDATE timeline_event_queue
      SET processed = TRUE,
          processing_started_at = NULL
      WHERE id = v_record.id;
      
      v_processed := v_processed + 1;
    EXCEPTION WHEN OTHERS THEN
      -- Mark as failed but retryable
      UPDATE timeline_event_queue
      SET processing_started_at = NULL,
          retry_count = retry_count + 1
      WHERE id = v_record.id;
      
      -- Log error
      INSERT INTO error_logs(function_name, error_message, details)
      VALUES ('process_timeline_event_queue', SQLERRM, jsonb_build_object(
        'record_id', v_record.id,
        'table_name', v_record.table_name,
        'operation', v_record.operation
      ));
    END;
  END LOOP;
  
  -- Release lock
  PERFORM pg_advisory_unlock(hashtext('process_timeline_events'));
  
  RETURN v_processed;
END;
$$ LANGUAGE plpgsql;

-- Set up cron job for processing
SELECT cron.schedule(
  'process_timeline_events',
  '* * * * *', -- Every minute
  $$SELECT process_timeline_event_queue(200)$$
);

-- Create savepoint before removing old triggers
SAVEPOINT before_drop_triggers;

-- Drop old triggers
DROP TRIGGER IF EXISTS interaction_timeline_trigger ON interactions;
DROP TRIGGER IF EXISTS relationship_timeline_trigger ON relationships;
DROP TRIGGER IF EXISTS milestone_timeline_trigger ON relationship_milestones;
DROP TRIGGER IF EXISTS cross_group_timeline_trigger ON cross_group_participations;
DROP TRIGGER IF EXISTS alumni_checkin_timeline_trigger ON alumni_checkins;

-- Create new statement-level triggers
CREATE TRIGGER queue_interaction_changes
AFTER INSERT OR UPDATE OR DELETE ON interactions
REFERENCING NEW TABLE AS new_table OLD TABLE AS old_table
FOR EACH STATEMENT EXECUTE FUNCTION queue_timeline_events();

CREATE TRIGGER queue_relationship_changes
AFTER INSERT OR UPDATE OR DELETE ON relationships
REFERENCING NEW TABLE AS new_table OLD TABLE AS old_table
FOR EACH STATEMENT EXECUTE FUNCTION queue_timeline_events();

-- Add similar triggers for other tables

COMMIT;
