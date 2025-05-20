# Database Migration Strategy

This document outlines the comprehensive migration strategy for the LPG project's Supabase database, including planning, execution, validation, and rollback procedures.

## Table of Contents

1. [Overview](#overview)
2. [Migration Types](#migration-types)
3. [Migration Workflow](#migration-workflow)
4. [Validation Approach](#validation-approach)
5. [Rollback Procedures](#rollback-procedures)
6. [Emergency Handling](#emergency-handling)
7. [Best Practices](#best-practices)

## Overview

Database migrations are a critical part of our development workflow. Following our project's workflow_first_development principle, we've established a structured approach that ensures migrations are:

- **Safe**: Validated through automated checks and branch environments
- **Reversible**: Include rollback options whenever possible
- **Traceable**: Documented and tracked in version control
- **Consistent**: Follow established patterns and naming conventions

## Migration Types

We classify migrations into different types based on their risk and impact:

### 1. Schema Migrations

Changes to the database structure:
- **Table Creation/Modification**: Adding or altering tables and columns
- **Index Management**: Adding, removing, or modifying indexes
- **Constraint Changes**: Adding or modifying constraints

**Risk Level**: Medium
**Validation Required**: Structure validation, constraint validation

### 2. Data Migrations

Changes to existing data:
- **Data Transformations**: Modifying existing records
- **Data Backfilling**: Populating new fields on existing records
- **Data Cleanup**: Removing or archiving old data

**Risk Level**: High
**Validation Required**: Data integrity checks, sample verification

### 3. Security Migrations

Changes to security settings:
- **Row-Level Security (RLS) Policies**: Adding or modifying access control
- **Role and Permission Changes**: Modifying authentication or authorization

**Risk Level**: Medium to High
**Validation Required**: Access control testing, authorization testing

### 4. Function and Procedure Migrations

Changes to database functions and procedures:
- **Creating/Modifying Functions**: Adding or changing database logic
- **Trigger Management**: Adding or modifying database triggers

**Risk Level**: Medium
**Validation Required**: Functionality testing, performance testing

## Migration Workflow

Our migration workflow follows these steps:

### 1. Planning Phase

1. **Identify Changes**: Determine what database changes are needed
2. **Document Requirements**: Create a list of specific changes
3. **Risk Assessment**: Evaluate potential impacts and rollback strategies
4. **Create Migration File**: Follow the naming convention: `YYYYMMDD_descriptive_name.sql`

### 2. Development Phase

1. **Local Testing**: Test migrations on a local Supabase instance
2. **Create Safeguards**: Add validation SQL to prevent unsafe migrations
3. **Add Rollback**: Create corresponding `.down.sql` script for reversing changes
4. **Code Review**: Get peer review of the migration changes

### 3. Testing Phase

1. **Branch Environment**: Push to a branch to trigger automatic branch environment creation
2. **Automated Validation**: Run the validation script against the branch environment
3. **Manual Testing**: Test functionality on the branch environment
4. **Integration Testing**: Test frontend integration with new schema

### 4. Deployment Phase

1. **PR Approval**: Get final approval for the migration
2. **Merge to Main**: Deploy to production via merge
3. **Post-Deploy Validation**: Verify migration success in production
4. **Documentation**: Update any relevant documentation about schema changes

## Validation Approach

We use a multi-layered validation approach:

### 1. Pre-Migration Validations

Implemented as SQL `DO` blocks in the migration file:

```sql
DO $$
DECLARE
  -- Variables
BEGIN
  -- Check logic
  IF unsafe_condition THEN
    RAISE EXCEPTION 'Aborting migration: reason';
  END IF;
END;
$$;
```

### 2. Automated Validation Scripts

The `validate-migrations.js` script performs validations against any environment:

```bash
doppler run --project lpg --config dev -- node scripts/validate-migrations.js --branch=<branch-id>
```

### 3. Post-Migration Validations

Verifications after migration has been applied:

```sql
-- Verify table structure
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'my_table';

-- Verify data integrity
SELECT COUNT(*) FROM my_table WHERE invalid_condition;
```

## Rollback Procedures

Every migration should have a corresponding rollback plan:

### 1. Automated Rollbacks

For schema migrations, create a `.down.sql` file with the reverse operations:

```sql
-- Example: 20250518_add_relationship_types.sql
CREATE TABLE relationship_types (...);

-- Example: 20250518_add_relationship_types.down.sql
DROP TABLE IF EXISTS relationship_types;
```

### 2. Manual Rollbacks

For complex data migrations, document the rollback procedure:

1. Take a snapshot of affected data
2. Implement the rollback SQL logic
3. Verify data integrity post-rollback

### 3. Branch Reset

For branch environments, use the Supabase branch reset functionality:

```bash
supabase db reset --branch=<branch-id>
```

## Emergency Handling

In case of critical issues in production:

### 1. Immediate Response

1. **Assess Impact**: Determine what's affected and severity
2. **Communication**: Notify team immediately via defined channels
3. **Access Control**: Consider temporarily restricting access if data integrity is at risk

### 2. Rollback Decision

1. **Evaluate Rollback**: Determine if rollback is the appropriate response
2. **Execute Rollback**: Use prepared rollback scripts if available
3. **Data Recovery**: Restore from point-in-time backup if necessary

### 3. Post-Mortem

1. **Root Cause Analysis**: Identify what caused the issue
2. **Validation Improvement**: Update validation scripts to catch similar issues
3. **Documentation**: Document the incident and resolution

## Best Practices

### Naming Conventions

- **Migration Files**: `YYYYMMDD_descriptive_name.sql`
- **Rollback Files**: `YYYYMMDD_descriptive_name.down.sql`
- **Tables**: Snake case, plural (e.g., `user_profiles`)
- **Columns**: Snake case, singular (e.g., `first_name`)

### SQL Style Guidelines

- Use uppercase for SQL keywords (SELECT, INSERT, etc.)
- Use lowercase for identifiers (table names, column names)
- Include comments for complex operations
- Break long queries into multiple lines for readability

### Safeguard Implementation

Always implement safeguards for:
- Data loss prevention
- Unique constraint violations
- Foreign key constraint violations
- Performance impacts on large tables

### Testing Requirements

- Test all migrations on a branch environment before merging
- Include at least one test case for each affected table
- Verify both successful path and error conditions

---

This migration strategy follows our project's workflow_first_development and simplicity_first principles while ensuring database changes are safe, reliable, and maintainable.
