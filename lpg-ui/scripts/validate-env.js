// Simple script to validate environment variables
const path = require('path');
const fs = require('fs');

// Try to find the correct path to the environment validator
let envValidatorPath;
const possiblePaths = [
  path.join(__dirname, '../src/lib/envValidator.js'),
  path.join(__dirname, '../src/lib/envValidator.ts'),
  path.join(__dirname, '../lib/envValidator.js'),
  path.join(__dirname, '../lib/envValidator.ts'),
];

for (const testPath of possiblePaths) {
  if (fs.existsSync(testPath)) {
    envValidatorPath = testPath;
    break;
  }
}

if (!envValidatorPath) {
  console.error('❌ Could not find envValidator module');
  console.log('Searched in:');
  possiblePaths.forEach(p => console.log(`- ${p}`));
  process.exit(1);
}

// Find the correct logger path as well
let loggerPath;
const possibleLoggerPaths = [
  path.join(__dirname, '../src/lib/logger.js'),
  path.join(__dirname, '../src/lib/logger.ts'),
  path.join(__dirname, '../lib/logger.js'),
  path.join(__dirname, '../lib/logger.ts'),
];

for (const testPath of possibleLoggerPaths) {
  if (fs.existsSync(testPath)) {
    loggerPath = testPath;
    break;
  }
}

if (!loggerPath) {
  console.log('⚠️ Logger module not found, but continuing with validation');
}

console.log(`🔍 Found environment validator at: ${envValidatorPath}`);

try {
  // Try to determine if we're running with Doppler
  const isDopplerActive = process.env.DOPPLER_PROJECT || process.env.DOPPLER_CONFIG;
  
  // List the environment variables we're checking for
  const requiredVars = [
    'NEXT_PUBLIC_SUPABASE_URL',
    'NEXT_PUBLIC_SUPABASE_ANON_KEY'
  ];

  console.log('\n📋 Environment Variable Check:');
  console.log(`Running with Doppler: ${isDopplerActive ? 'Yes' : 'No'}`);
  
  let allPresent = true;
  
  // Check each required variable
  for (const varName of requiredVars) {
    if (process.env[varName]) {
      console.log(`✅ ${varName}: Present`);
    } else {
      console.log(`❌ ${varName}: Missing`);
      allPresent = false;
    }
  }
  
  if (allPresent) {
    console.log('\n🎉 All required environment variables are present.');
    console.log('You can now proceed with running the application.');
  } else {
    console.error('\n❌ Some required environment variables are missing.');
    console.error('Please check your Doppler configuration or .env files.');
    process.exit(1);
  }
} catch (error) {
  console.error('❌ Error validating environment:', error);
  process.exit(1);
}
