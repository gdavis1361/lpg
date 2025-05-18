# Supabase Workflow

This document outlines the standard workflow for Supabase development in the LPG project, focusing on branch environments, migration validation, and deployment processes.

## Branch Environment Workflow

### Overview

LPG uses Supabase Branch Environments for isolated development and testing of database changes. This workflow ensures that:

1. Each feature branch gets its own isolated Supabase environment
2. Migrations are automatically applied and validated
3. Changes can be tested in isolation before being merged to production
4. The entire process is automated via GitHub Actions

### Automated Workflow (GitHub Actions)

The `supabase-branch.yml` workflow automatically:

1. Creates a Supabase branch environment when a PR is opened or updated
2. Applies migrations to the branch environment
3. Runs validation checks on the branch environment
4. Comments on the PR with branch details and connection instructions

#### When It Runs

The workflow triggers on:
- PR creation (`opened`)
- PR updates (`synchronize`)
- PR reopening (`reopened`)

And only for changes to:
- `lpg-backend/supabase/**`
- The workflow file itself

### Manual Branch Environment Creation

To manually create a branch environment:

1. Ensure you have the Supabase CLI installed:
   ```bash
   npm install -g supabase
   ```

2. Link to your Supabase project:
   ```bash
   cd lpg-backend
   supabase link --project-ref=<project-id>
   ```

3. Create a new branch:
   ```bash
   supabase branches create <branch-name>
   ```

4. Apply migrations to the branch:
   ```bash
   supabase db push --branch=<branch-id>
   ```

## Migration Validation

### Validation Framework

LPG implements a comprehensive validation framework for database migrations:

1. **Safeguard Blocks**: SQL `DO` blocks that check for unsafe conditions
2. **Helper Functions**: Reusable SQL functions for common validation checks
3. **Validation Script**: A Node.js script that runs validation checks against any environment

### Built-in Checks

The validation framework includes these checks:

1. **Unmapped Relationship Types**: Ensures all `relationship_type` values can be mapped to the `relationship_types` table
2. **Duplicate Active Relationships**: Checks for duplicate active relationships that would violate unique constraints

### Running Validation Checks

To run validation checks:

1. Against a branch environment:
   ```bash
   cd lpg-backend
   doppler run --project lpg --config dev -- node scripts/validate-migrations.js --branch=<branch-id>
   ```

2. Specific checks only:
   ```bash
   doppler run --project lpg --config dev -- node scripts/validate-migrations.js --check=unmapped-relationships
   ```

## Migration Development Process

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Create Migration File

Create your migration file in `lpg-backend/supabase/migrations/`:

```bash
cd lpg-backend
touch supabase/migrations/$(date +%Y%m%d)_your_migration_name.sql
```

### 3. Add Safeguards

For critical migrations, include safeguard blocks:

```sql
-- Safeguard: Description of what this safeguard checks
DO $$
DECLARE
  -- Variables
BEGIN
  -- Check logic
  
  -- Notify result
  RAISE NOTICE 'Safeguard check passed';
  
  -- Stop migration if unsafe
  IF unsafe_condition THEN
    RAISE EXCEPTION 'Aborting migration: detailed reason';
  END IF;
END;
$$;
```

### 4. Test Locally

Test your migration locally:

```bash
cd lpg-backend
supabase start
supabase db push
```

### 5. Create PR and Review

1. Push your branch and create a PR
2. The GitHub Action will automatically create a branch environment
3. Review the validation check results
4. Test your changes in the branch environment

### 6. Merge to Production

After approval, merge your PR to the main branch to deploy to production.

## Best Practices

1. **Always Include Rollback Logic**: Create `.down.sql` migrations or document rollback procedures
2. **Test Large Migrations in Stages**: Break complex migrations into smaller, safer steps
3. **Validate Early and Often**: Run validation checks locally before pushing
4. **Document Critical Migrations**: Add detailed comments and documentation for complex changes
5. **Follow Naming Conventions**: Use the date prefix format for migration files

## Troubleshooting

### Common Issues

1. **"Function does not exist" errors**: Ensure validation helper functions are installed
2. **Connection failures**: Check that your Supabase access token is valid
3. **Missing environment variables**: Run with `doppler run` to inject environment variables

### Getting Help

If you encounter issues with the Supabase workflow:

1. Check the GitHub Actions workflow logs
2. Review the validation script output
3. Test your migrations manually using the Supabase CLI
