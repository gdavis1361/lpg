/**
 * Production build configuration for Next.js
 * This file takes precedence over next.config.js when using import/export syntax
 */
import fs from 'fs';
import path from 'path';

// Log that we're using the production config
console.log('Using production Next.js config (next.config.mjs)');

// Import the development config from next.config.js using dynamic import
const devConfigPath = path.join(process.cwd(), 'next.config.js');
const getDevConfig = async () => {
  // We need to use dynamic import for CommonJS modules
  const devConfig = (await import(`file://${devConfigPath}`)).default;
  return devConfig;
};

// Create production config based on dev config but with type checking disabled
const createConfig = async () => {
  const devConfig = await getDevConfig();
  
  // Production config extends development config
  const prodConfig = {
    ...devConfig,
    
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
  };
  
  return prodConfig;
};

// Export the async config function
export default createConfig();
