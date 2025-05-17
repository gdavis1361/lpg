/** @type {import('next').NextConfig} */
const fs = require('fs');
const path = require('path');
const debug = require('./debug-config');

// Clear any previous log file
const logPath = path.join(process.cwd(), 'debug-build.log');
if (fs.existsSync(logPath)) {
  fs.unlinkSync(logPath);
}

debug.debugLog('Starting Next.js configuration');
debug.checkNativeModules();
const wasmAvailable = debug.checkWasmModule();
debug.debugLog(`WASM module available: ${wasmAvailable}`);

// Create a custom CSS loader that uses WASM instead of native modules
const createCustomLoader = (config) => {
  debug.debugLog('Creating custom CSS loader');
  // First check if we already have the PostCSS loader defined
  const cssRules = config.module.rules.find(rule => rule.test && rule.test.toString().includes('css'));
  if (!cssRules) {
    debug.debugLog('No CSS rules found in webpack config');
    return config;
  }
  
  // Log what we found
  debug.debugLog(`Found CSS rules: ${cssRules.oneOf.length} oneOf rules`);
  return config;
};

const nextConfig = {
  // Explicitly set the output export format
  output: 'standalone',
  // Add React strict mode for better development experience
  reactStrictMode: true,
  // Disable image optimization which might depend on missing binaries
  images: {
    unoptimized: true
  },
  // Override webpack configuration to avoid native module issues
  webpack: (config, { isServer, dev }) => {
    debug.debugLog(`Webpack config phase: isServer=${isServer}, dev=${dev}`);
    
    // Prevent webpack from trying to load the native binaries
    config.resolve.alias['lightningcss-native'] = false;
    debug.debugLog('Set lightningcss-native alias to false');
    
    // Add a resolve hook to catch any attempts to load the native module
    if (!config.resolve.plugins) {
      config.resolve.plugins = [];
    }
    
    // Use the wasm version of Lightning CSS instead of the native one
    if (config.resolve.fallback) {
      config.resolve.fallback['lightningcss'] = require.resolve('lightningcss-wasm');
      debug.debugLog(`Added lightningcss fallback to: ${require.resolve('lightningcss-wasm')}`);
    } else {
      config.resolve.fallback = {
        'lightningcss': require.resolve('lightningcss-wasm')
      };
      debug.debugLog('Created new fallback config for lightningcss');
    }
    
    // Try custom CSS loader approach
    config = createCustomLoader(config);
    
    debug.debugLog('Webpack config transformation complete');
    return config;
  },
  onDemandEntries: {
    // Attempt to troubleshoot module loading issues
    maxInactiveAge: 60 * 60 * 1000, // Extended for debugging
    pagesBufferLength: 5,
  },
};

module.exports = nextConfig;
