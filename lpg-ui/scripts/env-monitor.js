#!/usr/bin/env node

/**
 * Environment Variable Monitoring Script
 * 
 * This script provides enhanced monitoring and validation for environment variables:
 * 1. Validates required environment variables are present
 * 2. Checks for correct formatting/values in critical variables
 * 3. Creates warnings for deprecated or unused variables
 * 4. Verifies Doppler integration is working correctly
 * 
 * Usage:
 *   node scripts/env-monitor.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const ROOT_DIR = path.resolve(__dirname, '..');
const ENV_FILE_PATH = path.join(ROOT_DIR, '.env.local');
const DOPPLER_CHECK = process.argv.includes('--check-doppler');

// Define environment variable requirements
const requiredVars = [
  { name: 'NEXT_PUBLIC_SUPABASE_URL', pattern: /^https:\/\/.*\.supabase\.co$/ },
  { name: 'NEXT_PUBLIC_SUPABASE_ANON_KEY', pattern: /^ey.*/ },
  { name: 'SUPABASE_SERVICE_ROLE_KEY', pattern: /^ey.*/ },
  { name: 'SUPABASE_JWT_SECRET', pattern: /.{10,}/ },
];

// Optional but recommended variables
const recommendedVars = [
  { name: 'NEXT_TELEMETRY_DISABLED', recommended: '1' },
  { name: 'NEXT_SHARP_PATH', info: 'Speeds up image optimization' },
];

// Deprecated variables to warn about
const deprecatedVars = [
  { name: 'SKIP_TYPECHECK', replacement: 'NEXT_DISABLE_TYPECHECK' },
  { name: 'SKIP_ESLINT', replacement: 'NEXT_DISABLE_ESLINT' },
];

// Variables used in different environments
const environmentSpecificVars = {
  development: [
    'NEXT_TURBO',
  ],
  production: [
    'VERCEL_URL',
    'VERCEL_ENV',
  ],
};

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

// Check if a variable exists in the environment
function checkVar(name) {
  return process.env[name] !== undefined;
}

// Validate a variable's value against a pattern
function validateVar(name, pattern) {
  const value = process.env[name];
  if (!value) return false;
  
  if (pattern instanceof RegExp) {
    return pattern.test(value);
  }
  
  return true;
}

// Check for Doppler integration
function checkDoppler() {
  console.log(`\n${colors.cyan}Checking Doppler integration...${colors.reset}`);
  
  try {
    // Check if Doppler CLI is installed
    try {
      execSync('doppler --version', { stdio: 'ignore' });
      console.log(`${colors.green}✓ Doppler CLI is installed${colors.reset}`);
    } catch (e) {
      console.log(`${colors.red}✗ Doppler CLI is not installed${colors.reset}`);
      console.log(`  Run: npm install -g @dopplerhq/cli`);
      return false;
    }
    
    // Check Doppler configuration
    try {
      const configOutput = execSync('doppler configure').toString();
      console.log(`${colors.green}✓ Doppler is configured${colors.reset}`);
      
      // Check for project and environment
      const projectMatch = configOutput.match(/Project: (.*)/);
      const envMatch = configOutput.match(/Environment: (.*)/);
      
      if (projectMatch && projectMatch[1]) {
        console.log(`  Project: ${projectMatch[1]}`);
      }
      
      if (envMatch && envMatch[1]) {
        console.log(`  Environment: ${envMatch[1]}`);
      }
    } catch (e) {
      console.log(`${colors.yellow}⚠ Could not verify Doppler configuration${colors.reset}`);
      console.log(`  Run: doppler login && doppler setup`);
    }
    
    // Check for DOPPLER_TOKEN in GitHub Actions
    if (fs.existsSync(path.join(ROOT_DIR, '../.github/workflows'))) {
      try {
        const workflowFiles = fs.readdirSync(path.join(ROOT_DIR, '../.github/workflows'));
        
        let tokenFound = false;
        for (const file of workflowFiles) {
          if (!file.endsWith('.yml') && !file.endsWith('.yaml')) continue;
          
          const content = fs.readFileSync(path.join(ROOT_DIR, '../.github/workflows', file), 'utf8');
          if (content.includes('DOPPLER_TOKEN')) {
            tokenFound = true;
            break;
          }
        }
        
        if (tokenFound) {
          console.log(`${colors.green}✓ DOPPLER_TOKEN found in GitHub workflows${colors.reset}`);
        } else {
          console.log(`${colors.yellow}⚠ DOPPLER_TOKEN not found in GitHub workflows${colors.reset}`);
          console.log(`  Make sure to add DOPPLER_TOKEN to your GitHub repository secrets`);
        }
      } catch (e) {
        console.log(`${colors.yellow}⚠ Could not check GitHub workflows${colors.reset}`);
      }
    }
    
    return true;
  } catch (e) {
    console.log(`${colors.red}✗ Error checking Doppler: ${e.message}${colors.reset}`);
    return false;
  }
}

// Main execution
function main() {
  console.log(`${colors.cyan}Environment Variable Monitor${colors.reset}`);
  console.log(`${colors.cyan}=============================${colors.reset}`);
  
  // Check required variables
  console.log(`\n${colors.blue}Required Variables:${colors.reset}`);
  let requiredErrors = 0;
  
  for (const variable of requiredVars) {
    const exists = checkVar(variable.name);
    const isValid = variable.pattern ? validateVar(variable.name, variable.pattern) : exists;
    
    if (!exists) {
      console.log(`${colors.red}✗ ${variable.name} is missing${colors.reset}`);
      requiredErrors++;
    } else if (!isValid) {
      console.log(`${colors.red}✗ ${variable.name} has invalid format${colors.reset}`);
      requiredErrors++;
    } else {
      console.log(`${colors.green}✓ ${variable.name}${colors.reset}`);
    }
  }
  
  // Check recommended variables
  console.log(`\n${colors.blue}Recommended Variables:${colors.reset}`);
  
  for (const variable of recommendedVars) {
    const exists = checkVar(variable.name);
    
    if (!exists) {
      console.log(`${colors.yellow}⚠ ${variable.name} is not set${colors.reset}`);
      if (variable.recommended) {
        console.log(`  Recommended value: ${variable.recommended}`);
      }
      if (variable.info) {
        console.log(`  Note: ${variable.info}`);
      }
    } else {
      const value = process.env[variable.name];
      if (variable.recommended && value !== variable.recommended) {
        console.log(`${colors.yellow}⚠ ${variable.name}=${value} (recommended: ${variable.recommended})${colors.reset}`);
      } else {
        console.log(`${colors.green}✓ ${variable.name}=${value}${colors.reset}`);
      }
    }
  }
  
  // Check for deprecated variables
  console.log(`\n${colors.blue}Deprecated Variables:${colors.reset}`);
  let usingDeprecated = false;
  
  for (const variable of deprecatedVars) {
    const exists = checkVar(variable.name);
    
    if (exists) {
      console.log(`${colors.yellow}⚠ ${variable.name} is deprecated${colors.reset}`);
      if (variable.replacement) {
        console.log(`  Use ${variable.replacement} instead`);
      }
      usingDeprecated = true;
    }
  }
  
  if (!usingDeprecated) {
    console.log(`${colors.green}✓ No deprecated variables in use${colors.reset}`);
  }
  
  // Environment-specific check
  const nodeEnv = process.env.NODE_ENV || 'development';
  console.log(`\n${colors.blue}Environment: ${nodeEnv}${colors.reset}`);
  
  const envVars = environmentSpecificVars[nodeEnv] || [];
  for (const varName of envVars) {
    const exists = checkVar(varName);
    
    if (!exists) {
      console.log(`${colors.yellow}⚠ ${varName} is recommended for ${nodeEnv}${colors.reset}`);
    } else {
      console.log(`${colors.green}✓ ${varName}=${process.env[varName]}${colors.reset}`);
    }
  }
  
  // Check Doppler if requested
  if (DOPPLER_CHECK) {
    checkDoppler();
  }
  
  // Summary and exit code
  console.log(`\n${colors.blue}Summary:${colors.reset}`);
  
  if (requiredErrors > 0) {
    console.log(`${colors.red}✗ ${requiredErrors} required variables missing or invalid${colors.reset}`);
    console.log(`  Fix these issues before proceeding to production`);
    process.exit(1);
  } else {
    console.log(`${colors.green}✓ All required variables are present and valid${colors.reset}`);
    
    if (usingDeprecated) {
      console.log(`${colors.yellow}⚠ Using deprecated variables - consider updating${colors.reset}`);
    }
    
    process.exit(0);
  }
}

// Run the script
main();
