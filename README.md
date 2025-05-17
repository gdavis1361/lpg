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

1.  **Frontend (`lpg-ui`):**
    *   Copy `.env.example` to `.env.local` in the `lpg-ui` directory: `cp lpg-ui/.env.example lpg-ui/.env.local`
    *   Fill in the required environment variables in `lpg-ui/.env.local` (Supabase URL, Anon Key, etc.).

2.  **Backend (`lpg-backend`):**
    *   Copy `.env.example` to `.env` or `.env.local` (as per your Supabase CLI setup) in the `lpg-backend` directory: `cp lpg-backend/.env.example lpg-backend/.env`
    *   Fill in the required environment variables, especially for Supabase CLI and database connections.

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

## Contributing

(Details to be added: coding standards, branch strategy, PR process.)