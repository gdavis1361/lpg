# Dependency Management Strategy

## Current Approach

The project currently uses `--legacy-peer-deps` flag with npm for dependency installation. This document explains why this approach is necessary and outlines our future plans for dependency management.

### Why We Use `--legacy-peer-deps`

1. **Peer Dependency Resolution**: This flag instructs npm to use the pre-npm v7 behavior for resolving peer dependencies, bypassing the stricter validation introduced in newer npm versions.

2. **Compatibility Layer**: Essential when working with packages that haven't updated their peer dependency specifications to align with modern React/Next.js versions.

3. **Monorepo Consideration**: Particularly important in our project structure where dependencies may have complex interrelationships between workspaces.

### Implementation Context

This strategy is applied in two key places:

1. **Local Development**: Developers should use `npm install --legacy-peer-deps` when setting up the project locally.

2. **CI/CD Pipeline**: Our GitHub Actions workflows use the same flag to ensure consistent builds.

```yaml
# Example from our GitHub Actions workflow
- name: Install dependencies
  run: cd lpg-ui && npm install --legacy-peer-deps
```

## Long-term Dependency Management Roadmap

While `--legacy-peer-deps` enables successful builds and deployments, we recognize it's not an ideal long-term solution. Here's our plan for improving dependency management:

### Q3 2025
- Identify specific packages requiring `--legacy-peer-deps`
- Create an inventory of problematic dependency constraints
- Document exact version requirements for critical packages

### Q4 2025
- Research alternatives or updates for problematic dependencies
- Test compatibility with newer versions in isolation
- Begin gradual updating of dependencies where possible

### Q1 2026
- Implement incremental dependency modernization
- Target removal of `--legacy-peer-deps` flag
- Establish stricter dependency management policies

## Trade-offs and Considerations

Using `--legacy-peer-deps` comes with some trade-offs:

1. **Reduced Build Determinism**: Slightly less deterministic than using `npm ci`
   
2. **Potential Conflicts**: May mask underlying dependency conflicts that could manifest in runtime edge cases

3. **Security Considerations**: Regular security audits are essential as peer dependency checks are bypassed

## Best Practices for Team Members

When working with this project:

1. Always use `npm install --legacy-peer-deps` for installation
2. Document any new dependencies and their version constraints
3. Run `npm audit` periodically to check for security vulnerabilities
4. Add comments when a specific package requires the legacy flag

---

This document follows our project's principles of `workflow_first_development` by prioritizing working deployments, `simplicity_first` by providing clear guidance, and `document_tech_decisions` by explaining our approach and future plans.
