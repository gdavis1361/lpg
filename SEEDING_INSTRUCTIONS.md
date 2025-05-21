# Database Seeding Instructions

The seed script is now set up and all TypeScript errors have been fixed. To use it:

## 1. Set up Supabase credentials

Create a `.env` file in the `lpg-backend` directory with your Supabase credentials:

```
# Supabase credentials
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

You can find these credentials in your Supabase project settings.

## 2. Run the seed script

After setting up the credentials, you can run any of these commands:

```bash
# Full seed with default dataset (50 people, etc.)
./scripts/seed-database.sh seed

# Smaller seed with development dataset (20 people, etc.)
./scripts/seed-database.sh seed:dev

# Only seed special test cases
./scripts/seed-database.sh seed:special
```

## 3. Check database status

To verify what data has been seeded:

```bash
./scripts/seed-database.sh status
```

## 4. Reset data if needed

To clear all data:

```bash
./scripts/seed-database.sh reset
```

Or to clear specific tables:

```bash
./scripts/seed-database.sh reset:tables
```

The script will handle everything else automatically, including installing necessary dependencies. 