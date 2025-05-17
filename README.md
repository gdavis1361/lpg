# LPG - Chattanooga Prep Relationship Platform

This monorepo contains the frontend (`lpg-ui`) and backend (`lpg-backend`) for the Chattanooga Prep Relationship Platform.

## Project Structure

- `lpg-ui/`: Next.js frontend application.
- `lpg-backend/`: Supabase backend project (migrations, etc.).
- `docs/`: Project documentation and design files.

## Getting Started

### Prerequisites

- Node.js (version specified in `.nvmrc` if available, or latest LTS)
- npm (comes with Node.js)
- Supabase CLI (for backend development and type generation): `npm install supabase --save-dev` (globally or per project as needed)

### Installation

1.  Clone the repository.
2.  Navigate to the root directory (`lpg`).
3.  Install all dependencies for both `lpg-ui` and `lpg-backend` workspaces:
    ```bash
    npm run install:all
    # or
    # npm install
    ```

### Environment Setup

#### Option A: Using Doppler (Recommended)

We use Doppler for secure environment variable management across environments:

1. **Initial Setup:**
   ```bash
   # Login to Doppler
   npm run doppler:login
   
   # Configure your local setup
   npm run doppler:configure
   ```

2. **Running with Doppler:**
   All npm scripts are configured to use Doppler automatically. Simply use them as usual:
   ```bash
   npm run dev        # Uses dev environment variables
   npm run build:ui   # Uses production environment variables
   ```

3. **Required Variables in Doppler:**
   * **Frontend (`frontend` secrets group):**
     - `NEXT_PUBLIC_SUPABASE_URL`
     - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   
   * **Backend (`backend` secrets group):**
     - `SUPABASE_URL`
     - `SUPABASE_SERVICE_ROLE_KEY`
     - `SUPABASE_JWT_SECRET`
     - `POSTGRES_URL` and other DB connection variables
     - `LOG_LEVEL` and `LOG_FORMAT` for logging configuration

#### Option B: Manual Environment Files

If you prefer not to use Doppler, you can still use traditional environment files:

1. **Frontend (`lpg-ui`):**
   * Copy `.env.example` to `.env.local` in the `lpg-ui` directory: `cp lpg-ui/.env.example lpg-ui/.env.local`
   * Fill in the required environment variables in `lpg-ui/.env.local` (Supabase URL, Anon Key, etc.).

2. **Backend (`lpg-backend`):**
   * Copy `.env.example` to `.env` in the `lpg-backend` directory: `cp lpg-backend/.env.example lpg-backend/.env`
   * Fill in the required environment variables, especially for Supabase CLI and database connections.

### Running the Development Environment

From the root directory (`lpg`):

```bash
# Start both frontend UI and backend (Supabase local development server)
npm run dev
```

This will concurrently:
- Start the Next.js development server for `lpg-ui` (usually on `http://localhost:3000`).
- Start the Supabase local development environment for `lpg-backend`.

Alternatively, you can run them separately:

- **Frontend UI:**
  ```bash
  npm run dev:ui
  ```
- **Backend (Supabase local):**
  ```bash
  npm run dev:backend
  ```
  (This primarily runs `supabase start`. Ensure your Supabase project is linked or initialized in `lpg-backend`.)

## Key Scripts (run from the root `lpg` directory)

- `npm run install:all`: Installs dependencies for all workspaces.
- `npm run dev`: Starts both frontend and backend development servers.
- `npm run dev:ui`: Starts only the frontend UI development server.
- `npm run dev:backend`: Starts the Supabase local development server.
- `npm run build:ui`: Builds the frontend UI application.
- `npm run lint`: Lints both frontend and backend (backend linting to be configured).
- `npm run lint:ui`: Lints the frontend UI application.
- `npm run types:supabase`: Generates TypeScript types from your Supabase schema into `lpg-ui/src/types/supabase.ts`. Requires Supabase CLI and a running Supabase instance (local or remote) accessible.
- `npm run migrate:db`: Applies database migrations located in `lpg-backend/supabase/migrations` using the Supabase CLI.
- `npm test --workspace=lpg-ui`: Runs frontend tests for `lpg-ui`.

## Type Generation (Supabase)

To ensure your frontend has up-to-date types from your Supabase schema:

1.  Make sure your Supabase local instance is running (`npm run dev:backend` or `supabase start` in `lpg-backend`).
2.  From the root directory (`lpg`), run:
    ```bash
    npm run types:supabase
    ```
    This will output the generated types to `lpg-ui/src/types/supabase.ts`.
    The `project-id` in the `lpg-ui/package.json` script for `types:supabase` is currently hardcoded to `tfvnratitcbmqqrsjamp`. Update this if your Supabase project ID is different.

## Database Migrations

Database schema changes are managed via migration files in `lpg-backend/supabase/migrations/`.

- To apply migrations to your local Supabase instance:
  ```bash
  npm run migrate:db
  ```
  (This runs `supabase db push` within the `lpg-backend` workspace.)

## Testing

- **Frontend (`lpg-ui`):**
  Uses Vitest for unit and component testing.
  ```bash
  npm test --workspace=lpg-ui
  # or from lpg-ui directory
  # npm run test
  ```

## Deployment and CI/CD

### Doppler Integration with CI/CD

The project uses Doppler for secure environment variable management in CI/CD pipelines:

1. **GitHub Actions:**
   * A GitHub Actions workflow is configured in `.github/workflows/doppler-ci.yml`
   * It uses the Doppler CLI action to securely inject environment variables during the build
   * You'll need to add a `DOPPLER_TOKEN` secret to your GitHub repository settings

2. **Vercel Deployment:**
   * The frontend is configured for deployment on Vercel
   * To use Doppler with Vercel:
     1. Install the Doppler Vercel integration: https://vercel.com/integrations/doppler
     2. Connect your Vercel project to Doppler
     3. Configure Doppler to sync environment variables to Vercel automatically

3. **Security Considerations:**
   * The CI/CD pipeline includes a check to verify no secrets are committed to the codebase
   * TypeScript strict mode is enforced during the build process
   * Logs are configured to mask sensitive information in accordance with our logging standards

### Database Migrations in CI/CD

For CI/CD database migrations:

1. Development branches use test databases to validate migrations
2. Production deployments should run migrations before deploying the application
3. Migrations are applied using Doppler for environment variable injection:
   ```bash
   doppler run --project lpg --config prod --secrets-group backend -- npm run migrate:db
   ```

## Contributing

(Details to be added: coding standards, branch strategy, PR process.)