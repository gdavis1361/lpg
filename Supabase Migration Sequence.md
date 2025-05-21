# Revised Supabase Migration Sequence for Chattanooga Prep

Your current migration sequence contains critical dependency chains that will fail in Supabase's deployment pipeline. I've restructured the migrations to ensure proper initialization order while maintaining logical grouping.

## Revised Migration Sequence

```
# PHASE 1: Foundation Layer
20240601000000_enable_extensions.sql               # Extensions first (pg_cron, uuid-ossp, etc.)
20240601010000_core_foundation.sql                 # Core tables (people, roles, etc.)
20240601020000_environment_config.sql              # Environment configuration

# PHASE 2: Domain Tables (All primary entities before relationships)
20240602000000_relationship_types.sql              # Extract from relationship_framework.sql
20240602010000_mentoring_tables.sql                # mentor_milestones table
20240602020000_activity_groups.sql                 # activity_groups and person_activities tables
20240602030000_alumni_tables.sql                   # Alumni-specific tables

# PHASE 3: Relationship Structure with Immediate RLS
20240603000000_relationships.sql                   # Relationships schema with status field
20240603010000_relationship_milestones.sql         # Relationship milestones junction
20240603020000_cross_group_participations.sql      # Cross-group participation tracking
20240603030000_alumni_checkins.sql                 # Alumni check-in records

# PHASE 4: Auth & Security (Early for protection)
20240604000000_auth_plumbing.sql                   # Auth integration
20240604010000_base_security.sql                   # Initial RLS policies
20240604020000_function_permissions.sql            # Function permissions

# PHASE 5: Timeline & Events
20240605000000_timeline_events_table.sql           # Timeline event schema only
20240605010000_timeline_event_triggers.sql         # Timeline event triggers (after tables exist)
20240605020000_relationship_timeline_views.sql      # Timeline views

# PHASE 6: Analytics & Measurement
20240606000000_relationship_strength_metrics.sql   # Relationship strength calculations
20240606010000_brotherhood_visibility.sql          # Brotherhood visibility metrics
20240606020000_mentor_health_metrics.sql           # Mentor relationship health 
20240606030000_ai_relationship_intelligence.sql    # AI-driven relationship intelligence

# PHASE 7: Materialized Views with Proper Transaction Control
20240607000000_create_materialized_views.sql       # Create MVs with transaction boundaries
20240607010000_mv_incremental_refresh.sql          # Optimized MV refresh mechanism
20240607020000_drop_original_views.sql             # Drop original views after MVs established

# PHASE 8: Performance Optimization
20240608000000_enhanced_indexes.sql                # Comprehensive indexing strategy
20240608010000_optimize_rls_policies.sql           # RLS policy optimization
20240608020000_ai_function_transaction_control.sql # AI function optimizations
```

## Critical Implementation Considerations

### 1. Extension Dependencies

Your first migration must be:

```sql
-- 20240601000000_enable_extensions.sql
BEGIN;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
COMMIT;
```

This ensures extensions are available before dependent objects.

### 2. Table Creation with Immediate RLS

For each domain table, implement the Supabase-recommended pattern:

```sql
-- Example for relationships.sql
BEGIN;
CREATE TABLE relationships (...);

-- Apply RLS immediately
ALTER TABLE relationships ENABLE ROW LEVEL SECURITY;

-- Base RLS policy (restrictive)
CREATE POLICY "relationships_read_self" ON relationships
  FOR SELECT USING (
    from_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid()) OR
    to_person_id IN (SELECT id FROM people WHERE auth_id = auth.uid())
  );
COMMIT;
```

This prevents even momentary security exposures during deployment.

### 3. Timeline Event Source Dependencies

Split the timeline event implementation into schema and triggers:

```sql
-- 20240605000000_timeline_events_table.sql
BEGIN;
CREATE TABLE timeline_events (...);
-- Define schema only
COMMIT;

-- 20240605010000_timeline_event_triggers.sql
BEGIN;
-- Now create triggers after tables exist
CREATE TRIGGER relationship_timeline_trigger
AFTER INSERT OR UPDATE OR DELETE ON relationships
FOR EACH ROW EXECUTE FUNCTION populate_relationship_timeline();
-- Additional triggers
COMMIT;
```

### 4. Materialized View Optimization

Implement transaction boundaries and advisory locks:

```sql
-- 20240607000000_create_materialized_views.sql
BEGIN;
-- Try to acquire lock for MV creation
SELECT pg_try_advisory_lock(hashtext('create_relationship_strength_mv'));

CREATE MATERIALIZED VIEW IF NOT EXISTS relationship_strength_analytics_mv AS
SELECT /* your select statement */;

-- Release lock
SELECT pg_advisory_unlock(hashtext('create_relationship_strength_mv'));
COMMIT;
```

### 5. RLS Implementation Optimization

Use the optimized pattern for RLS implementation:

```sql
-- In 20240608010000_optimize_rls_policies.sql
BEGIN;
-- Memory-efficient helper functions
CREATE OR REPLACE FUNCTION get_current_user_person_id()
RETURNS UUID AS $$
  SELECT id FROM people WHERE auth_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE PARALLEL SAFE SECURITY DEFINER;

-- Optimized RLS policies
CREATE POLICY "people_self_view_policy" ON people
  FOR SELECT USING (id = get_current_user_person_id());
COMMIT;
```

## Migration Content Modifications

Several migration files require structural changes to work properly:

1. **Timeline Event Sourcing**: Remove references to tables that don't exist yet, create a separate trigger file

2. **Materialized View Creation**: Add transaction boundaries and error handling:
   ```sql
   DO $$
   BEGIN
     BEGIN
       CREATE MATERIALIZED VIEW brotherhood_visibility_mv AS SELECT...;
     EXCEPTION WHEN duplicate_table THEN
       RAISE NOTICE 'Materialized view already exists';
     END;
   END $$;
   ```

3. **Function Implementation**: Replace dynamic SQL with parameterized queries where possible to improve Supabase execution plan caching

4. **Indexes**: Create indexes after tables and inside transaction blocks:
   ```sql
   BEGIN;
   -- Create partial index for active relationships
   CREATE INDEX idx_relationships_active ON relationships(from_person_id, to_person_id)
   WHERE status = 'active';
   COMMIT;
   ```

This revised structure properly addresses Supabase's deployment constraints while maintaining your logical grouping and ensuring database integrity throughout the migration process.