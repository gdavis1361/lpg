#!/bin/bash

# Cleanup script for source control issues

echo "Starting repository cleanup..."

# 1. Remove .DS_Store files from git repository
echo "Removing .DS_Store files from git index..."
find . -name ".DS_Store" | xargs git rm --cached

# 2. Remove .env files that might be tracked
echo "Removing any .env files from git index..."
find . -name ".env*" -not -name ".env.example" | xargs git rm --cached

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
cat << EOF >> .gitignore

# Additional ignores
**/.DS_Store
**/tsconfig.tsbuildinfo
**/*.log
**/.vercel
**/.git.bak
**/module-patch.log
EOF

# 6. Stage the updated .gitignore
git add .gitignore

echo "Cleanup complete. Please review the changes with 'git status' before committing." 