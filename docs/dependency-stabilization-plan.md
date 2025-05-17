# Dependency Stabilization Plan

## Current State Analysis

The project currently uses multiple pre-release dependencies which are creating stability issues:

- **Next.js 15.3.2 (canary)** - Pre-release features with potential breaking changes
- **React 19 (alpha)** - Alpha features with incomplete TypeScript definitions
- **Tailwind CSS 4 (beta)** - Beta features with potential incompatibilities
- **Lightning CSS** - WASM compatibility challenges requiring module patching

This combination has several implications:
1. Requires `--legacy-peer-deps` during installation
2. Necessitates custom module patching 
3. Creates TypeScript definition conflicts
4. Results in build configuration complexities

## Stabilization Approach

Following our `workflow_first_development` and `simplicity_first` principles, we'll take a staged approach to dependency stabilization:

### Phase 1: Immediate Configuration Stability (Week 1)

1. **Create Package Lock File**
   - Generate package-lock.json with `npm install --package-lock-only`
   - Commit this to repository for consistent installations
   - Enable `npm ci` usage in build processes

2. **Version Pinning**
   - Pin exact versions of all dependencies (remove ^ and ~)
   - Pin transitive dependencies through package-lock.json
   - Create .npmrc to enforce pinning with `save-exact=true`

3. **Module Patching Assessment**
   - Evaluate if module-patch.js is still necessary with latest dependencies
   - Adjust patching method if needed for Vercel's Linux environment
   - Test build with and without patching to determine necessity

### Phase 2: Dependency Rationalization (Weeks 2-3)

We have two possible approaches, with Option 1 as the recommended path:

**Option 1: Stability Focus (Recommended)**
   - Downgrade to stable Next.js 14.x
   - Use stable React 18.x
   - Use stable Tailwind CSS 3.x
   - Remove module patching if no longer needed
   - This approach prioritizes stability and build reliability

**Option 2: Cutting Edge with Proper Configuration**
   - Maintain current versions but properly configure them
   - Add proper peer dependency resolutions
   - Update TypeScript definitions for alpha/beta APIs
   - Implement comprehensive testing for experimental features
   - This approach keeps cutting-edge features but requires more maintenance

### Phase 3: Long-term Dependency Strategy (Ongoing)

1. **Versioning Policy**
   - Only use pre-release dependencies in feature branches
   - Require stability benchmarks before upgrading main dependencies
   - Document upgrade paths and breaking changes

2. **Testing Framework**
   - Implement comprehensive dependency testing
   - Create visual regression tests for UI components
   - Use end-to-end tests to validate critical paths

3. **Maintenance Automation**
   - Setup Dependabot or similar for update notifications
   - Create automated testing for dependency upgrades
   - Implement scheduled dependency audits

## Integration with Code Quality

This plan coordinates with our other restoration efforts:

1. **TypeScript Integration**
   - Dependency changes must align with TypeScript restoration plan
   - Ensure type definitions are complete for all dependencies
   - Fix type compatibility issues between packages

2. **ESLint Integration**
   - Update ESLint plugins for compatibility with dependency versions
   - Add ESLint rules for proper dependency usage
   - Enforce best practices for import patterns

## Success Metrics

- Build success rate increased to 100%
- Dependency resolution time decreased by 50%
- No manual intervention required for builds
- Clear upgrade paths documented for all dependencies
- Test coverage for all critical dependency integrations

## Risk Management

| Risk | Mitigation |
|------|------------|
| Breaking changes in upgrades | Comprehensive test suite and staged rollouts |
| Deployment failures | Maintain fallback deployment mechanism during transitions |
| Developer productivity impact | Provide clear documentation and setup automation |
| Feature loss from downgrades | Document any features that would be lost and provide alternatives |

This plan embodies our `simplicity_first` rule by prioritizing working software over experimental features, while maintaining a path toward innovative capabilities through proper planning and testing.
