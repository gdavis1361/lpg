# Database Seed Script

This directory contains scripts to seed the Supabase database with realistic mock data for development and testing.

## Overview

The seed script generates data for all major entities in the system following the correct dependency order:

1. Organizations & Activity Groups
2. Tags
3. People (with affiliations and activities)
4. Relationships
5. Milestones
6. Interactions
7. Special test cases

## Prerequisites

- Node.js (v16+)
- npm or yarn
- Supabase project with schema already created
- Supabase credentials in environment variables

## Setup

1. Install the dependencies:
   ```bash
   npm install
   ```

2. Create a `.env` file in the project root with your Supabase credentials:
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://yourproject.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```

3. Generate TypeScript types for your Supabase schema:
   ```bash
   npm run supabase:generate-types
   ```

## Usage

### Generate full development dataset:

```bash
npm run seed
```

### Generate smaller development dataset:

```bash
npm run seed:dev
```

### Generate only special test cases:

```bash
npm run seed:special
```

## Configuration

You can customize the seed data generation by modifying the configuration in `config.ts`:

- Adjust entity counts
- Change time ranges
- Modify probabilities for different scenarios
- Enable/disable special test cases

## Special Test Cases

The seed script creates special entities with known IDs that can be used for testing:

1. **Test University** (ID: `a0000000-0000-0000-0000-000000000001`)
2. **Test Mentor** (ID: `b0000000-0000-0000-0000-000000000001`) 
3. **Test Student** (ID: `b0000000-0000-0000-0000-000000000002`)
4. **Test Relationship** (ID: `c0000000-0000-0000-0000-000000000001`)

These can be used to build UI components with predictable test data.

## Adding New Entity Generators

To add a generator for a new entity type:

1. Create a new file in the `generators` directory
2. Define the generation function with appropriate parameters 
3. Import and use it in the main `index.ts` script
4. Update the `config.ts` with any new configuration parameters

## Troubleshooting

- **Database connection errors**: Check your Supabase credentials in the `.env` file
- **Type errors**: Run `npm run supabase:generate-types` to update the TypeScript definitions
- **"Relation does not exist" errors**: Ensure your database schema is properly migrated before running the seed script

## Production Safety

The seed script has a safety check to prevent accidentally seeding production environments. To override this for initial production data setup, use the `--force` flag:

```bash
NODE_ENV=production npm run seed -- --force
```

## Contributing

When adding new generators or modifying existing ones:

1. Follow the established patterns for error handling and batch processing
2. Maintain proper entity relationships
3. Use realistic data that reflects real-world scenarios 