#!/bin/bash

# Standardize project structure script

echo "Starting project standardization..."

# Check if we're at the root of the project
if [ ! -f "package.json" ]; then
  echo "Error: This script must be run from the root of the project"
  exit 1
fi

# 1. Ensure consistent package-lock.json usage
echo "Ensuring consistent package management..."

# If both root and lpg-ui have package-lock.json, ensure they're using the same npm version
ROOT_NPM_VERSION=$(node -e "try { console.log(require('./package-lock.json').lockfileVersion) } catch(e) { console.log('unknown') }")
UI_NPM_VERSION=$(node -e "try { console.log(require('./lpg-ui/package-lock.json').lockfileVersion) } catch(e) { console.log('unknown') }")

echo "Root lockfile version: $ROOT_NPM_VERSION"
echo "UI lockfile version: $UI_NPM_VERSION"

# 2. Create standard directories if they don't exist
echo "Ensuring standard directory structure..."
mkdir -p docs
mkdir -p scripts
mkdir -p lpg-ui/scripts
mkdir -p logs
mkdir -p lpg-ui/logs

# 3. Create a unified README.md if it doesn't exist
if [ ! -f "README.md" ]; then
  echo "Creating a standard README.md..."
  cat << EOF > README.md
# LPG Project

## Overview
This repository contains the LPG (Learning Platform for Growth) project, divided into:
- \`lpg-ui\`: Frontend Next.js application
- \`lpg-backend\`: Backend services and database migrations

## Getting Started

### Prerequisites
- Node.js 22.x
- npm 10.x or later
- Supabase CLI

### Installation
1. Clone the repository
2. Install dependencies: \`npm install\`
3. Set up environment variables (see \`.env.example\` files)
4. Start development server: \`npm run dev\`

### Development Workflow
See \`CONTRIBUTING.md\` for guidelines on contributing to this project.

## Project Structure
- \`/lpg-ui\`: Frontend Next.js application
- \`/lpg-backend\`: Backend Supabase services
- \`/docs\`: Project documentation
- \`/scripts\`: Utility scripts for development and deployment

## License
Proprietary - All rights reserved
EOF
fi

# 4. Create CONTRIBUTING.md if it doesn't exist
if [ ! -f "CONTRIBUTING.md" ]; then
  echo "Creating CONTRIBUTING.md..."
  cat << EOF > CONTRIBUTING.md
# Contributing to LPG

Thank you for your interest in contributing to LPG! This document provides guidelines and instructions for contributing.

## Development Process

### Branching Strategy
- \`main\`: Production-ready code
- \`feature/*\`: New features
- \`bugfix/*\`: Bug fixes
- \`cleanup/*\`: Code cleanup and refactoring

### Pull Request Process
1. Create a branch from \`main\` with the appropriate prefix
2. Make your changes, following the coding standards
3. Submit a pull request to \`main\`
4. Ensure all checks pass
5. Request a review from a maintainer

## Coding Standards

### General
- Follow consistent naming conventions
- Write clear, descriptive comments
- Include appropriate tests for your changes

### Frontend (Next.js)
- Follow component-based architecture
- Use React hooks appropriately
- Follow the established UI patterns
- Use TypeScript for all new code

### Backend (Supabase)
- Follow PostgreSQL best practices
- Ensure Row Level Security policies are properly implemented
- Document all database changes in migration files

## Environment Setup
See the README.md for instructions on setting up your development environment.

## Questions?
If you have any questions, please reach out to the project maintainers.
EOF
fi

echo "Project standardization complete!" 