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
  // Disable type checking and linting during build
  typescript: {
    ignoreBuildErrors: true
  },
  eslint: {
    ignoreDuringBuilds: true
  },
  // Override webpack configuration to avoid native module issues
  webpack: (config) => {
    // Prevent webpack from trying to load the native binaries
    config.resolve.alias['lightningcss-native'] = false;
    
    // Use the wasm version of Lightning CSS instead of the native one
    if (!config.resolve.fallback) {
      config.resolve.fallback = {};
    }
    
    config.resolve.fallback['lightningcss'] = require.resolve('lightningcss-wasm');
    
    return config;
  }
};

module.exports = nextConfig;
