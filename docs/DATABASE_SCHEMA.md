# LPG Database Schema Documentation

## Core Tables

### people
Primary user records in the system.

```
people
------
id: UUID PK
auth_id: UUID (from Supabase Auth)
first_name: TEXT
last_name: TEXT
display_name: TEXT
email: TEXT
phone: TEXT
bio: TEXT
metadata: JSONB
strength_score: INTEGER
created_at: TIMESTAMPTZ
updated_at: TIMESTAMPTZ
```

### roles
System roles for access control.

```
roles
-----
id: UUID PK
name: TEXT
description: TEXT
created_at: TIMESTAMPTZ
```

### people_roles
Junction table linking people to their roles.

```
people_roles
------------
id: UUID PK
person_id: UUID FK → people.id
role_id: UUID FK → roles.id
created_at: TIMESTAMPTZ
```

## Relationship Management

### relationship_types
Defines different kinds of relationships (mentor, friend, etc.).

```
relationship_types
-----------------
id: UUID PK
name: TEXT
description: TEXT
created_at: TIMESTAMPTZ
```

### relationships
Tracks connections between people.

```
relationships
------------
id: UUID PK
from_person_id: UUID FK → people.id
to_person_id: UUID FK → people.id
relationship_type_id: UUID FK → relationship_types.id
relationship_type: TEXT
start_date: DATE
end_date: DATE
status: TEXT
notes: TEXT
metadata: JSONB
strength_score: INTEGER
created_at: TIMESTAMPTZ
updated_at: TIMESTAMPTZ
created_by: UUID FK → people.id
```

### milestone_types
Predefined milestones that can be achieved in relationships.

```
milestone_types
--------------
id: UUID PK
name: TEXT
description: TEXT
category: TEXT
created_at: TIMESTAMPTZ
```

### mentor_milestones
Specific milestones for mentoring relationships.

```
mentor_milestones
----------------
id: UUID PK
name: TEXT
description: TEXT
expected_days: INTEGER
is_required: BOOLEAN
sequence_order: INTEGER
created_at: TIMESTAMPTZ
```

### relationship_milestones
Tracks milestones achieved in specific relationships.

```
relationship_milestones
----------------------
id: UUID PK
relationship_id: UUID FK → relationships.id
milestone_type_id: UUID FK → milestone_types.id
milestone_id: UUID FK → mentor_milestones.id
milestone_date: DATE
notes: TEXT
created_at: TIMESTAMPTZ
updated_at: TIMESTAMPTZ
```

## Activity Tracking

### activity_groups
Groups or organizations that people can belong to.

```
activity_groups
--------------
id: UUID PK
name: TEXT
description: TEXT
category: TEXT
created_at: TIMESTAMPTZ
```

### person_activities
Junction table linking people to activity groups.

```
person_activities
----------------
id: UUID PK
person_id: UUID FK → people.id
activity_group_id: UUID FK → activity_groups.id
primary_activity: BOOLEAN
created_at: TIMESTAMPTZ
```

### activity_events
Events associated with activity groups.

```
activity_events
--------------
id: UUID PK
activity_group_id: UUID FK → activity_groups.id
name: TEXT
description: TEXT
event_date: DATE
created_at: TIMESTAMPTZ
```

### cross_group_participations
Tracks participation in activity groups other than a person's primary group.

```
cross_group_participations
-------------------------
id: UUID PK
person_id: UUID FK → people.id
activity_event_id: UUID FK → activity_events.id
participation_date: DATE
recognition_points: INTEGER
notes: TEXT
created_at: TIMESTAMPTZ
```

## Interaction Tracking

### interactions
Records interactions between people.

```
interactions
-----------
id: UUID PK
title: TEXT
description: TEXT
occurred_at: TIMESTAMPTZ
quality_score: INTEGER (1-10)
reciprocity_score: INTEGER (1-10)
created_at: TIMESTAMPTZ
```

### interaction_participants
Junction table linking people to interactions.

```
interaction_participants
-----------------------
id: UUID PK
interaction_id: UUID FK → interactions.id
person_id: UUID FK → people.id
attended: BOOLEAN
created_at: TIMESTAMPTZ
```

## Timeline Event System

### timeline_events
Centralized record of events related to people and relationships, partitioned by date.

```
timeline_events
--------------
id: UUID PK
event_type: TEXT
event_date: TIMESTAMPTZ (partition key)
event_title: TEXT
event_description: TEXT
person_id: UUID FK → people.id
relationship_id: UUID FK → relationships.id
source_entity_type: TEXT
source_entity_id: UUID
payload: JSONB
created_at: TIMESTAMPTZ
updated_at: TIMESTAMPTZ
is_deleted: BOOLEAN
```

### timeline_event_queue
Queue for asynchronous processing of timeline events.

```
timeline_event_queue
-------------------
id: UUID PK
operation: TEXT ('INSERT', 'UPDATE', 'DELETE')
table_name: TEXT
record_id: UUID
payload: JSONB
priority: SMALLINT
retry_count: SMALLINT
processed: BOOLEAN
processing_started_at: TIMESTAMPTZ
processing_completed_at: TIMESTAMPTZ
created_at: TIMESTAMPTZ
```

## Materialized Views

### relationship_strength_analytics_mv
Analytics on relationship strength based on interactions.

```
relationship_strength_analytics_mv
--------------------------------
relationship_id: UUID
from_person_id: UUID
to_person_id: UUID
relationship_type: TEXT
interaction_count: INTEGER
avg_quality: NUMERIC
avg_reciprocity: NUMERIC
last_interaction_at: TIMESTAMPTZ
time_since_last_interaction: INTERVAL
strength_score: NUMERIC
```

### brotherhood_visibility_mv
Analytics on cross-group participation.

```
brotherhood_visibility_mv
-----------------------
person_id: UUID
first_name: TEXT
last_name: TEXT
home_activity_id: UUID
home_activity_name: TEXT
home_activity_category: TEXT
visited_activity_id: UUID
visited_activity_name: TEXT
visited_activity_category: TEXT
visit_count: INTEGER
total_recognition_points: INTEGER
```

### mentor_relationship_health_mv
Health assessment of mentor relationships.

```
mentor_relationship_health_mv
---------------------------
relationship_id: UUID
mentor_id: UUID
mentor_first_name: TEXT
mentor_last_name: TEXT
student_id: UUID
student_first_name: TEXT
student_last_name: TEXT
start_date: DATE
relationship_duration: INTERVAL
interaction_count: INTEGER
recent_interaction_count: INTEGER
recent_avg_quality: NUMERIC
milestones_achieved_count: INTEGER
total_required_milestones_overall: INTEGER
required_milestones_achieved_count: INTEGER
health_status: TEXT
```

## Telemetry

### telemetry.rls_evaluations
Performance metrics for RLS policy evaluations.

```
telemetry.rls_evaluations
------------------------
id: UUID PK
view_name: TEXT
duration_ms: DOUBLE PRECISION
evaluated_at: TIMESTAMPTZ
rows_returned: INTEGER
```

## Entity Relationship Diagram

```mermaid
erDiagram
    people ||--o{ people_roles : has
    people ||--o{ relationships : from
    people ||--o{ relationships : to
    people ||--o{ person_activities : belongs_to
    people ||--o{ interaction_participants : participates_in
    people ||--o{ timeline_events : records
    people ||--o{ cross_group_participations : participates_in
    
    roles ||--o{ people_roles : assigned_to
    
    relationship_types ||--o{ relationships : categorizes
    
    relationships ||--o{ relationship_milestones : achieves
    relationships ||--o{ timeline_events : generates
    
    milestone_types ||--o{ relationship_milestones : defines
    
    mentor_milestones ||--o{ relationship_milestones : defines
    
    activity_groups ||--o{ person_activities : includes
    activity_groups ||--o{ activity_events : hosts
    
    activity_events ||--o{ cross_group_participations : tracked_in
    
    interactions ||--o{ interaction_participants : includes
    
    timeline_events }|--|| timeline_event_queue : processed_by
    
    people {
        UUID id PK
        UUID auth_id
        TEXT first_name
        TEXT last_name
        TEXT email
    }
    
    roles {
        UUID id PK
        TEXT name
    }
    
    people_roles {
        UUID id PK
        UUID person_id FK
        UUID role_id FK
    }
    
    relationship_types {
        UUID id PK
        TEXT name
        TEXT description
    }
    
    relationships {
        UUID id PK
        UUID from_person_id FK
        UUID to_person_id FK
        UUID relationship_type_id FK
        TEXT status
        DATE start_date
        DATE end_date
    }
    
    milestone_types {
        UUID id PK
        TEXT name
        TEXT description
    }
    
    mentor_milestones {
        UUID id PK
        TEXT name
        TEXT description
        BOOLEAN is_required
    }
    
    relationship_milestones {
        UUID id PK
        UUID relationship_id FK
        UUID milestone_type_id FK
        UUID milestone_id FK
        DATE milestone_date
    }
    
    activity_groups {
        UUID id PK
        TEXT name
        TEXT category
    }
    
    person_activities {
        UUID id PK
        UUID person_id FK
        UUID activity_group_id FK
        BOOLEAN primary_activity
    }
    
    activity_events {
        UUID id PK
        UUID activity_group_id FK
        TEXT name
        DATE event_date
    }
    
    cross_group_participations {
        UUID id PK
        UUID person_id FK
        UUID activity_event_id FK
        INTEGER recognition_points
    }
    
    interactions {
        UUID id PK
        TEXT title
        TEXT description
        TIMESTAMPTZ occurred_at
        INTEGER quality_score
        INTEGER reciprocity_score
    }
    
    interaction_participants {
        UUID id PK
        UUID interaction_id FK
        UUID person_id FK
        BOOLEAN attended
    }
    
    timeline_events {
        UUID id PK
        TEXT event_type
        TIMESTAMPTZ event_date
        TEXT event_title
        UUID person_id FK
        UUID relationship_id FK
        TEXT source_entity_type
        UUID source_entity_id
        BOOLEAN is_deleted
    }
    
    timeline_event_queue {
        UUID id PK
        TEXT operation
        TEXT table_name
        UUID record_id
        JSONB payload
        BOOLEAN processed
    }
    
    relationship_strength_analytics_mv {
        UUID relationship_id
        UUID from_person_id
        UUID to_person_id
        INTEGER interaction_count
        NUMERIC strength_score
    }
    
    brotherhood_visibility_mv {
        UUID person_id
        UUID home_activity_id
        UUID visited_activity_id
        INTEGER visit_count
    }
    
    mentor_relationship_health_mv {
        UUID relationship_id
        UUID mentor_id
        UUID student_id
        TEXT health_status
    }
    
    telemetry_rls_evaluations {
        UUID id PK
        TEXT view_name
        DOUBLE duration_ms
        INTEGER rows_returned
    }
```

## Security Policies

The database implements Row Level Security (RLS) policies on most tables:

1. **Self-access policies**: Users can view and manage their own data
2. **Relationship-based policies**: Users can see data related to their relationships
3. **Admin/staff override**: Users with admin/staff roles can access all data

## Performance Optimization Features

1. **Partitioned tables**: Timeline events are partitioned by date quarter
2. **Materialized views**: Pre-computed analytics for faster dashboard rendering
3. **Covering indexes**: Specialized indexes that include commonly queried columns
4. **SQL functions**: Optimized SQL language functions for better JIT compilation
5. **Telemetry**: Performance monitoring for RLS policy evaluation

## Integration Points for Frontend

The database provides several optimized access patterns for frontend integration:

1. **Secure access functions**: 
   - `get_relationship_strength()`
   - `get_brotherhood_visibility()`
   - `get_mentor_relationship_health()`
   - `get_relationship_timeline()`

2. **Timeline event management**:
   - `merge_timeline_event_sql()`
   - `soft_delete_timeline_event_sql()`
   - `process_timeline_events_batch()`

3. **Auth integration**:
   - `handle_new_user()`
   - `update_user_claims()`
   - `has_permission()`

## Database Migration Sequence

The migrations should be applied in the following order to ensure proper dependency resolution:

1. Enable extensions (20240601000000)
2. Create fundamental tables (relationships, people, etc.)
3. Apply relationship framework and security
4. Implement timeline event system
5. Create materialized views
6. Add performance optimizations (indexes, function optimizations)
7. Enhance RLS policies and telemetry

These migrations establish the foundation for a scalable, performant application with proper security boundaries and analytics capabilities.
