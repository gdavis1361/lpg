# Doppler Setup Guide

This guide walks through the complete setup of Doppler for the LPG project, ensuring secure environment variable management across all environments.

## Initial Doppler Setup

### 1. Create a Doppler Account

1. Sign up at [https://doppler.com](https://doppler.com)
2. Create a new organization or use an existing one

### 2. Create the Project Structure

1. Create a new project called `lpg`
2. Configure the following environments:
   - `dev` - Development environment
   - `test` - Testing environment
   - `prod` - Production environment

### 3. Set Up Secret Groups

For each environment, create two secret groups:
- `frontend` - For Next.js frontend variables
- `backend` - For Supabase and database variables

## Required Environment Variables

### Frontend Secret Group

```
NEXT_PUBLIC_SUPABASE_URL=https://example-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJh...example...kZCI6MTY5NDQ5
```

### Backend Secret Group

```
SUPABASE_URL=https://example-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...example-service-role-key...J9
SUPABASE_JWT_SECRET=example-jwt-secret-at-least-32-chars-long
POSTGRES_URL=postgresql://postgres:password@localhost:5432/postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=example-db-password
LOG_LEVEL=info
LOG_FORMAT=console
```

## CI/CD Integration

### GitHub Actions

1. In your GitHub repository, go to Settings > Secrets > Actions
2. Add a new repository secret:
   - Name: `DOPPLER_TOKEN`
   - Value: Create a new service token in Doppler with read access

### Vercel Integration

1. In Vercel, go to your project settings
2. Install the Doppler integration: https://vercel.com/integrations/doppler
3. Connect your Vercel project to your Doppler project
4. Configure automatic syncing from Doppler to Vercel

## Local Development Setup

After installing the Doppler CLI:

```bash
# Login to your Doppler account
doppler login

# At the root of your project
doppler setup --project lpg --config dev

# Configure frontend and backend components
cd lpg-ui && doppler setup
cd ../lpg-backend && doppler setup
```

You can also use the npm scripts added to package.json:

```bash
npm run doppler:login
npm run doppler:configure
```

## Running with Doppler

All npm scripts are configured to use Doppler automatically:

```bash
# Run development environment
npm run dev

# Build for production
npm run build:ui
```

## Troubleshooting

1. **Authentication Issues**: Run `doppler login` to refresh your authentication
2. **Configuration Problems**: Verify your setup with `doppler configure`
3. **Missing Variables**: Check that all required variables are set in the appropriate secret groups
4. **Doppler CLI Issues**: Update the CLI with `brew upgrade doppler` on macOS
