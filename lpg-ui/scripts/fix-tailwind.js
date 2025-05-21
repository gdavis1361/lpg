#!/usr/bin/env node

/**
 * This script fixes Tailwind CSS compatibility issues on Apple Silicon Macs
 * It removes incompatible Linux binary modules and ensures the correct platform modules are used
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

const platform = os.platform();
const arch = os.arch();

console.log(`Running Tailwind CSS fix for platform: ${platform}, architecture: ${arch}`);

// Only run this on macOS
if (platform !== 'darwin') {
  console.log('This script is intended for macOS only. Exiting.');
  process.exit(0);
}

// Paths to check and remove if needed
const problematicPaths = [
  path.join(process.cwd(), 'node_modules/@tailwindcss/oxide-linux-x64-gnu'),
  path.join(process.cwd(), 'node_modules/lightningcss-linux-x64-gnu')
];

// Remove problematic Linux binaries
problematicPaths.forEach(modulePath => {
  if (fs.existsSync(modulePath)) {
    console.log(`Found incompatible module: ${path.basename(modulePath)}`);
    try {
      fs.rmSync(modulePath, { recursive: true, force: true });
      console.log(`Removed ${path.basename(modulePath)}`);
    } catch (e) {
      console.error(`Error removing ${modulePath}: ${e.message}`);
    }
  } else {
    console.log(`No incompatible modules found at: ${path.basename(modulePath)}`);
  }
});

// Check for appropriate native modules for this platform
const expectedArchSuffix = arch === 'arm64' ? 'arm64' : 'x64';
const expectedModules = [
  `@tailwindcss/oxide-darwin-${expectedArchSuffix}`,
  `lightningcss-darwin-${expectedArchSuffix}`
];

const missingModules = expectedModules.filter(module => 
  !fs.existsSync(path.join(process.cwd(), 'node_modules', module))
);

if (missingModules.length > 0) {
  console.log(`\nMissing required modules for your platform: ${missingModules.join(', ')}`);
  console.log('Attempting to install the correct modules...');
  
  try {
    console.log('Installing tailwindcss with platform-specific flags...');
    execSync(`npm install tailwindcss --platform=darwin --arch=${arch}`, { stdio: 'inherit' });
    console.log('Installation completed successfully!');
  } catch (e) {
    console.error('Error during installation:', e.message);
    console.log('\nTry manually running:');
    console.log(`npm install --platform=darwin --arch=${arch}`);
  }
} else {
  console.log('\nAll required modules are properly installed!');
}

console.log('\nTailwind CSS fix completed. You can now run your development server.'); 