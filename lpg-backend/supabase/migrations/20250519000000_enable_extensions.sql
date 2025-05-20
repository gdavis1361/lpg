-- Prerequisites: None
-- Purpose: Enables extensions required by subsequent migrations.

-- UUID generation for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
COMMENT ON EXTENSION "uuid-ossp" IS 'UUID generation functions for primary keys';

-- Cron functionality for scheduled jobs
CREATE EXTENSION IF NOT EXISTS "pg_cron";
COMMENT ON EXTENSION "pg_cron" IS 'Job scheduling for various automated tasks';

-- Full text search capability / text similarity
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
COMMENT ON EXTENSION "pg_trgm" IS 'Text similarity and indexing for search capabilities';
