#!/bin/bash
set -euo pipefail

# Cleanup script for source control issues

echo "Starting repository cleanup..."

# 1. Remove .DS_Store files from git repository
echo "Removing .DS_Store files from git index..."
find . -type f -name ".DS_Store" -print0 | xargs -0 git rm --cached --ignore-unmatch

# 2. Remove .env files that might be tracked
echo "Removing any .env files from git index..."
find . -type f -name ".env*" -not -name ".env.example" -print0 | xargs -0 git rm --cached --ignore-unmatch

# 3. Ensure large directories are properly ignored
echo "Ensuring large directories are properly ignored..."
git rm -r --cached lpg-ui/.next 2>/dev/null || echo "Directory lpg-ui/.next already ignored"
git rm -r --cached lpg-ui/.vercel 2>/dev/null || echo "Directory lpg-ui/.vercel already ignored"
git rm -r --cached lpg-ui/logs 2>/dev/null || echo "Directory lpg-ui/logs already ignored"
git rm -r --cached lpg-ui/.git.bak 2>/dev/null || echo "Directory lpg-ui/.git.bak already ignored"
git rm -r --cached logs 2>/dev/null || echo "Directory logs already ignored"

# 4. Clean up build artifacts
echo "Removing build artifacts..."
git rm --cached lpg-ui/module-patch.log 2>/dev/null || echo "File lpg-ui/module-patch.log already ignored"
git rm --cached lpg-ui/tsconfig.tsbuildinfo 2>/dev/null || echo "File lpg-ui/tsconfig.tsbuildinfo already ignored"

# 5. Update .gitignore to ensure these files don't get committed again
echo "Updating .gitignore file..."
if ! grep -qxF '**/.DS_Store' .gitignore; then
  echo '**/.DS_Store' >> .gitignore
fi
if ! grep -qxF '**/tsconfig.tsbuildinfo' .gitignore; then
  echo '**/tsconfig.tsbuildinfo' >> .gitignore
fi
if ! grep -qxF '**/*.log' .gitignore; then
  echo '**/*.log' >> .gitignore
fi
if ! grep -qxF '**/.vercel' .gitignore; then
  echo '**/.vercel' >> .gitignore
fi
if ! grep -qxF '**/.git.bak' .gitignore; then
  echo '**/.git.bak' >> .gitignore
fi
if ! grep -qxF '**/module-patch.log' .gitignore; then
  echo '**/module-patch.log' >> .gitignore
fi

# 6. Stage the updated .gitignore
git add .gitignore

echo "Cleanup complete. Please review the changes with 'git status' before committing." 