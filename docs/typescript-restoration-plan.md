# TypeScript Strictness Restoration Plan

## Background

As part of our effort to achieve working deployments (following our `workflow_first_development` rule), we temporarily disabled TypeScript checking using the `NEXT_DISABLE_TYPECHECK=1` environment variable. While this approach helped unblock deployments, it accumulates technical debt that needs to be addressed to maintain code quality and align with our `enforce_typescript_strict` project rule.

## Restoration Approach

We will take an incremental approach to restore TypeScript strictness:

### Phase 1: Assessment & Inventory (Week 1)

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

### Phase 2: Targeted Fixes (Weeks 2-3)

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

### Phase 3: Configuration Restoration (Week 4)

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

## Success Metrics

- All TypeScript errors resolved or explicitly suppressed with justification
- Type checking restored in all environments (dev, test, CI/CD, production)
- Build times optimized with incremental checking
- Documentation of complex type patterns
- Zero regressions from type-related changes

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
