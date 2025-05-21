#!/bin/bash
# Script to rename and reorganize Supabase migration files

MIGRATIONS_DIR="lpg-backend/supabase/migrations"

# Create backup directory
mkdir -p "$MIGRATIONS_DIR/backup_$(date +%Y%m%d)"

# Phase 1: Foundation Layer
cp "$MIGRATIONS_DIR/20250519000000_enable_extensions.sql" "$MIGRATIONS_DIR/20240601000000_enable_extensions.sql"
cp "$MIGRATIONS_DIR/20240603000000_core_foundation.sql" "$MIGRATIONS_DIR/20240601010000_core_foundation.sql"
cp "$MIGRATIONS_DIR/20250519000100_environment_config.sql" "$MIGRATIONS_DIR/20240601020000_environment_config.sql"

# Phase 2: Domain Tables - extract from existing files
# We'll need to manually create these files by splitting existing ones
echo "-- Extract from relationship_framework.sql" > "$MIGRATIONS_DIR/20240602000000_relationship_types.sql"
echo "-- See 20240603000100_relationship_framework.sql for source" >> "$MIGRATIONS_DIR/20240602000000_relationship_types.sql"

echo "-- Contains mentor_milestones table" > "$MIGRATIONS_DIR/20240602010000_mentoring_tables.sql"
echo "-- See 20250522010000_mentor_relationship_milestones_view.sql for source" >> "$MIGRATIONS_DIR/20240602010000_mentoring_tables.sql"

cp "$MIGRATIONS_DIR/20250520010000_cross_cultural_participation_view.sql" "$MIGRATIONS_DIR/20240602020000_activity_groups.sql"
cp "$MIGRATIONS_DIR/20250521010000_alumni_continuity.sql" "$MIGRATIONS_DIR/20240602030000_alumni_tables.sql"

# Phase 3: Relationship Structure
cp "$MIGRATIONS_DIR/20250519000200_add_status_to_relationships.sql" "$MIGRATIONS_DIR/20240603000000_relationships.sql"
cp "$MIGRATIONS_DIR/20250522010000_mentor_relationship_milestones_view.sql" "$MIGRATIONS_DIR/20240603010000_relationship_milestones.sql"
cp "$MIGRATIONS_DIR/20250520010000_cross_cultural_participation_view.sql" "$MIGRATIONS_DIR/20240603020000_cross_group_participations.sql"
cp "$MIGRATIONS_DIR/20250521010000_alumni_continuity.sql" "$MIGRATIONS_DIR/20240603030000_alumni_checkins.sql"

# Phase 4: Auth & Security
cp "$MIGRATIONS_DIR/20240610000000_auth_plumbing.sql" "$MIGRATIONS_DIR/20240604000000_auth_plumbing.sql"
cp "$MIGRATIONS_DIR/20240611000000_policy_enhancements.sql" "$MIGRATIONS_DIR/20240604010000_base_security.sql"
cp "$MIGRATIONS_DIR/20250518000100_validation_helpers.sql" "$MIGRATIONS_DIR/20240604020000_function_permissions.sql"

# Phase 5: Timeline & Events
cp "$MIGRATIONS_DIR/20250530000000_timeline_event_sourcing.sql" "$MIGRATIONS_DIR/20240605000000_timeline_events_table.sql"
# Create a new file for timeline triggers - will need extraction
echo "-- Extract from timeline_event_sourcing.sql" > "$MIGRATIONS_DIR/20240605010000_timeline_event_triggers.sql"
cp "$MIGRATIONS_DIR/20250524010000_relationship_timeline.sql" "$MIGRATIONS_DIR/20240605020000_relationship_timeline_views.sql"

# Phase 6: Analytics & Measurement
cp "$MIGRATIONS_DIR/20250519010000_relationship_strength_metrics_view.sql" "$MIGRATIONS_DIR/20240606000000_relationship_strength_metrics.sql"
cp "$MIGRATIONS_DIR/20250520010000_cross_cultural_participation_view.sql" "$MIGRATIONS_DIR/20240606010000_brotherhood_visibility.sql"
cp "$MIGRATIONS_DIR/20250522010000_mentor_relationship_milestones_view.sql" "$MIGRATIONS_DIR/20240606020000_mentor_health_metrics.sql"
cp "$MIGRATIONS_DIR/20250523010000_ai_relationship_intelligence.sql" "$MIGRATIONS_DIR/20240606030000_ai_relationship_intelligence.sql"

# Phase 7: Materialized Views
cp "$MIGRATIONS_DIR/20250525010000_create_materialized_views.sql" "$MIGRATIONS_DIR/20240607000000_create_materialized_views.sql"
cp "$MIGRATIONS_DIR/20250531000000_mv_incremental_refresh.sql" "$MIGRATIONS_DIR/20240607010000_mv_incremental_refresh.sql"
cp "$MIGRATIONS_DIR/20250525020000_drop_original_views.sql" "$MIGRATIONS_DIR/20240607020000_drop_original_views.sql"

# Phase 8: Performance Optimization
cp "$MIGRATIONS_DIR/20250603000000_enhanced_indexes.sql" "$MIGRATIONS_DIR/20240608000000_enhanced_indexes.sql"
cp "$MIGRATIONS_DIR/20250601000000_optimize_rls_policies.sql" "$MIGRATIONS_DIR/20240608010000_optimize_rls_policies.sql"
cp "$MIGRATIONS_DIR/20250602000000_ai_functions_transaction_control.sql" "$MIGRATIONS_DIR/20240608020000_ai_function_transaction_control.sql"

echo "Files copied with new naming scheme. Original files preserved."
echo "Important: You need to manually extract content for split files!"
echo "Note: Some files are copied multiple times for different purposes."
echo "You need to edit these files to contain only the relevant sections." 