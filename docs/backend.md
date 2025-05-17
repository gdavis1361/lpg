# Supabase Migration Files for Chattanooga Prep Relationship Platform

Based on the relationship-centered design requirements, I've architected a comprehensive database schema that prioritizes relationship intelligence over traditional siloed data structures. These migrations create a foundation that supports fluid role transitions, cross-contextual awareness, and longitudinal relationship tracking.

## Migration 1: Core Entities and Authentication

```sql
-- migration_1_core_entities.sql

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Base table for all individuals in the system
CREATE TABLE people (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID UNIQUE, -- Links to Supabase auth.users when applicable
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    bio TEXT,
    address_line1 TEXT,
    address_line2 TEXT, 
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'USA',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    metadata JSONB DEFAULT '{}'::JSONB -- For flexible additional attributes
);

-- Create role definitions
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    permissions JSONB DEFAULT '{}'::JSONB -- Role capabilities
);

-- Many-to-many relationship between people and roles
CREATE TABLE people_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES people(id), -- Who assigned this role
    primary_role BOOLEAN DEFAULT FALSE, -- Is this the person's primary role?
    start_date DATE,
    end_date DATE, -- For historical tracking
    notes TEXT,
    UNIQUE (person_id, role_id) -- Prevent duplicate role assignments
);

-- Organizations (companies, schools, etc.)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- e.g., 'company', 'school', 'foundation'
    description TEXT,
    website TEXT,
    logo_url TEXT,
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'USA',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    metadata JSONB DEFAULT '{}'::JSONB -- Flexible additional attributes
);

-- People's affiliations with organizations
CREATE TABLE affiliations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title TEXT, -- Position/title at the organization
    start_date DATE,
    end_date DATE, -- For historical tracking
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    UNIQUE (person_id, organization_id, title) WHERE end_date IS NULL -- Prevent duplicate active affiliations
);

-- Global tagging system for categorization
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    category TEXT, -- For grouping tags (e.g., 'interest', 'skill', 'need')
    color TEXT, -- For UI representation
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Authentication triggers and RLS
ALTER TABLE people ENABLE ROW LEVEL SECURITY;

-- Basic RLS policy for people table
CREATE POLICY "People are viewable by authenticated users" 
ON people FOR SELECT 
USING (auth.role() = 'authenticated');

-- Trigger to keep updated_at current
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_people_updated_at
BEFORE UPDATE ON people
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at
BEFORE UPDATE ON organizations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_affiliations_updated_at
BEFORE UPDATE ON affiliations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for performance
CREATE INDEX idx_people_email ON people(email);
CREATE INDEX idx_people_last_name ON people(last_name);
CREATE INDEX idx_people_roles_person ON people_roles(person_id);
CREATE INDEX idx_affiliations_person ON affiliations(person_id);
CREATE INDEX idx_affiliations_organization ON affiliations(organization_id);
```

## Migration 2: Relationship Framework

```sql
-- migration_2_relationship_framework.sql

-- Relationship types to categorize different kinds of connections
CREATE TABLE relationship_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    bidirectional BOOLEAN DEFAULT TRUE, -- Is this relationship reciprocal?
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Core relationship table - the heart of the system
CREATE TABLE relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    to_person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    relationship_type_id UUID NOT NULL REFERENCES relationship_types(id),
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE, -- For historical relationship tracking
    strength_score INT, -- Optional numerical indicator of relationship strength
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'historical', 'potential')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB, -- For flexible relationship attributes
    -- Prevent exact duplicate relationships
    CONSTRAINT unique_active_relationship UNIQUE (from_person_id, to_person_id, relationship_type_id) 
        WHERE status = 'active' AND end_date IS NULL,
    -- Ensure no self-relationships    
    CONSTRAINT no_self_relationships CHECK (from_person_id != to_person_id)
);

-- Relationship milestones/lifecycle events
CREATE TABLE relationship_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- e.g., 'first_meeting', 'major_achievement', 'transition'
    event_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT,
    significance INT, -- 1-10 scale of importance
    created_by UUID REFERENCES people(id),
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Relationship goals tracking
CREATE TABLE relationship_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    target_date DATE,
    completion_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned', 'deferred')),
    priority INT, -- 1-5 scale
    created_by UUID REFERENCES people(id),
    notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Tagging for relationships
CREATE TABLE relationship_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    UNIQUE (relationship_id, tag_id) -- No duplicate tags on relationships
);

-- Interaction tracking for relationship touchpoints
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interaction_type TEXT NOT NULL, -- e.g., 'meeting', 'email', 'phone_call', 'event'
    title TEXT NOT NULL,
    description TEXT,
    scheduled_at TIMESTAMPTZ,
    occurred_at TIMESTAMPTZ,
    duration_minutes INT,
    location TEXT,
    is_planned BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'canceled', 'rescheduled')),
    sentiment_score INT, -- Optional -5 to 5 score on how positive the interaction was
    follow_up_needed BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    follow_up_notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Linking people to interactions
CREATE TABLE interaction_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interaction_id UUID NOT NULL REFERENCES interactions(id) ON DELETE CASCADE,
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    role TEXT, -- Role in this interaction (e.g., 'host', 'attendee')
    attended BOOLEAN DEFAULT NULL, -- Tracks actual attendance
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (interaction_id, person_id) -- Person can only be listed once per interaction
);

-- Contextual notes system
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id) ON DELETE SET NULL,
    is_private BOOLEAN DEFAULT FALSE,
    note_type TEXT NOT NULL DEFAULT 'general' CHECK (note_type IN ('general', 'meeting', 'observation', 'idea', 'followup')),
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Polymorphic relationships for notes (can be attached to people, relationships, interactions, etc.)
CREATE TABLE note_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL, -- 'person', 'relationship', 'interaction', etc.
    entity_id UUID NOT NULL, -- ID of the entity
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    UNIQUE (note_id, entity_type, entity_id) -- Prevent duplicate connections
);

-- Trigger for updated_at columns
CREATE TRIGGER update_relationships_updated_at
BEFORE UPDATE ON relationships
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interactions_updated_at
BEFORE UPDATE ON interactions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for performance
CREATE INDEX idx_relationships_from_person ON relationships(from_person_id);
CREATE INDEX idx_relationships_to_person ON relationships(to_person_id);
CREATE INDEX idx_relationships_type ON relationships(relationship_type_id);
CREATE INDEX idx_relationship_events_relationship ON relationship_events(relationship_id);
CREATE INDEX idx_interactions_created_by ON interactions(created_by);
CREATE INDEX idx_interaction_participants_interaction ON interaction_participants(interaction_id);
CREATE INDEX idx_interaction_participants_person ON interaction_participants(person_id);
CREATE INDEX idx_note_connections_entity ON note_connections(entity_type, entity_id);
```

## Migration 3: Domain-Specific Tables

```sql
-- migration_3_domain_specific.sql

-- MENTORSHIP DOMAIN

-- Student academic profiles
CREATE TABLE student_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    grade_level TEXT,
    cohort_year INT, -- Graduation year
    enrollment_date DATE,
    gpa DECIMAL(3,2),
    academic_standing TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (person_id) -- One profile per student
);

-- Mentor-specific metadata
CREATE TABLE mentor_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    expertise TEXT[],
    max_mentees INT,
    commitment_start DATE,
    commitment_end DATE,
    training_completed BOOLEAN DEFAULT FALSE,
    background_check_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (person_id) -- One profile per mentor
);

-- FUNDRAISING DOMAIN

-- Donor profiles
CREATE TABLE donor_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID REFERENCES people(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    donor_type TEXT NOT NULL CHECK (donor_type IN ('individual', 'organization', 'foundation', 'corporate')),
    donor_level TEXT, -- e.g., 'major', 'regular', 'one-time'
    first_donation_date DATE,
    lifetime_donation_amount DECIMAL(12,2) DEFAULT 0,
    preferred_contact_method TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    tax_exempt_status BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}'::JSONB,
    -- Either person_id OR organization_id must be set, but not both
    CONSTRAINT donor_source_check CHECK (
        (person_id IS NOT NULL AND organization_id IS NULL) OR
        (person_id IS NULL AND organization_id IS NOT NULL)
    ),
    CONSTRAINT unique_donor_profile UNIQUE (COALESCE(person_id, uuid_nil()), COALESCE(organization_id, uuid_nil()))
);

-- Donation transactions
CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donor_profile_id UUID NOT NULL REFERENCES donor_profiles(id) ON DELETE RESTRICT,
    amount DECIMAL(12,2) NOT NULL,
    donation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    donation_type TEXT NOT NULL, -- e.g., 'one-time', 'recurring', 'in-kind'
    payment_method TEXT, -- e.g., 'credit_card', 'check', 'wire_transfer'
    campaign TEXT, -- Associated fundraising campaign
    earmark TEXT, -- Specific designation if any
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES people(id),
    tax_receipt_sent BOOLEAN DEFAULT FALSE,
    tax_receipt_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'refunded', 'failed')),
    metadata JSONB DEFAULT '{}'::JSONB
);

-- COLLEGE GUIDANCE DOMAIN

-- College institution records
CREATE TABLE colleges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    type TEXT, -- e.g., 'public', 'private', 'community'
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'USA',
    website TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::JSONB -- For storing additional details like acceptance rates, etc.
);

-- College applications tracking
CREATE TABLE college_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    college_id UUID NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    application_type TEXT NOT NULL, -- e.g., 'early_decision', 'early_action', 'regular'
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'submitted', 'accepted', 'rejected', 'waitlisted', 'deferred', 'enrolled')),
    application_date DATE, -- When submitted
    decision_date DATE, -- When decision received
    counselor_id UUID REFERENCES people(id), -- College counselor assisting
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deadline DATE,
    is_priority BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::JSONB,
    UNIQUE (student_id, college_id, application_type) -- Prevent duplicate applications of same type
);

-- Activity tracking (extracurriculars, achievements, etc.)
CREATE TABLE student_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    activity_name TEXT NOT NULL,
    description TEXT,
    activity_type TEXT NOT NULL, -- e.g., 'sport', 'club', 'volunteer', 'work', 'honor'
    role TEXT, -- Position or role in the activity
    start_date DATE,
    end_date DATE,
    hours_per_week INT,
    weeks_per_year INT,
    is_leadership BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    metadata JSONB DEFAULT '{}'::JSONB
);

-- CROSS-CUTTING CONCERNS

-- Document/file management
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT,
    file_type TEXT,
    file_size INT, -- In bytes
    upload_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_by UUID REFERENCES people(id),
    document_type TEXT NOT NULL, -- e.g., 'transcript', 'recommendation', 'agreement', 'photo'
    is_private BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Polymorphic relationships for documents
CREATE TABLE document_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL, -- 'person', 'relationship', 'donation', etc.
    entity_id UUID NOT NULL, -- ID of the entity
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    UNIQUE (document_id, entity_type, entity_id) -- Prevent duplicate connections
);

-- Task management system
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_by UUID REFERENCES people(id),
    assigned_to UUID REFERENCES people(id),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'deferred', 'canceled')),
    task_type TEXT, -- Category of task
    reminder_date TIMESTAMPTZ,
    recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern TEXT, -- e.g., 'daily', 'weekly', 'monthly'
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Polymorphic relationships for tasks
CREATE TABLE task_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL, -- 'person', 'relationship', 'donation', etc.
    entity_id UUID NOT NULL, -- ID of the entity
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    UNIQUE (task_id, entity_type, entity_id) -- Prevent duplicate connections
);

-- Updated_at triggers
CREATE TRIGGER update_student_profiles_updated_at
BEFORE UPDATE ON student_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mentor_profiles_updated_at
BEFORE UPDATE ON mentor_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donor_profiles_updated_at
BEFORE UPDATE ON donor_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donations_updated_at
BEFORE UPDATE ON donations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_colleges_updated_at
BEFORE UPDATE ON colleges
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_college_applications_updated_at
BEFORE UPDATE ON college_applications
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_activities_updated_at
BEFORE UPDATE ON student_activities
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_student_profiles_person ON student_profiles(person_id);
CREATE INDEX idx_mentor_profiles_person ON mentor_profiles(person_id);
CREATE INDEX idx_donor_profiles_person ON donor_profiles(person_id);
CREATE INDEX idx_donor_profiles_organization ON donor_profiles(organization_id);
CREATE INDEX idx_donations_donor ON donations(donor_profile_id);
CREATE INDEX idx_college_applications_student ON college_applications(student_id);
CREATE INDEX idx_college_applications_college ON college_applications(college_id);
CREATE INDEX idx_student_activities_student ON student_activities(student_id);
CREATE INDEX idx_document_connections_entity ON document_connections(entity_type, entity_id);
CREATE INDEX idx_task_connections_entity ON task_connections(entity_type, entity_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
```

## Migration 4: Relationship Intelligence

```sql
-- migration_4_relationship_intelligence.sql

-- Relationship health scoring
CREATE TABLE relationship_health_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
    score_date DATE NOT NULL DEFAULT CURRENT_DATE,
    engagement_score INT, -- 1-10 score of active engagement
    alignment_score INT, -- 1-10 score of goal alignment
    trust_score INT, -- 1-10 score of trust
    overall_score INT, -- 1-10 composite score
    calculated_by TEXT DEFAULT 'system', -- 'system', 'manual', 'ai'
    created_by UUID REFERENCES people(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::JSONB,
    -- Ensure only one score per relationship per day
    UNIQUE (relationship_id, score_date)
);

-- Interaction patterns for relationship intelligence
CREATE TABLE interaction_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
    pattern_type TEXT NOT NULL, -- e.g., 'frequency', 'response_time', 'initiative'
    pattern_value JSONB NOT NULL, -- Flexible structure for different pattern types
    start_date DATE,
    end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    confidence_score DECIMAL(3,2), -- 0-1 confidence in pattern accuracy
    identified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    identified_by TEXT DEFAULT 'system', -- 'system', 'manual', 'ai'
    notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Relationship network insights
CREATE TABLE relationship_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    insight_type TEXT NOT NULL, -- e.g., 'connection_opportunity', 'risk_alert', 'strength_recognition'
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    affected_entities JSONB NOT NULL, -- Flexible structure to represent various entity combinations
    urgency TEXT NOT NULL DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high', 'critical')),
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'acknowledged', 'actioned', 'dismissed', 'expired')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    created_by TEXT DEFAULT 'system', -- 'system', 'manual', 'ai'
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES people(id),
    actioned_at TIMESTAMPTZ,
    actioned_by UUID REFERENCES people(id),
    action_taken TEXT,
    confidence_score DECIMAL(3,2), -- 0-1 confidence in insight accuracy
    metadata JSONB DEFAULT '{}'::JSONB
);

-- User notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL, -- e.g., 'relationship_alert', 'task_reminder', 'achievement'
    entity_type TEXT, -- Optional reference to entity type
    entity_id UUID, -- Optional reference to entity ID
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    is_actionable BOOLEAN DEFAULT FALSE,
    action_url TEXT, -- Deep link to take action
    expires_at TIMESTAMPTZ,
    priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    metadata JSONB DEFAULT '{}'::JSONB
);

-- User preferences for relationship intelligence
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    preference_category TEXT NOT NULL, -- e.g., 'notifications', 'privacy', 'insights'
    preferences JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (person_id, preference_category)
);

-- Event log for system activities and relationship intelligence
CREATE TABLE event_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type TEXT NOT NULL,
    entity_type TEXT,
    entity_id UUID,
    user_id UUID REFERENCES people(id),
    event_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    details JSONB NOT NULL DEFAULT '{}'::JSONB,
    ip_address TEXT,
    user_agent TEXT
);

-- Visual representation for UI dashboards
CREATE TABLE relationship_visualizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visualization_type TEXT NOT NULL, -- e.g., 'network', 'timeline', 'heatmap'
    title TEXT NOT NULL,
    description TEXT,
    configuration JSONB NOT NULL, -- Flexible structure for visualization settings
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES people(id),
    is_public BOOLEAN DEFAULT FALSE,
    thumbnail_url TEXT,
    last_refreshed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Create stored functions for relationship intelligence features

-- Function to calculate relationship strength
CREATE OR REPLACE FUNCTION calculate_relationship_strength(
    p_relationship_id UUID
)
RETURNS INT AS $$
DECLARE
    strength INT;
BEGIN
    -- Sophisticated algorithm would consider:
    -- 1. Recency, frequency, and depth of interactions
    -- 2. Reciprocity in communication
    -- 3. Sentiment in notes and interactions
    -- 4. Goal achievement rate
    -- 5. Explicit feedback
    
    -- Simplified placeholder implementation:
    SELECT 
        GREATEST(1, LEAST(10, 
            5 + 
            -- Add points for recent interactions
            (SELECT COUNT(*) FROM interactions i
             JOIN interaction_participants ip ON i.id = ip.interaction_id
             WHERE ip.person_id IN (
                 SELECT from_person_id FROM relationships WHERE id = p_relationship_id
                 UNION
                 SELECT to_person_id FROM relationships WHERE id = p_relationship_id
             )
             AND i.occurred_at > NOW() - INTERVAL '90 days'
            ) / 2
            -- Could subtract points for negative indicators
        ))
    INTO strength;
    
    RETURN COALESCE(strength, 5); -- Default middle value if calculation fails
END;
$$ LANGUAGE plpgsql;

-- Function to identify potential connections
CREATE OR REPLACE FUNCTION identify_potential_connections()
RETURNS TABLE(
    from_person_id UUID,
    to_person_id UUID,
    connection_strength DECIMAL,
    connection_reason TEXT
) AS $$
BEGIN
    -- This would use a sophisticated algorithm to identify:
    -- 1. Second-degree connections
    -- 2. Shared interests or goals
    -- 3. Complementary skills or needs
    -- 4. Historical interaction patterns
    
    -- Simplified placeholder implementation:
    RETURN QUERY
    WITH common_connections AS (
        SELECT 
            r1.from_person_id as person_a,
            r2.to_person_id as person_b,
            COUNT(*) as common_count
        FROM relationships r1
        JOIN relationships r2 ON r1.to_person_id = r2.from_person_id
        WHERE 
            r1.status = 'active' AND 
            r2.status = 'active' AND
            r1.from_person_id != r2.to_person_id AND
            NOT EXISTS (
                SELECT 1 FROM relationships r3
                WHERE 
                    (r3.from_person_id = r1.from_person_id AND r3.to_person_id = r2.to_person_id)
                    OR
                    (r3.from_person_id = r2.to_person_id AND r3.to_person_id = r1.from_person_id)
            )
        GROUP BY r1.from_person_id, r2.to_person_id
        HAVING COUNT(*) > 2 -- Only suggest if at least 3 common connections
    )
    SELECT 
        cc.person_a,
        cc.person_b,
        cc.common_count::DECIMAL / 10, -- Simple strength score
        'Common connections through ' || 
            (SELECT COUNT(*) || ' people' FROM common_connections 
             WHERE person_a = cc.person_a AND person_b = cc.person_b)
    FROM common_connections cc
    ORDER BY cc.common_count DESC
    LIMIT 100; -- Reasonable limit for batch processing
END;
$$ LANGUAGE plpgsql;

-- Create updated_at triggers
CREATE TRIGGER update_user_preferences_updated_at
BEFORE UPDATE ON user_preferences
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_relationship_visualizations_updated_at
BEFORE UPDATE ON relationship_visualizations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_relationship_health_scores_relationship ON relationship_health_scores(relationship_id);
CREATE INDEX idx_interaction_patterns_relationship ON interaction_patterns(relationship_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_read_status ON notifications(recipient_id) WHERE read_at IS NULL;
CREATE INDEX idx_event_log_entity ON event_log(entity_type, entity_id);
CREATE INDEX idx_event_log_user ON event_log(user_id);
CREATE INDEX idx_event_log_time ON event_log(event_time);
```

## Migration 5: Views and Advanced Functions

```sql
-- migration_5_views_and_functions.sql

-- 360-degree view of a person
CREATE OR REPLACE VIEW person_360_view AS
SELECT 
    p.id,
    p.first_name,
    p.last_name,
    p.email,
    p.status,
    -- Roles information
    ARRAY(
        SELECT r.name 
        FROM people_roles pr
        JOIN roles r ON pr.role_id = r.id
        WHERE pr.person_id = p.id
    ) as roles,
    -- Primary role
    (
        SELECT r.name 
        FROM people_roles pr
        JOIN roles r ON pr.role_id = r.id
        WHERE pr.person_id = p.id AND pr.primary_role = TRUE
        LIMIT 1
    ) as primary_role,
    -- Is student?
    EXISTS(
        SELECT 1 FROM student_profiles sp WHERE sp.person_id = p.id
    ) as is_student,
    -- Is mentor?
    EXISTS(
        SELECT 1 FROM mentor_profiles mp WHERE mp.person_id = p.id
    ) as is_mentor,
    -- Is donor?
    EXISTS(
        SELECT 1 FROM donor_profiles dp WHERE dp.person_id = p.id
    ) as is_donor,
    -- Organization affiliations
    ARRAY(
        SELECT o.name 
        FROM affiliations a
        JOIN organizations o ON a.organization_id = o.id
        WHERE a.person_id = p.id AND (a.end_date IS NULL OR a.end_date > CURRENT_DATE)
    ) as organizations,
    -- Relationships count (outgoing)
    (
        SELECT COUNT(*) 
        FROM relationships r 
        WHERE r.from_person_id = p.id AND r.status = 'active'
    ) as outgoing_relationships_count,
    -- Relationships count (incoming)
    (
        SELECT COUNT(*) 
        FROM relationships r 
        WHERE r.to_person_id = p.id AND r.status = 'active'
    ) as incoming_relationships_count,
    -- Recent interactions count
    (
        SELECT COUNT(*) 
        FROM interactions i
        JOIN interaction_participants ip ON i.id = ip.interaction_id
        WHERE ip.person_id = p.id AND i.occurred_at > NOW() - INTERVAL '90 days'
    ) as recent_interactions_count,
    -- Open tasks count
    (
        SELECT COUNT(*) 
        FROM tasks t
        WHERE t.assigned_to = p.id AND t.status IN ('open', 'in_progress') 
    ) as open_tasks_count,
    -- Notes count
    (
        SELECT COUNT(*) 
        FROM notes n
        JOIN note_connections nc ON n.id = nc.note_id
        WHERE nc.entity_type = 'person' AND nc.entity_id = p.id
    ) as notes_count,
    -- Last interaction date
    (
        SELECT MAX(i.occurred_at)
        FROM interactions i
        JOIN interaction_participants ip ON i.id = ip.interaction_id
        WHERE ip.person_id = p.id
    ) as last_interaction_date,
    -- Specific profile data based on roles
    CASE 
        WHEN EXISTS(SELECT 1 FROM student_profiles sp WHERE sp.person_id = p.id) THEN
            jsonb_build_object(
                'grade_level', (SELECT grade_level FROM student_profiles WHERE person_id = p.id),
                'cohort_year', (SELECT cohort_year FROM student_profiles WHERE person_id = p.id),
                'gpa', (SELECT gpa FROM student_profiles WHERE person_id = p.id)
            )
        WHEN EXISTS(SELECT 1 FROM mentor_profiles mp WHERE mp.person_id = p.id) THEN
            jsonb_build_object(
                'expertise', (SELECT expertise FROM mentor_profiles WHERE person_id = p.id),
                'max_mentees', (SELECT max_mentees FROM mentor_profiles WHERE person_id = p.id)
            )
        WHEN EXISTS(SELECT 1 FROM donor_profiles dp WHERE dp.person_id = p.id) THEN
            jsonb_build_object(
                'donor_type', (SELECT donor_type FROM donor_profiles WHERE person_id = p.id),
                'lifetime_donation', (SELECT lifetime_donation_amount FROM donor_profiles WHERE person_id = p.id)
            )
        ELSE '{}'::jsonb
    END as role_specific_data,
    p.created_at,
    p.updated_at,
    p.last_active_at
FROM people p;

-- Relationship health view
CREATE OR REPLACE VIEW relationship_health_view AS
SELECT 
    r.id as relationship_id,
    r.from_person_id,
    fp.first_name as from_first_name,
    fp.last_name as from_last_name,
    r.to_person_id,
    tp.first_name as to_first_name,
    tp.last_name as to_last_name,
    rt.name as relationship_type,
    r.status,
    r.start_date,
    r.end_date,
    -- Latest health score
    (
        SELECT rhs.overall_score
        FROM relationship_health_scores rhs
        WHERE rhs.relationship_id = r.id
        ORDER BY rhs.score_date DESC
        LIMIT 1
    ) as current_health_score,
    -- Score trend (positive/negative/stable)
    (
        WITH scores AS (
            SELECT 
                rhs.score_date,
                rhs.overall_score,
                LAG(rhs.overall_score) OVER (ORDER BY rhs.score_date) as prev_score
            FROM relationship_health_scores rhs
            WHERE rhs.relationship_id = r.id
            ORDER BY rhs.score_date DESC
            LIMIT 5
        )
        SELECT 
            CASE 
                WHEN AVG(score - prev_score) > 0.5 THEN 'improving'
                WHEN AVG(score - prev_score) < -0.5 THEN 'declining'
                ELSE 'stable'
            END
        FROM scores
        WHERE prev_score IS NOT NULL
    ) as health_trend,
    -- Recent interaction count
    (
        SELECT COUNT(*)
        FROM interactions i
        JOIN interaction_participants ip1 ON i.id = ip1.interaction_id
        JOIN interaction_participants ip2 ON i.id = ip2.interaction_id
        WHERE 
            ip1.person_id = r.from_person_id AND 
            ip2.person_id = r.to_person_id AND
            i.occurred_at > NOW() - INTERVAL '90 days'
    ) as recent_interaction_count,
    -- Days since last interaction
    (
        SELECT 
            EXTRACT(DAY FROM NOW() - MAX(i.occurred_at))::INT
        FROM interactions i
        JOIN interaction_participants ip1 ON i.id = ip1.interaction_id
        JOIN interaction_participants ip2 ON i.id = ip2.interaction_id
        WHERE 
            ip1.person_id = r.from_person_id AND 
            ip2.person_id = r.to_person_id
    ) as days_since_last_interaction,
    -- Open goals count
    (
        SELECT COUNT(*)
        FROM relationship_goals rg
        WHERE rg.relationship_id = r.id AND rg.status = 'active'
    ) as open_goals_count,
    -- Relationship duration in days
    CASE 
        WHEN r.end_date IS NOT NULL THEN 
            (r.end_date - r.start_date)
        ELSE
            (CURRENT_DATE - r.start_date)
    END as relationship_duration_days
FROM relationships r
JOIN people fp ON r.from_person_id = fp.id
JOIN people tp ON r.to_person_id = tp.id
JOIN relationship_types rt ON r.relationship_type_id = rt.id;

-- Interaction feed view
CREATE OR REPLACE VIEW interaction_feed_view AS
SELECT 
    i.id as interaction_id,
    i.interaction_type,
    i.title,
    i.description,
    i.occurred_at,
    i.status,
    i.sentiment_score,
    -- Participants list
    ARRAY(
        SELECT jsonb_build_object(
            'id', p.id,
            'name', p.first_name || ' ' || p.last_name,
            'role', ip.role,
            'attended', ip.attended
        )
        FROM interaction_participants ip
        JOIN people p ON ip.person_id = p.id
        WHERE ip.interaction_id = i.id
    ) as participants,
    -- Number of notes
    (
        SELECT COUNT(*)
        FROM notes n
        JOIN note_connections nc ON n.id = nc.note_id
        WHERE nc.entity_type = 'interaction' AND nc.entity_id = i.id
    ) as notes_count,
    -- Has follow-up
    i.follow_up_needed,
    i.follow_up_date,
    -- Creator info
    cp.first_name || ' ' || cp.last_name as created_by_name,
    i.created_at,
    i.duration_minutes
FROM interactions i
LEFT JOIN people cp ON i.created_by = cp.id
ORDER BY i.occurred_at DESC;

-- Alumni continuity view
CREATE OR REPLACE VIEW alumni_continuity_view AS
SELECT 
    p.id as person_id,
    p.first_name,
    p.last_name,
    p.email,
    sp.cohort_year,
    -- Current college if applicable
    (
        SELECT c.name
        FROM college_applications ca
        JOIN colleges c ON ca.college_id = c.id
        WHERE ca.student_id = p.id AND ca.status = 'enrolled'
        ORDER BY ca.decision_date DESC
        LIMIT 1
    ) as current_college,
    -- Mentor relationship
    (
        SELECT jsonb_build_object(
            'mentor_id', r.from_person_id,
            'mentor_name', mp.first_name || ' ' || mp.last_name,
            'relationship_id', r.id,
            'start_date', r.start_date,
            'status', r.status
        )
        FROM relationships r
        JOIN people mp ON r.from_person_id = mp.id
        JOIN relationship_types rt ON r.relationship_type_id = rt.id
        WHERE r.to_person_id = p.id AND rt.name = 'mentor'
        ORDER BY r.start_date DESC
        LIMIT 1
    ) as mentor_info,
    -- Last interaction date
    (
        SELECT MAX(i.occurred_at)
        FROM interactions i
        JOIN interaction_participants ip ON i.id = ip.interaction_id
        WHERE ip.person_id = p.id
    ) as last_interaction_date,
    -- Days since last interaction
    (
        SELECT EXTRACT(DAY FROM NOW() - MAX(i.occurred_at))::INT
        FROM interactions i
        JOIN interaction_participants ip ON i.id = ip.interaction_id
        WHERE ip.person_id = p.id
    ) as days_since_last_interaction,
    -- Engagement level (based on interaction frequency)
    CASE 
        WHEN (
            SELECT COUNT(*)
            FROM interactions i
            JOIN interaction_participants ip ON i.id = ip.interaction_id
            WHERE ip.person_id = p.id AND i.occurred_at > NOW() - INTERVAL '180 days'
        ) > 5 THEN 'high'
        WHEN (
            SELECT COUNT(*)
            FROM interactions i
            JOIN interaction_participants ip ON i.id = ip.interaction_id
            WHERE ip.person_id = p.id AND i.occurred_at > NOW() - INTERVAL '180 days'
        ) > 2 THEN 'medium'
        WHEN (
            SELECT COUNT(*)
            FROM interactions i
            JOIN interaction_participants ip ON i.id = ip.interaction_id
            WHERE ip.person_id = p.id AND i.occurred_at > NOW() - INTERVAL '180 days'
        ) > 0 THEN 'low'
        ELSE 'none'
    END as engagement_level,
    -- Is donor
    EXISTS(
        SELECT 1 FROM donor_profiles dp WHERE dp.person_id = p.id
    ) as is_donor,
    -- Is mentor (reverse mentorship)
    EXISTS(
        SELECT 1 
        FROM relationships r
        JOIN relationship_types rt ON r.relationship_type_id = rt.id
        WHERE r.from_person_id = p.id AND rt.name = 'mentor'
    ) as is_mentor,
    -- Number of other alumni connections
    (
        SELECT COUNT(*)
        FROM relationships r
        JOIN people p2 ON r.to_person_id = p2.id
        JOIN student_profiles sp2 ON p2.id = sp2.person_id
        WHERE 
            r.from_person_id = p.id AND 
            r.status = 'active' AND
            sp2.cohort_year IS NOT NULL
    ) as alumni_connections_count
FROM people p
JOIN student_profiles sp ON p.id = sp.person_id
WHERE sp.cohort_year IS NOT NULL AND sp.cohort_year < EXTRACT(YEAR FROM CURRENT_DATE);

-- Function to find relationship paths between people
CREATE OR REPLACE FUNCTION find_relationship_paths(
    start_person_id UUID,
    end_person_id UUID,
    max_distance INT DEFAULT 3
)
RETURNS TABLE(
    path UUID[],
    distance INT,
    path_description TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE
    connection_paths(path, distance, last_person, path_description) AS (
        -- Base case: direct connections from start_person
        SELECT 
            ARRAY[start_person_id, r.to_person_id]::UUID[],
            1,
            r.to_person_id,
            ARRAY[
                (SELECT first_name || ' ' || last_name FROM people WHERE id = start_person_id) || 
                ' → ' || rt.name || ' → ' || 
                (SELECT first_name || ' ' || last_name FROM people WHERE id = r.to_person_id)
            ]::TEXT[]
        FROM relationships r
        JOIN relationship_types rt ON r.relationship_type_id = rt.id
        WHERE r.from_person_id = start_person_id AND r.status = 'active'
        
        UNION
        
        -- Recursive case: extend paths that haven't reached end_person yet
        SELECT 
            cp.path || r.to_person_id,
            cp.distance + 1,
            r.to_person_id,
            cp.path_description || (
                (SELECT first_name || ' ' || last_name FROM people WHERE id = cp.last_person) || 
                ' → ' || rt.name || ' → ' || 
                (SELECT first_name || ' ' || last_name FROM people WHERE id = r.to_person_id)
            )
        FROM connection_paths cp
        JOIN relationships r ON cp.last_person = r.from_person_id
        JOIN relationship_types rt ON r.relationship_type_id = rt.id
        WHERE 
            r.status = 'active' AND
            r.to_person_id <> ALL(cp.path) AND -- Avoid cycles
            cp.distance < max_distance -- Limit path length
    )
    SELECT 
        cp.path,
        cp.distance,
        cp.path_description
    FROM connection_paths cp
    WHERE cp.last_person = end_person_id
    ORDER BY cp.distance
    LIMIT 10; -- Reasonable limit for typical usage
END;
$$ LANGUAGE plpgsql;

-- Function to calculate donor engagement score
CREATE OR REPLACE FUNCTION calculate_donor_engagement_score(
    donor_id UUID
)
RETURNS INT AS $$
DECLARE
    engagement_score INT;
BEGIN
    -- Comprehensive scoring would consider:
    -- 1. Recency and frequency of donations
    -- 2. Trend in donation amounts
    -- 3. Event attendance and participation
    -- 4. Communication responsiveness
    -- 5. Volunteering and non-financial engagement
    
    -- Simplified implementation for demonstration:
    SELECT 
        GREATEST(1, LEAST(10, 
            5 + 
            -- Recent donations boost score
            (SELECT COUNT(*) FROM donations d
             JOIN donor_profiles dp ON d.donor_profile_id = dp.id
             WHERE (dp.person_id = donor_id OR dp.organization_id = 
                  (SELECT organization_id FROM affiliations WHERE person_id = donor_id AND is_primary = TRUE LIMIT 1))
             AND d.donation_date > CURRENT_DATE - INTERVAL '1 year'
            ) 
            +
            -- Recent interactions boost score
            (SELECT COUNT(*) FROM interactions i
             JOIN interaction_participants ip ON i.id = ip.interaction_id
             WHERE ip.person_id = donor_id
             AND i.occurred_at > CURRENT_DATE - INTERVAL '180 days'
            ) / 2
            -- Scale could be adjusted based on organizational norms
        ))
    INTO engagement_score;
    
    RETURN COALESCE(engagement_score, 5); -- Default middle value if calculation fails
END;
$$ LANGUAGE plpgsql;

-- Function to identify at-risk relationships
CREATE OR REPLACE FUNCTION identify_at_risk_relationships()
RETURNS TABLE(
    relationship_id UUID,
    from_person_name TEXT,
    to_person_name TEXT,
    relationship_type TEXT,
    risk_score INT,
    risk_factors TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    WITH relationship_risks AS (
        SELECT
            r.id,
            -- Person names
            (SELECT first_name || ' ' || last_name FROM people WHERE id = r.from_person_id) as from_name,
            (SELECT first_name || ' ' || last_name FROM people WHERE id = r.to_person_id) as to_name,
            -- Relationship type
            (SELECT name FROM relationship_types WHERE id = r.relationship_type_id) as rel_type,
            -- Risk indicators
            CASE WHEN (
                SELECT MAX(occurred_at) FROM interactions i
                JOIN interaction_participants ip1 ON i.id = ip1.interaction_id
                JOIN interaction_participants ip2 ON i.id = ip2.interaction_id
                WHERE ip1.person_id = r.from_person_id AND ip2.person_id = r.to_person_id
            ) < NOW() - INTERVAL '90 days' THEN
                TRUE
            ELSE
                FALSE
            END as no_recent_interactions,
            
            CASE WHEN (
                SELECT COUNT(*) FROM interactions i
                JOIN interaction_participants ip1 ON i.id = ip1.interaction_id
                JOIN interaction_participants ip2 ON i.id = ip2.interaction_id
                WHERE 
                    ip1.person_id = r.from_person_id AND 
                    ip2.person_id = r.to_person_id AND
                    i.occurred_at > NOW() - INTERVAL '180 days'
            ) < 2 THEN
                TRUE
            ELSE
                FALSE
            END as low_interaction_frequency,
            
            CASE WHEN (
                SELECT AVG(sentiment_score) FROM interactions i
                JOIN interaction_participants ip1 ON i.id = ip1.interaction_id
                JOIN interaction_participants ip2 ON i.id = ip2.interaction_id
                WHERE 
                    ip1.person_id = r.from_person_id AND 
                    ip2.person_id = r.to_person_id AND
                    i.occurred_at > NOW() - INTERVAL '180 days' AND
                    i.sentiment_score IS NOT NULL
            ) < 0 THEN
                TRUE
            ELSE
                FALSE
            END as negative_sentiment,
            
            CASE WHEN (
                SELECT COUNT(*) FROM relationship_goals
                WHERE relationship_id = r.id AND status = 'active'
            ) = 0 THEN
                TRUE
            ELSE
                FALSE
            END as no_active_goals,
            
            CASE WHEN (
                SELECT COUNT(*) FROM relationship_goals
                WHERE 
                    relationship_id = r.id AND 
                    status = 'active' AND
                    target_date < CURRENT_DATE
            ) > 0 THEN
                TRUE
            ELSE
                FALSE
            END as overdue_goals
        FROM relationships r
        WHERE r.status = 'active'
    )
    SELECT
        rr.id,
        rr.from_name,
        rr.to_name,
        rr.rel_type,
        -- Calculate risk score (1-10)
        GREATEST(1, LEAST(10, 
            3 + 
            (CASE WHEN rr.no_recent_interactions THEN 3 ELSE 0 END) +
            (CASE WHEN rr.low_interaction_frequency THEN 2 ELSE 0 END) +
            (CASE WHEN rr.negative_sentiment THEN 2 ELSE 0 END) +
            (CASE WHEN rr.no_active_goals THEN 1 ELSE 0 END) +
            (CASE WHEN rr.overdue_goals THEN 2 ELSE 0 END)
        )) as risk_score,
        -- Compile risk factors
        ARRAY_REMOVE(ARRAY[
            CASE WHEN rr.no_recent_interactions THEN 'No interactions in last 90 days' ELSE NULL END,
            CASE WHEN rr.low_interaction_frequency THEN 'Low interaction frequency' ELSE NULL END,
            CASE WHEN rr.negative_sentiment THEN 'Negative sentiment in recent interactions' ELSE NULL END,
            CASE WHEN rr.no_active_goals THEN 'No active relationship goals' ELSE NULL END,
            CASE WHEN rr.overdue_goals THEN 'Overdue relationship goals' ELSE NULL END
        ], NULL) as risk_factors
    FROM relationship_risks rr
    WHERE 
        rr.no_recent_interactions OR
        rr.low_interaction_frequency OR
        rr.negative_sentiment OR
        rr.no_active_goals OR
        rr.overdue_goals
    ORDER BY risk_score DESC;
END;
$$ LANGUAGE plpgsql;
```

## Design Rationale

The schema design reflects several key architectural decisions to support the relationship-centered philosophy:

1. **Person-Centric Foundation**
   - All entities center around the `people` table, with polymorphic relationships allowing any entity to connect to any other
   - Role flexibility through many-to-many `people_roles` rather than separate user tables
   - Comprehensive profile data supporting multiple perspectives on the same person

2. **Relationship Intelligence Core**
   - Sophisticated relationship tracking with bidirectional connections
   - Health scoring, interaction patterns, and relationship milestones
   - Cross-boundary relationship visualization and insight generation

3. **Role-Specific Extensions**
   - Domain-specific tables for mentorship, fundraising, and college guidance
   - Unified design allowing seamless transitions between roles
   - Specialized metadata for each role while maintaining a common identity

4. **Temporal Awareness**
   - Historical tracking throughout the system (relationships, interactions, affiliations)
   - Explicit tracking of when relationships begin and end
   - Activity timelines and engagement patterns

5. **Interaction Tracking**
   - Comprehensive system for recording all forms of communication
   - Sentiment analysis and follow-up tracking
   - Connection to relationship health and strength metrics

6. **Insight Generation**
   - Stored functions for relationship strength calculation
   - Potential connection identification
   - At-risk relationship identification
   - Engagement scoring

7. **Views for Cross-Cutting Concerns**
   - 360-degree person view combining all roles
   - Relationship health dashboard
   - Interaction feed
   - Alumni continuity tracking

This schema provides a solid foundation for building a relationship-centered platform that supports the multi-role experience described in the UI/UX documents, with particular attention to relationship continuity, cross-boundary awareness, and unified stakeholder experiences.