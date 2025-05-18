# Database Seeding Strategy

## Overview

This document outlines the database seeding approach for the Chattanooga Prep Relationship Platform. We use separate seed files for different environments to ensure appropriate data is available while maintaining security and consistency.

## Seed Files

| File | Purpose | Usage |
|------|---------|-------|
| `seed.sql` | Environment-aware entry point | Detects environment and runs appropriate seed file |
| `seed-dev.sql` | Development environment | Contains reference data + sample data for development |
| `seed-prod.sql` | Production environment | Contains only essential reference data, no sample data |
| `seed-test.sql` | Testing | Contains minimal test data for workflow validation |

## Reference Data

All environments receive the following reference data:
- Roles (admin, staff, mentor, donor, alumni, student)
- Relationship types (mentor, donor, alumni, staff, family, peer)
- Tags for categorization (interests, status markers, etc.)
- Core organizations (schools, universities, employers)

## Sample Data (Development Only)

The development seed additionally provides:
- Sample staff member (Maria Johnson)
- Sample mentor (James Wilson)
- Sample donor (Elizabeth Chen)
- Eight sample students with various tags and interests
- Mentor relationships between sample users
- Sample interaction records

## How to Use

### Local Development

```bash
# Option 1: Use environment detection (requires app.environment setting)
supabase db execute --project-ref <project_id> --file ./lpg-backend/supabase/seed.sql

# Option 2: Use environment-specific seed directly
supabase db execute --project-ref <project_id> --file ./lpg-backend/supabase/seed-dev.sql
```

### CI/CD Pipeline

Our GitHub Actions workflows use Doppler for environment variables:

```yaml
# For development environments
- name: Seed Development Database
  run: |
    doppler run --project lpg --config dev -- supabase db execute \
      --project-ref ${{ secrets.SUPABASE_PROJECT_REF }} \
      --file ./lpg-backend/supabase/seed-dev.sql

# For production environments
- name: Seed Production Database
  run: |
    doppler run --project lpg --config dev -- supabase db execute \
      --project-ref ${{ secrets.SUPABASE_PRODUCTION_PROJECT_REF }} \
      --file ./lpg-backend/supabase/seed-prod.sql
```

## Implementation Notes

1. **Idempotent Operations**: All seed operations use `ON CONFLICT` clauses to ensure they can be safely run multiple times.

2. **Transaction Safety**: Seeds are wrapped in transactions to ensure all-or-nothing execution.

3. **Helper Functions**: The development seed uses temporary PL/pgSQL functions to facilitate data creation while maintaining DRY principles.

4. **Error Handling**: All operations include appropriate error handling to fail gracefully.

## Technical Decisions

- **Split Files vs. Environment Variables**: We chose split files over environmental branching for clarity and simplicity, following our simplicity_first principle.
  
- **Temporary Functions**: Helper functions are created at runtime and dropped at completion, keeping the database schema clean.

- **Error Handling**: Comprehensive error handling ensures failed seeds don't leave the database in an inconsistent state.

## Maintenance

When updating seed data:

1. Always update reference data in both `seed-dev.sql` and `seed-prod.sql`
2. Only add sample/test data to `seed-dev.sql`
3. Run tests after updating seed data to ensure consistency
