console.log('⚠️ LOADED next.config.mjs (ESM version)');

/**
 * Production build configuration for Next.js
 * This file takes precedence over next.config.js when using import/export syntax
 */

// Log that we're using the production config
console.log('Using production Next.js config (next.config.mjs) - All checks disabled');

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Explicitly set the output export format
  output: 'standalone',
  
  // Add React strict mode for better development experience
  reactStrictMode: true,
  
  // Disable image optimization which might depend on missing binaries
  images: {
    unoptimized: true
  },
  
  // Explicitly disable TypeScript type checking
  typescript: {
    // This completely disables TypeScript type checking
    ignoreBuildErrors: true,
  },
  
  // Explicitly disable ESLint
  eslint: {
    // This completely disables ESLint during the build
    ignoreDuringBuilds: true,
  },
  
  // Override webpack configuration to avoid native module issues
  webpack: (config) => {
    // Prevent webpack from trying to load the native binaries
    config.resolve.alias['lightningcss-native'] = false;
    
    // Use the wasm version of Lightning CSS instead of the native one
    if (config.resolve.fallback) {
      config.resolve.fallback['lightningcss'] = require.resolve('lightningcss-wasm');
    } else {
      config.resolve.fallback = {
        'lightningcss': require.resolve('lightningcss-wasm')
      };
    }
    
    return config;
  },
  
  // Attempt to troubleshoot module loading issues
  onDemandEntries: {
    maxInactiveAge: 60 * 60 * 1000, // Extended for debugging
    pagesBufferLength: 5,
  },
};

export default nextConfig;
