// This file handles platform-specific module patching for Tailwind CSS and LightningCSS
// It's used during the build process to ensure compatibility across different environments

const Module = require('module');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Store the original require function
const originalRequire = Module.prototype.require;

// Detect the platform
const platform = os.platform();
const arch = os.arch();
console.log(`Detected platform: ${platform}, architecture: ${arch}`);

// Create a custom require function to handle platform-specific modules
Module.prototype.require = function(...args) {
  const modulePath = args[0];
  
  // Handle Tailwind's oxide binaries
  if (modulePath && modulePath.includes('@tailwindcss/oxide')) {
    // Check if we're targeting Linux x64 but running on Darwin (macOS)
    if (modulePath.includes('linux-x64-gnu') && platform === 'darwin') {
      console.log(`Attempting to load incompatible Linux binary: ${modulePath}`);
      
      // Try to find a compatible binary or use a fallback
      const possiblePaths = [
        modulePath.replace('linux-x64-gnu', 'darwin-arm64'),
        modulePath.replace('linux-x64-gnu', 'darwin-x64'),
        '@tailwindcss/postcss'
      ];
      
      for (const altPath of possiblePaths) {
        try {
          console.log(`Trying alternative: ${altPath}`);
          return originalRequire.apply(this, [altPath]);
        } catch (e) {
          console.log(`Alternative ${altPath} failed: ${e.message}`);
        }
      }
      
      // If all alternatives fail, return an empty object to prevent crashes
      console.log('All alternatives failed, using fallback');
      return {};
    }
  }
  
  // Handle LightningCSS binaries
  if (modulePath && modulePath.includes('lightningcss-linux-x64-gnu') && platform === 'darwin') {
    console.log(`Attempting to load incompatible LightningCSS Linux binary`);
    
    // Try to find a compatible binary or use a fallback
    const possiblePaths = [
      modulePath.replace('linux-x64-gnu', 'darwin-arm64'),
      modulePath.replace('linux-x64-gnu', 'darwin-x64'),
      'lightningcss-wasm'
    ];
    
    for (const altPath of possiblePaths) {
      try {
        console.log(`Trying alternative: ${altPath}`);
        return originalRequire.apply(this, [altPath]);
      } catch (e) {
        console.log(`Alternative ${altPath} failed: ${e.message}`);
      }
    }
    
    // If all alternatives fail, return an empty object to prevent crashes
    console.log('All alternatives failed, using fallback');
    return {};
  }
  
  // Use the original require for all other modules
  return originalRequire.apply(this, args);
};

console.log('Module patch applied for Tailwind CSS and LightningCSS compatibility');
