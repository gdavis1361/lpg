# Supabase Migration Plan: Safeguarded Deployment of `20240603_relationship_framework.sql`

## 1. Objective (Why This Plan is Being Implemented)

The primary goal is to safely deploy the `20240603_relationship_framework.sql` database migration to our Supabase project. This migration refactors the `relationships` table, introduces `relationship_types`, and modifies the `interactions` table. Due to the nature of these changes, particularly the data backfilling and new unique constraints, there are risks of failure if certain data conditions aren't met.

This plan aims to:
*   **Prevent Data Integrity Issues:** Specifically, ensure all existing `relationships.relationship_type` values can be mapped to the new `relationship_types` table, preventing orphaned data or `NOT NULL` constraint violations when `relationship_type_id` is populated.
*   **Avoid Constraint Violations:** Proactively check for and prevent failures due to duplicate active relationships that would violate the new partial unique index on `(from_person_id, to_person_id, relationship_type_id)`.
*   **Leverage Supabase Branch Environments:** Utilize Supabase Cloud's Branch Environments feature to create an isolated "staging" database. This allows the migrations to be run and validated on a fresh, production-like environment without impacting the actual production database.
*   **Automate Validation:** Embed SQL `DO` blocks directly into the migration script. These blocks will perform pre-flight checks and `RAISE EXCEPTION` (halting the migration) if unsafe conditions are detected, providing immediate feedback in the Supabase deployment logs.

## 2. Implementation Plan (How to Execute)

### Phase 1: Local Code Modification

1.  **Modify `lpg-backend/supabase/migrations/20240603_relationship_framework.sql`:**
    *   Add two specific SQL `DO` blocks (detailed in section 3 below) into this migration file. These blocks are safeguards that will run as part of the migration.

### Phase 2: Git and Supabase Cloud Workflow

1.  **Create a Staging Branch:**
    *   Locally, create a new Git branch from your current working branch (e.g., `main` or `develop`). Name it `staging` (or a similar descriptive name like `supabase-preview-relationship-fix`).
    ```bash
    git checkout -b staging
    ```

2.  **Commit Changes:**
    *   Add the modified migration file to Git.
    *   Commit the changes with a clear message.
    ```bash
    git add lpg-backend/supabase/migrations/20240603_relationship_framework.sql
    git commit -m "feat(db): add safeguards to relationship_framework migration for validation"
    ```

3.  **Configure Supabase Branch Environment (if not already done for this branch name):**
    *   Go to your Supabase project dashboard.
    *   Navigate to **Project Settings** → **Branch Environments**.
    *   If a "staging" (or your chosen branch name) environment doesn't exist, create one. Map your Git branch (`staging`) to this new Supabase environment. This will provision a new, isolated Postgres instance for this branch.
    *   Note down the `Project Ref` for this new staging environment if you need to use the Supabase CLI to link to it explicitly (though often, Supabase detects pushes to linked branches automatically). If explicit linking is needed:
        ```bash
        # Run this once locally in your project directory
        # supabase link --project-ref <STAGING_PROJECT_REF>
        ```
        (Ensure your local Supabase CLI is logged in: `supabase login`)

4.  **Push to Staging Branch:**
    *   Push the new local `staging` branch to your remote repository (e.g., GitHub).
    ```bash
    git push --set-upstream origin staging
    ```

5.  **Automated Staging Deployment & Validation:**
    *   Supabase CI/CD (or GitHub Actions integrated with Supabase) should automatically detect the push to the `staging` branch.
    *   It will attempt to apply all migrations, including the modified `20240603_relationship_framework.sql`, to the isolated "staging" database instance.
    *   The embedded `DO` blocks will execute.

6.  **Verify in Supabase Cloud:**
    *   In the Supabase dashboard, navigate to your "staging" branch environment.
    *   Check the "Branch Logs" or "Database Migrations" section for this environment.
    *   **Success Scenario:** You should see `RAISE NOTICE` messages from the `DO` blocks indicating the number of unmapped rows and duplicate groups (hopefully zero for both). The migration should complete successfully without any `RAISE EXCEPTION` messages.
    *   **Failure Scenario:** If a `DO` block detects an issue, it will `RAISE EXCEPTION`. The migration will fail, and the error message will be visible in the logs. This is the desired outcome if problems exist, as it protects production.
    *   Optionally, use the SQL Editor in the Supabase dashboard (connected to the staging environment) to inspect the schema (`relationships`, `relationship_types` tables) and run manual queries (like your original validation queries A & B) to double-check.

7.  **Address Issues (If Staging Fails):**
    *   If the migration fails on staging, analyze the error.
    *   Make necessary data cleanups (directly in staging if it's just for testing, or plan for cleanup in production *before* the real migration) or adjust the `relationship_types` seed data in `20240603_relationship_framework.sql`.
    *   Commit fixes to the `staging` branch and re-push to trigger another validation run. Repeat until staging deployment is successful.

### Phase 3: Production Deployment

1.  **Merge to Main/Production Branch:**
    *   Once the `staging` branch deploys cleanly and you've verified its correctness, merge the `staging` branch into your main production branch (e.g., `main`).
    ```bash
    git checkout main
    git merge staging --no-ff -m "feat(db): merge validated relationship framework migration"
    git push origin main
    ```
2.  **Production Deployment:**
    *   The push to `main` will trigger the Supabase CI/CD to deploy the migrations to your actual production Supabase project. Since it passed on an identical (fresh) staging environment with safeguards, the risk of failure is now significantly minimized.

### Phase 4: Cleanup (Optional)

1.  Consider deleting the "staging" Supabase Branch Environment to save resources, or keep it for future migration testing.
2.  Delete the local and remote `staging` Git branch if no longer needed.

## 3. Specific Code Changes Required (What to Add to the SQL File)

**Target File:** `lpg-backend/supabase/migrations/20240603_relationship_framework.sql`

**Safeguard Block 1: Check for Unmapped `relationship_type` values**

*   **Placement:** Insert this `DO` block *immediately before* the line: `ALTER TABLE relationships ALTER COLUMN relationship_type_id SET NOT NULL;` (which is step 2.3 in the migration).
*   **SQL Code:**
    ```sql
    -- Safeguard: Check for unmapped relationship_type values before making relationship_type_id NOT NULL
    DO $$
    DECLARE
      unmapped_count INTEGER;
      sample_unmapped_types TEXT;
    BEGIN
      SELECT COUNT(*), array_to_string(array_agg(DISTINCT r.relationship_type), ', ')
      INTO unmapped_count, sample_unmapped_types
      FROM relationships r
      LEFT JOIN relationship_types rt ON rt.code = r.relationship_type
      WHERE r.relationship_type IS NOT NULL AND rt.id IS NULL;

      RAISE NOTICE 'Found % unmapped relationship_type values. Sample unmapped types: %', unmapped_count, COALESCE(sample_unmapped_types, 'None');

      IF unmapped_count > 0 THEN
        RAISE EXCEPTION 'Aborting migration: % unmapped relationship_type values detected. Please seed these types in relationship_types or clean data. Sample problematic types: %', unmapped_count, COALESCE(sample_unmapped_types, 'None');
      END IF;
    END;
    $$;
    ```

**Safeguard Block 2: Check for Duplicates Violating New Unique Index**

*   **Placement:** Insert this `DO` block *immediately before* the line: `CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_relationship ON relationships(from_person_id, to_person_id, relationship_type_id) WHERE status = 'active' AND end_date IS NULL;` (which is part of step 2.6).
*   **SQL Code:**
    ```sql
    -- Safeguard: Check for duplicate active relationships based on (from_person_id, to_person_id, relationship_type_id)
    -- This check assumes relationship_type_id has been successfully populated by this stage.
    DO $$
    DECLARE
      duplicate_group_count INTEGER;
    BEGIN
      SELECT COUNT(*)
      INTO duplicate_group_count
      FROM (
        SELECT 1
        FROM relationships
        WHERE status = 'active'
          AND end_date IS NULL
          AND relationship_type_id IS NOT NULL -- Should be NOT NULL if previous steps and safeguard passed
        GROUP BY from_person_id, to_person_id, relationship_type_id
        HAVING COUNT(*) > 1
      ) AS duplicate_groups;

      RAISE NOTICE 'Found % groups of (from_person_id, to_person_id, relationship_type_id) that would violate the new unique index for active relationships.', duplicate_group_count;

      IF duplicate_group_count > 0 THEN
        RAISE EXCEPTION 'Aborting migration: % groups of duplicate active relationships detected (based on from_person_id, to_person_id, relationship_type_id) that would violate the new unique index. Please clean/merge these duplicates or mark them as inactive/ended.';
      END IF;
    END;
    $$;
    ```

---

By following this detailed plan, we can confidently implement the database changes with multiple layers of validation. 