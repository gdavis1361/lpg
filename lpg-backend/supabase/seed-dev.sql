-- Version: 2.0 (Refactored May 2025)
-- seed.sql for Chattanooga Prep Relationship Platform
-- Provides essential lookup data and sample records for development
-- Requires tables created by migrations: roles, relationship_types, tags, organizations, people, people_roles, affiliations, people_tags, relationships, interactions, interaction_participants, interaction_tags.

BEGIN;

RAISE NOTICE 'Starting seed script execution...';

-- Create temporary helper functions for this seeding operation only
CREATE OR REPLACE FUNCTION _seed_helper_create_person_if_not_exists(
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_phone TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_person_id UUID;
BEGIN
  INSERT INTO people (first_name, last_name, email, phone, created_at, updated_at)
  VALUES (p_first_name, p_last_name, p_email, p_phone, NOW(), NOW())
  ON CONFLICT (email) DO NOTHING
  RETURNING id INTO v_person_id;

  IF v_person_id IS NULL THEN
    SELECT id INTO v_person_id FROM people WHERE email = p_email;
  END IF;

  RETURN v_person_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _seed_helper_assign_role_to_person(
  p_person_id UUID,
  p_role_id UUID,
  p_is_primary BOOLEAN DEFAULT false
) RETURNS VOID AS $$
BEGIN
  IF p_person_id IS NULL OR p_role_id IS NULL THEN
    RAISE WARNING '_seed_helper_assign_role_to_person: person_id or role_id is NULL. Person ID: %, Role ID: %', p_person_id, p_role_id;
    RETURN;
  END IF;
  INSERT INTO people_roles (person_id, role_id, primary_role, assigned_at)
  VALUES (p_person_id, p_role_id, p_is_primary, NOW())
  ON CONFLICT (person_id, role_id) DO UPDATE SET
    primary_role = EXCLUDED.primary_role,
    assigned_at = NOW(); -- Update assigned_at if role details change
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _seed_helper_assign_role_to_person_by_name(
  p_person_id UUID,
  p_role_name TEXT,
  p_is_primary BOOLEAN DEFAULT false
) RETURNS VOID AS $$
DECLARE
  v_role_id UUID;
BEGIN
  IF p_person_id IS NULL THEN
    RAISE WARNING '_seed_helper_assign_role_to_person_by_name: person_id is NULL for role %', p_role_name;
    RETURN;
  END IF;
  SELECT id INTO v_role_id FROM roles WHERE name = p_role_name;

  IF v_role_id IS NULL THEN
    RAISE WARNING 'Role "%" not found, cannot assign to person_id %', p_role_name, p_person_id;
    RETURN;
  END IF;

  PERFORM _seed_helper_assign_role_to_person(p_person_id, v_role_id, p_is_primary);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _seed_helper_add_affiliation_to_person_by_org_name(
  p_person_id UUID,
  p_organization_name TEXT,
  p_role_in_org TEXT,
  p_start_date_interval_text TEXT
) RETURNS VOID AS $$
DECLARE
  v_organization_id UUID;
  v_start_date DATE;
BEGIN
  IF p_person_id IS NULL THEN
    RAISE WARNING '_seed_helper_add_affiliation_to_person_by_org_name: person_id is NULL for org %', p_organization_name;
    RETURN;
  END IF;
  SELECT id INTO v_organization_id FROM organizations WHERE name = p_organization_name;

  IF v_organization_id IS NULL THEN
    RAISE WARNING 'Organization "%" not found, cannot create affiliation for person_id %', p_organization_name, p_person_id;
    RETURN;
  END IF;

  v_start_date := CURRENT_DATE - CAST(p_start_date_interval_text AS INTERVAL);

  INSERT INTO affiliations (person_id, organization_id, role, start_date, created_at)
  VALUES (p_person_id, v_organization_id, p_role_in_org, v_start_date, NOW())
  ON CONFLICT (person_id, organization_id, role) DO UPDATE SET -- Assuming role in org is part of uniqueness
    start_date = EXCLUDED.start_date;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _seed_helper_add_tag_to_person_by_name(
  p_person_id UUID,
  p_tag_name TEXT
) RETURNS VOID AS $$
DECLARE
  v_tag_id UUID;
BEGIN
  IF p_person_id IS NULL THEN
    RAISE WARNING '_seed_helper_add_tag_to_person_by_name: person_id is NULL for tag %', p_tag_name;
    RETURN;
  END IF;
  SELECT id INTO v_tag_id FROM tags WHERE name = p_tag_name;

  IF v_tag_id IS NULL THEN
    RAISE WARNING 'Tag "%" not found, cannot assign to person_id %', p_tag_name, p_person_id;
    RETURN;
  END IF;

  INSERT INTO people_tags (person_id, tag_id, assigned_at)
  VALUES (p_person_id, v_tag_id, NOW())
  ON CONFLICT (person_id, tag_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE 'Helper functions created.';

-- 1. Seed roles
RAISE NOTICE 'Seeding roles...';
INSERT INTO roles (name, description, permissions, created_at) VALUES
  ('admin', 'System administrators with full access', '{"all": true}'::jsonb, NOW()),
  ('staff', 'School staff members', '{"view_people": true, "edit_people": true, "view_interactions": true, "log_interactions": true}'::jsonb, NOW()),
  ('mentor', 'External mentors supporting students', '{"view_assigned_students": true, "log_interactions": true}'::jsonb, NOW()),
  ('donor', 'Financial supporters of the school', '{"view_impact": true}'::jsonb, NOW()),
  ('alumni', 'Former students', '{"view_events": true, "view_network": true}'::jsonb, NOW()),
  ('student', 'Current students', '{"view_profile": true}'::jsonb, NOW())
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  permissions = EXCLUDED.permissions,
  updated_at = NOW(); -- Ensure updated_at is set on conflict update

-- 2. Seed relationship types
RAISE NOTICE 'Seeding relationship types...';
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'relationship_types') THEN
    INSERT INTO relationship_types (code, name, description, created_at) VALUES
      ('mentor', 'Mentor', 'Mentoring relationship between mentor and student', NOW()),
      ('donor', 'Donor', 'Financial supporter relationship', NOW()),
      ('alumni', 'Alumni', 'Former student relationship', NOW()),
      ('staff', 'Staff', 'School staff relationship', NOW()),
      ('family', 'Family', 'Family relationship', NOW()),
      ('peer', 'Peer', 'Peer-to-peer relationship between students', NOW())
    ON CONFLICT (code) DO UPDATE SET
      name = EXCLUDED.name,
      description = EXCLUDED.description,
      updated_at = NOW(); -- Ensure updated_at is set
  ELSE
    RAISE NOTICE 'Table relationship_types does not exist, skipping seeding.';
  END IF;
END $$;

-- 3. Seed tags for categorization
RAISE NOTICE 'Seeding tags...';
INSERT INTO tags (name, category, color, created_at) VALUES
  ('STEM', 'interest', '#4CAF50', NOW()),
  ('Arts', 'interest', '#9C27B0', NOW()),
  ('Sports', 'interest', '#2196F3', NOW()),
  ('College-bound', 'status', '#FF9800', NOW()),
  ('First-generation', 'status', '#795548', NOW()),
  ('High-potential', 'assessment', '#F44336', NOW()),
  ('Needs-support', 'assessment', '#607D8B', NOW()),
  ('Mentorship', 'activity', '#3F51B5', NOW()),
  ('Fundraising', 'activity', '#00BCD4', NOW()),
  ('Academic', 'category', '#009688', NOW())
ON CONFLICT (name) DO UPDATE SET
  category = EXCLUDED.category,
  color = EXCLUDED.color,
  updated_at = NOW(); -- Ensure updated_at is set

-- 4. Seed organizations
RAISE NOTICE 'Seeding organizations...';
INSERT INTO organizations (name, type, description, created_at, updated_at) VALUES
  ('Chattanooga Prep', 'school', 'Our school', NOW(), NOW()),
  ('University of Tennessee', 'university', 'Public research university', NOW(), NOW()),
  ('Covenant College', 'university', 'Private liberal arts college', NOW(), NOW()),
  ('Unum Group', 'employer', 'Insurance company', NOW(), NOW()),
  ('BlueCross BlueShield of Tennessee', 'employer', 'Health insurance provider', NOW(), NOW()),
  ('Community Foundation of Greater Chattanooga', 'foundation', 'Local philanthropic organization', NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
  type = EXCLUDED.type,
  description = EXCLUDED.description,
  updated_at = NOW();

RAISE NOTICE 'Reference data seeding complete.';

-- Checkpoint validation
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'admin') THEN
    RAISE EXCEPTION 'Admin role not found after seeding roles. Aborting.';
  END IF;
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'relationship_types') THEN
    IF NOT EXISTS (SELECT 1 FROM relationship_types WHERE code = 'mentor') THEN
      RAISE EXCEPTION 'Mentor relationship type not found after seeding. Aborting.';
    END IF;
  END IF;
END $$;
RAISE NOTICE 'Initial checkpoint validations passed.';

-- 5. Seed sample people (conditionally)
DO $$
DECLARE
  -- Role IDs
  v_admin_role_id UUID;
  v_staff_role_id UUID;
  v_mentor_role_id UUID;
  v_donor_role_id UUID;
  v_student_role_id UUID;

  -- Organization IDs
  v_chatt_prep_org_id UUID;
  v_unum_org_id UUID;
  
  -- Person IDs
  v_staff_person_id UUID;
  v_mentor_person_id UUID;
  v_donor_person_id UUID;
  v_student_ids UUID[] := ARRAY[]::UUID[];
  v_current_student_id UUID;
  
  -- Relationship and Interaction IDs
  v_mentor_relationship_type_id UUID;
  v_interaction_id UUID;

  -- Loop counter
  i INTEGER;

  -- Email constants
  maria_email TEXT := 'maria.johnson@chattprep.org';
  james_email TEXT := 'james.wilson@example.com';
  elizabeth_email TEXT := 'elizabeth.chen@example.com';
  student_email_base TEXT := 'student';
  student_email_domain TEXT := '@chattprep.org';

BEGIN
  RAISE NOTICE 'Checking if sample people seeding is required...';
  IF (SELECT COUNT(*) FROM people) < 5 THEN
    RAISE NOTICE 'People table has < 5 records, proceeding with initial people seeding.';

    -- Get role IDs
    RAISE NOTICE 'Fetching role IDs...';
    SELECT id INTO v_admin_role_id FROM roles WHERE name = 'admin';
    SELECT id INTO v_staff_role_id FROM roles WHERE name = 'staff';
    SELECT id INTO v_mentor_role_id FROM roles WHERE name = 'mentor';
    SELECT id INTO v_donor_role_id FROM roles WHERE name = 'donor';
    SELECT id INTO v_student_role_id FROM roles WHERE name = 'student';

    IF v_admin_role_id IS NULL OR v_staff_role_id IS NULL OR v_mentor_role_id IS NULL OR v_donor_role_id IS NULL OR v_student_role_id IS NULL THEN
        RAISE EXCEPTION 'One or more core role IDs could not be found. Aborting people seed.';
    END IF;
    RAISE NOTICE 'Role IDs fetched.';

    -- Get organization IDs
    RAISE NOTICE 'Fetching organization IDs...';
    SELECT id INTO v_chatt_prep_org_id FROM organizations WHERE name = 'Chattanooga Prep';
    SELECT id INTO v_unum_org_id FROM organizations WHERE name = 'Unum Group';

    IF v_chatt_prep_org_id IS NULL OR v_unum_org_id IS NULL THEN
        RAISE EXCEPTION 'Chattanooga Prep or Unum organization ID not found. Aborting people seed.';
    END IF;
    RAISE NOTICE 'Organization IDs fetched.';

    -- Create Staff Member (Maria Johnson)
    RAISE NOTICE 'Seeding staff member Maria Johnson...';
    v_staff_person_id := _seed_helper_create_person_if_not_exists('Maria', 'Johnson', maria_email, '423-555-0101');
    IF v_staff_person_id IS NOT NULL THEN
      PERFORM _seed_helper_assign_role_to_person(v_staff_person_id, v_admin_role_id, true);
      PERFORM _seed_helper_assign_role_to_person(v_staff_person_id, v_staff_role_id, false);
      PERFORM _seed_helper_add_affiliation_to_person_by_org_name(v_staff_person_id, 'Chattanooga Prep', 'College Counselor', '2 years');
      PERFORM _seed_helper_add_tag_to_person_by_name(v_staff_person_id, 'Academic');
      RAISE NOTICE 'Staff member Maria Johnson seeded (ID: %).', v_staff_person_id;
    ELSE
      RAISE WARNING 'Could not create or find staff member Maria Johnson (email: %)', maria_email;
    END IF;

    -- Create Mentor (James Wilson)
    RAISE NOTICE 'Seeding mentor James Wilson...';
    v_mentor_person_id := _seed_helper_create_person_if_not_exists('James', 'Wilson', james_email, '423-555-0202');
    IF v_mentor_person_id IS NOT NULL THEN
      PERFORM _seed_helper_assign_role_to_person(v_mentor_person_id, v_mentor_role_id, true);
      PERFORM _seed_helper_add_affiliation_to_person_by_org_name(v_mentor_person_id, 'Unum Group', 'Software Engineer', '5 years');
      PERFORM _seed_helper_add_tag_to_person_by_name(v_mentor_person_id, 'STEM');
      RAISE NOTICE 'Mentor James Wilson seeded (ID: %).', v_mentor_person_id;
    ELSE
      RAISE WARNING 'Could not create or find mentor James Wilson (email: %)', james_email;
    END IF;

    -- Create Donor (Elizabeth Chen)
    RAISE NOTICE 'Seeding donor Elizabeth Chen...';
    v_donor_person_id := _seed_helper_create_person_if_not_exists('Elizabeth', 'Chen', elizabeth_email, '423-555-0303');
    IF v_donor_person_id IS NOT NULL THEN
      PERFORM _seed_helper_assign_role_to_person(v_donor_person_id, v_donor_role_id, true);
      PERFORM _seed_helper_add_tag_to_person_by_name(v_donor_person_id, 'Fundraising');
      RAISE NOTICE 'Donor Elizabeth Chen seeded (ID: %).', v_donor_person_id;
    ELSE
      RAISE WARNING 'Could not create or find donor Elizabeth Chen (email: %)', elizabeth_email;
    END IF;

    -- Seed Students (8 sample records)
    RAISE NOTICE 'Seeding 8 sample students...';
    FOR i IN 1..8 LOOP
      DECLARE
        student_email TEXT := student_email_base || i || student_email_domain;
      BEGIN
        v_current_student_id := _seed_helper_create_person_if_not_exists('Student' || i, 'LastName' || i, student_email);
        
        IF v_current_student_id IS NOT NULL THEN
          v_student_ids := array_append(v_student_ids, v_current_student_id);
          PERFORM _seed_helper_assign_role_to_person(v_current_student_id, v_student_role_id, true);
          PERFORM _seed_helper_add_affiliation_to_person_by_org_name(v_current_student_id, 'Chattanooga Prep', 'Student', (i || ' months')::INTERVAL);
          
          IF i % 3 = 0 THEN
            PERFORM _seed_helper_add_tag_to_person_by_name(v_current_student_id, 'STEM');
          ELSIF i % 3 = 1 THEN
            PERFORM _seed_helper_add_tag_to_person_by_name(v_current_student_id, 'Arts');
          ELSE
            PERFORM _seed_helper_add_tag_to_person_by_name(v_current_student_id, 'Sports');
          END IF;
          
          IF i % 4 = 0 THEN
            PERFORM _seed_helper_add_tag_to_person_by_name(v_current_student_id, 'College-bound');
          ELSIF i % 5 = 0 THEN
            PERFORM _seed_helper_add_tag_to_person_by_name(v_current_student_id, 'First-generation');
          END IF;
          RAISE NOTICE 'Student % seeded (ID: %)', i, v_current_student_id;
        ELSE
          RAISE WARNING 'Could not create or find student with email %', student_email;
        END IF;
      END;
    END LOOP;
    RAISE NOTICE 'Sample students seeding complete.';

    -- Create mentor relationships for a few students
    RAISE NOTICE 'Creating mentor relationships...';
    IF v_mentor_person_id IS NOT NULL AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'relationship_types') THEN
      SELECT id INTO v_mentor_relationship_type_id FROM relationship_types WHERE code = 'mentor';
      IF v_mentor_relationship_type_id IS NOT NULL THEN
        FOR i IN 1..LEAST(3, array_length(v_student_ids, 1)) LOOP
          IF v_student_ids[i] IS NOT NULL THEN
            INSERT INTO relationships (from_person_id, to_person_id, relationship_type_id, start_date, status, created_at, updated_at, created_by)
            VALUES (v_mentor_person_id, v_student_ids[i], v_mentor_relationship_type_id, CURRENT_DATE - INTERVAL '3 months', 'active', NOW(), NOW(), v_staff_person_id)
            ON CONFLICT (from_person_id, to_person_id, relationship_type_id) DO NOTHING;
            RAISE NOTICE 'Mentor relationship created for student ID %.', v_student_ids[i];
          END IF;
        END LOOP;
      ELSE
        RAISE WARNING 'Mentor relationship type ID not found, skipping mentor relationship seeding.';
      END IF;
    ELSE
      RAISE WARNING 'Mentor person ID is null or relationship_types table does not exist, skipping mentor relationship seeding.';
    END IF;
    RAISE NOTICE 'Mentor relationships seeding complete.';
    
    -- Add sample interactions
    RAISE NOTICE 'Adding sample interactions...';
    IF v_staff_person_id IS NOT NULL AND v_mentor_person_id IS NOT NULL AND array_length(v_student_ids, 1) > 0 AND v_student_ids[1] IS NOT NULL THEN
      INSERT INTO interactions (interaction_type, title, description, occurred_at, duration_minutes, location, created_at, updated_at, created_by)
      VALUES ('meeting', 'Initial mentorship meeting', 'First meeting between James and Student1', NOW() - INTERVAL '30 days', 60, 'School Library', NOW(), NOW(), v_staff_person_id)
      RETURNING id INTO v_interaction_id;

      IF v_interaction_id IS NOT NULL THEN
        INSERT INTO interaction_participants (interaction_id, person_id, role, created_at) VALUES (v_interaction_id, v_mentor_person_id, 'mentor', NOW()) ON CONFLICT (interaction_id, person_id) DO NOTHING;
        INSERT INTO interaction_participants (interaction_id, person_id, role, created_at) VALUES (v_interaction_id, v_student_ids[1], 'mentee', NOW()) ON CONFLICT (interaction_id, person_id) DO NOTHING;
        INSERT INTO interaction_tags (interaction_id, tag_id, created_at, created_by) SELECT v_interaction_id, id, NOW(), v_staff_person_id FROM tags WHERE name = 'Mentorship' ON CONFLICT (interaction_id, tag_id) DO NOTHING;
        RAISE NOTICE 'Interaction 1 (ID: %) and participants/tags seeded.', v_interaction_id;
      END IF;

      v_interaction_id := NULL; -- Reset for next interaction
      INSERT INTO interactions (interaction_type, title, description, occurred_at, duration_minutes, location, created_at, updated_at, created_by)
      VALUES ('meeting', 'Follow-up mentorship session', 'Progress check and goal setting', NOW() - INTERVAL '15 days', 45, 'Career Center', NOW(), NOW(), v_mentor_person_id)
      RETURNING id INTO v_interaction_id;
      
      IF v_interaction_id IS NOT NULL THEN
        INSERT INTO interaction_participants (interaction_id, person_id, role, created_at) VALUES (v_interaction_id, v_mentor_person_id, 'mentor', NOW()) ON CONFLICT (interaction_id, person_id) DO NOTHING;
        INSERT INTO interaction_participants (interaction_id, person_id, role, created_at) VALUES (v_interaction_id, v_student_ids[1], 'mentee', NOW()) ON CONFLICT (interaction_id, person_id) DO NOTHING;
        INSERT INTO interaction_tags (interaction_id, tag_id, created_at, created_by) SELECT v_interaction_id, id, NOW(), v_mentor_person_id FROM tags WHERE name = 'Mentorship' ON CONFLICT (interaction_id, tag_id) DO NOTHING;
        INSERT INTO interaction_tags (interaction_id, tag_id, created_at, created_by) SELECT v_interaction_id, id, NOW(), v_mentor_person_id FROM tags WHERE name = 'Academic' ON CONFLICT (interaction_id, tag_id) DO NOTHING;
        RAISE NOTICE 'Interaction 2 (ID: %) and participants/tags seeded.', v_interaction_id;
      END IF;
    ELSE
      RAISE WARNING 'One or more required IDs (staff, mentor, student) are null, skipping sample interaction seeding.';
    END IF;
    RAISE NOTICE 'Sample interactions seeding complete.';
  ELSE
    RAISE NOTICE 'People table has >= 5 records, skipping initial people seeding.';
  END IF; -- End of IF (SELECT COUNT(*) FROM people) < 5 THEN

EXCEPTION
  WHEN others THEN
    RAISE WARNING 'An error occurred during people and interactions seeding: %', SQLERRM;
    RAISE; -- Re-raise the exception to ensure transaction rollback
END;
$$;

RAISE NOTICE 'Main seeding logic complete.';

-- Clean up temporary functions
RAISE NOTICE 'Cleaning up temporary helper functions...';
DROP FUNCTION IF EXISTS _seed_helper_create_person_if_not_exists(TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS _seed_helper_assign_role_to_person(UUID, UUID, BOOLEAN);
DROP FUNCTION IF EXISTS _seed_helper_assign_role_to_person_by_name(UUID, TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS _seed_helper_add_affiliation_to_person_by_org_name(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS _seed_helper_add_tag_to_person_by_name(UUID, TEXT);
RAISE NOTICE 'Temporary helper functions cleaned up.';

RAISE NOTICE 'Seed script execution finished successfully.';

COMMIT;
