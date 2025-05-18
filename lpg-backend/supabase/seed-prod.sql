-- Version: 2.0 (Refactored May 2025)
-- seed-prod.sql for Chattanooga Prep Relationship Platform
-- PRODUCTION VERSION - Contains ONLY reference data, NO sample data
-- Provides essential lookup data for production environment
-- Requires tables created by migrations: roles, relationship_types, tags, organizations

BEGIN;

RAISE NOTICE 'Starting production seed script execution...';

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

-- Checkpoint validation - essential for production
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
RAISE NOTICE 'Final checkpoint validations passed.';

RAISE NOTICE 'Production seed script execution finished successfully.';

COMMIT;
