-- Reset migration tracking tables
DROP TABLE IF EXISTS supabase_migrations.schema_migrations;
DROP TABLE IF EXISTS supabase_migrations.seed_files;
DROP SCHEMA IF EXISTS supabase_migrations CASCADE;

-- Drop existing tables (except auth tables)
DROP TABLE IF EXISTS interactions CASCADE;
DROP TABLE IF EXISTS relationships CASCADE;
DROP TABLE IF EXISTS relationship_types CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS person_roles CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;

-- Create fresh migration tracking
CREATE SCHEMA IF NOT EXISTS supabase_migrations;
CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
  version text primary key,
  statements text[],
  name text
);
