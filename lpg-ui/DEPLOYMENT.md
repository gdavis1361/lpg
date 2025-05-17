# LPG-UI Deployment Guide

## Overview

This document provides a comprehensive guide to deploying the LPG-UI project on Vercel. It explains our deployment strategy, configuration optimizations, and monitoring tools implemented to ensure reliable deployments.

## Deployment Strategy

We follow a **workflow-first** approach to deployment:

1. **Prioritize working deployments** over strict type checking
2. **Optimize build configuration** for reliability
3. **Monitor deployment health** continuously
4. **Restore type safety** incrementally without breaking deployments

## Key Files

- **Root `/vercel.json`**: Primary deployment configuration
- **`lpg-ui/package.json`**: Contains build scripts including `build:vercel`
- **`lpg-ui/next.config.js`**: Next.js configuration optimized for production
- **`lpg-ui/.npmrc`**: Controls dependency resolution with `legacy-peer-deps=true`

## Build Process

The build process is configured to:

1. Install dependencies with `npm --prefix lpg-ui ci --legacy-peer-deps`
2. Run the specialized `build:vercel` script which:
   - Runs prestart diagnostics
   - Sets environment variables to bypass TypeScript and ESLint checks
   - Applies module patching for Lightning CSS compatibility
   - Includes a fallback mechanism for failed builds

## Environment Variables

### Build-Time Variables

These environment variables control the build process:

- `NEXT_DISABLE_TYPECHECK=1`: Disables TypeScript checking
- `NEXT_DISABLE_ESLINT=1`: Disables ESLint
- `NEXT_TELEMETRY_DISABLED=1`: Disables telemetry
- `NODE_OPTIONS='--require ./module-patch.js'`: Module patching for CSS compatibility

### Doppler Integration

The project uses Doppler for environment variable management with:

- Project environments: 'dev' and 'prod'
- GitHub Actions integration via DOPPLER_TOKEN
- Environment validation via scripts/validate-env.js

## Monitoring Tools

### Build Optimization

Run `node scripts/optimize-build.js` to:
- Measure build performance
- Implement incremental TypeScript checking
- Analyze bundle size

### Environment Variable Monitoring

Run `node scripts/env-monitor.js` to:
- Validate required environment variables
- Check for deprecated variable usage
- Verify Doppler integration

### Deployment Health Monitoring

Run `node scripts/deployment-monitor.js` to:
- Track deployment success
- Monitor runtime issues
- Generate health reports

## Technical Debt Management

We've created comprehensive plans to address technical debt:

1. **TypeScript Restoration Plan** - `/docs/typescript-restoration-plan.md`
2. **ESLint Restoration Plan** - `/docs/eslint-restoration-plan.md` 
3. **Dependency Stabilization Plan** - `/docs/dependency-stabilization-plan.md`

## CI/CD Integration

The GitHub Actions workflow in `.github/workflows/deployment-monitor.yml` automatically:
- Monitors deployment health
- Verifies environment variables
- Alerts on failures

## Troubleshooting

If deployment fails:

1. Check Vercel logs for specific errors
2. Verify environment variables in Doppler and Vercel
3. Run `node scripts/env-monitor.js --check-doppler` to validate configuration
4. Check for dependency conflicts or build-time errors
