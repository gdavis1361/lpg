# TypeScript Strict Mode Guide

## Background

As part of our effort to achieve working deployments (following our `workflow_first_development` rule), we temporarily disabled TypeScript checking using the `NEXT_DISABLE_TYPECHECK=1` environment variable. This was addressed by fully enabling TypeScript strict mode in May 2025. This document outlines the current strict mode configuration, provides guidance for maintaining type safety, and details the project's ongoing maintenance strategy.

---

## Strict Mode Implementation (May 2025)

As of May 2025, TypeScript strict mode has been fully enabled in `lpg-ui/tsconfig.json` to align with the `enforce_typescript_strict: true` project rule. This section details the configuration and provides guidance for maintaining strict type safety.

### Configuration Summary

- **`tsconfig.json`**:
  - `"strict": true`
  - Additional strict flags enabled:
    - `noImplicitAny`
    - `strictNullChecks`
    - `strictFunctionTypes`
    - `strictBindCallApply`
    - `strictPropertyInitialization`
    - `noImplicitThis`
    - `useUnknownInCatchVariables`
- **ESLint (`.eslintrc.json`)**:
  - Extends `plugin:@typescript-eslint/recommended`.
  - Enforces critical rules:
    - `@typescript-eslint/explicit-function-return-type: "error"`
    - `@typescript-eslint/no-explicit-any: "error"`
    - `@typescript-eslint/no-unused-vars: "error"`
- **CI/CD (`.github/workflows/doppler-ci.yml`)**:
  - The "TypeScript strict check" step (`npx tsc --noEmit`) no longer uses `continue-on-error`, meaning type errors will fail the build.

### Common Strict Mode Issues & Solutions

1.  **Missing Explicit Return Types**:
    *   **Issue**: Functions without explicit return types (`@typescript-eslint/explicit-function-return-type`).
    *   **Solution**: Add a return type to all functions. For React components, use `JSX.Element` or `React.ReactNode`. For functions not returning a value, use `void`. For async functions, wrap the return type in `Promise<>` (e.g., `Promise<void>`, `Promise<string>`).

2.  **Implicit `any` Types**:
    *   **Issue**: Variables or parameters implicitly typed as `any` (`noImplicitAny` in `tsconfig`, `@typescript-eslint/no-explicit-any` in ESLint).
    *   **Solution**: Provide explicit types. Use `unknown` for values that are truly unknown and then perform type checking or use type assertions carefully. Avoid `any` where possible.

3.  **Strict Null Checks (`strictNullChecks`)**:
    *   **Issue**: Variables that could be `null` or `undefined` are not handled, leading to potential runtime errors.
    *   **Solution**:
        *   Explicitly check for `null` or `undefined` before accessing properties.
        *   Use optional chaining (`?.`) and nullish coalescing (`??`).
        *   Define types that explicitly include `null` or `undefined` (e.g., `string | null`).

4.  **Component Props Typing**:
    *   **Issue**: React component props are not explicitly typed.
    *   **Solution**: Define an interface or type for component props.
        ```typescript
        interface MyComponentProps {
          title: string;
          onClick: () => void;
        }
        const MyComponent = ({ title, onClick }: MyComponentProps): JSX.Element => {
          // ...
        };
        ```

5.  **Environment Variables**:
    *   **Issue**: `process.env` properties are not typed.
    *   **Solution**: Define expected environment variables in `lpg-ui/src/types/env.d.ts`:
        ```typescript
        declare namespace NodeJS {
          interface ProcessEnv {
            NEXT_PUBLIC_SUPABASE_URL: string;
            NEXT_PUBLIC_SUPABASE_ANON_KEY: string;
            // Add other environment variables
          }
        }
        ```

### Best Practices for Maintaining Strictness

*   **Type Early, Type Often**: Add types as you write new code, rather than retrofitting later.
*   **Leverage Utility Types**: Use TypeScript's built-in utility types (e.g., `Partial`, `Required`, `Readonly`, `Pick`, `Omit`) to create new types from existing ones.
*   **Specific Over Generic**: Prefer specific types over `any` or overly broad types like `object`. Use `unknown` when the type is genuinely unknown at compile time and then narrow it down.
*   **Keep Supabase Types Updated**: Regularly run `npm run types:supabase` (especially after database schema changes) to ensure `src/types/supabase.ts` is current.
*   **ESLint Integration**: Pay attention to ESLint warnings and errors in your IDE to catch type issues early.

---

## Maintenance Strategy

To prevent future type-related technical debt:

1. **Proactive Typing**
   - Define types upfront for new features
   - Add typing tests for critical interfaces
   - Use Zod or similar for runtime validation of critical data

2. **Regular Audits**
   - Weekly audit of new TypeScript suppressions
   - Monthly dependency type updates
   - Quarterly type coverage report

3. **Knowledge Sharing**
   - Document common typing patterns
   - Create team training on effective TypeScript usage
   - Review complex type implementations

---

## Appendix: Original TypeScript Strictness Restoration Plan

This appendix details the phased approach originally taken to restore TypeScript strictness in the project.

### Restoration Approach

We will take an incremental approach to restore TypeScript strictness:

#### Phase 1: Assessment & Inventory (Week 1)

1. **Enable TypeScript in Development Only**
   - Keep TypeScript disabled for production builds
   - Enable TypeScript checking in the development workflow to identify issues
   - Run `tsc --noEmit` in CI to identify type errors without blocking deployments

2. **Error Categorization**
   - Create an inventory of all TypeScript errors
   - Categorize by severity, component, and estimated fix complexity
   - Identify patterns and common issues

3. **Critical Path Identification**
   - Map TypeScript errors to critical user paths
   - Prioritize fixing errors in high-impact areas first
   - Create JIRA tickets for all identified issues

#### Phase 2: Targeted Fixes (Weeks 2-3)

1. **Low-Hanging Fruit**
   - Fix simple type errors (missing types, any casts, etc.)
   - Update dependency type definitions
   - Address deprecated API usages

2. **Component-by-Component Approach**
   - Address errors in one component/module at a time
   - Update tests to verify behavior is preserved
   - Document complex type patterns for team reference

3. **Supabase Type Integration**
   - Ensure database types from `types:supabase` are properly used
   - Validate API responses against expected types
   - Implement runtime type validation for critical data

#### Phase 3: Configuration Restoration (Week 4)

1. **Gradual Strictness Setting Restoration**
   - Enable incremental type checking with `NEXT_TYPECHECK_INCREMENTAL=1`
   - Gradually reintroduce strict settings in `tsconfig.json`
   - Implement progressive type checking in CI pipeline

2. **Build Integration**
   - Remove `NEXT_DISABLE_TYPECHECK=1` from development builds
   - Add pre-commit hooks for type checking
   - Re-enable type checking for specific modules in production builds

3. **Final Restoration**
   - Remove `NEXT_DISABLE_TYPECHECK=1` from all environments
   - Ensure CI/CD enforces type checking
   - Verify deployment process with TypeScript checking restored

### Success Metrics

- All TypeScript errors resolved or explicitly suppressed with justification
- Type checking restored in all environments (dev, test, CI/CD, production)
- Build times optimized with incremental checking
- Documentation of complex type patterns
- Zero regressions from type-related changes 