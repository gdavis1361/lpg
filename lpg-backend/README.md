# LPG Backend (Supabase)

This directory contains the Supabase backend configuration, migrations, and eventually, serverless functions for the Chattanooga Prep Relationship Platform.

## Project Structure

- `supabase/`: Contains Supabase project configuration, migrations, and function stubs.
  - `migrations/`: SQL migration files managed by Supabase CLI.
  - `functions/`: (Directory to be created when functions are added) Serverless functions.
- `.env.example`: Example environment variables required for the backend.
- `package.json`: Manages backend-specific dependencies (primarily Supabase CLI for now) and scripts.

## Getting Started

Refer to the root `README.md` in the `lpg/` directory for overall project setup and installation instructions.

### Environment Setup

1.  Copy `lpg-backend/.env.example` to `lpg-backend/.env` (or `.env.local` depending on your Supabase CLI workflow).
2.  Fill in the necessary Supabase project details (URL, keys, database connection string).

## Development

- **Starting Supabase Local Environment:**
  From the `lpg-backend` directory:
  ```bash
  supabase start
  ```
  Or from the root `lpg/` directory:
  ```bash
  npm run dev:backend
  ```

- **Applying Database Migrations:**
  Migrations are located in `lpg-backend/supabase/migrations/`.
  From the `lpg-backend` directory:
  ```bash
  supabase db push
  ```
  Or from the root `lpg/` directory:
  ```bash
  npm run migrate:db
  ```

## Logging

- **Supabase Functions:** When serverless functions are implemented, standard `console.log()`, `console.warn()`, and `console.error()` can be used. These logs are automatically captured and viewable in the Supabase Dashboard under your project's Function logs.
  - **Structure:** Aim for structured logs (e.g., JSON) for easier parsing and analysis, especially in a production environment.
  - **Privacy:** Ensure any Personally Identifiable Information (PII) or sensitive data is masked or redacted before logging, similar to the conventions in the frontend logger.
- **PostgreSQL Logs:** Database-level logging is configured within Supabase and can be reviewed in the Supabase Dashboard.

## Testing

A testing strategy for the backend is being established. Potential approaches include:

- **Database Integration Tests:**
  - Using tools like `pgTAP` for in-database testing of SQL functions, policies, and schema integrity.
  - Writing test scripts (e.g., using Node.js with a PostgreSQL client like `pg`) to execute queries against a test database and assert results.
- **Supabase Function Tests:**
  - Unit and integration tests for serverless functions using a JavaScript/TypeScript testing framework (e.g., Jest, Vitest).
  - Mocking Supabase client interactions where necessary.
- **API Tests (for functions exposed as an API):**
  - Using tools like Postman, `supertest` (if functions are part of an HTTP server locally), or custom scripts to test API endpoints.

(Placeholder for test setup and scripts in `package.json` will be added.)

## Future Considerations

- **Shared Contract Tests:** Once APIs are more defined between `lpg-ui` and `lpg-backend` (via Supabase Functions), contract tests (e.g., using Pact) will be considered to ensure compatibility.