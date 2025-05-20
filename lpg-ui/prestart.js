// This script runs before Next.js to patch modules and prepare the environment
console.log('Running prestart configuration for Vercel compatibility');

// Set up diagnostics for the build process
const fs = require('fs');
const path = require('path');
const logDir = path.join(process.cwd(), 'logs');

// Create logs directory if it doesn't exist
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const logFile = path.join(logDir, 'build-diagnostics.log');
fs.writeFileSync(logFile, `Build started at ${new Date().toISOString()}\n`);

function log(message) {
  const entry = `${new Date().toISOString()}: ${message}\n`;
  console.log(entry.trim());
  fs.appendFileSync(logFile, entry);
}

log('Environment information:');
log(`Node.js version: ${process.version}`);
log(`Platform: ${process.platform}`);
log(`Architecture: ${process.arch}`);
log(`Working directory: ${process.cwd()}`);

// Tailwind version validation
try {
  log('Validating Tailwind CSS configuration:');
  
  // Check actual installed version
  const tailwindPkgPath = path.join(process.cwd(), 'node_modules/tailwindcss/package.json');
  if (fs.existsSync(tailwindPkgPath)) {
    const tailwindPkg = require(tailwindPkgPath);
    log(`Installed Tailwind CSS version: ${tailwindPkg.version}`);
  } else {
    log('Tailwind CSS package.json not found');
  }
  
  // Check for v4 postcss configuration
  const postcssConfigPath = path.join(process.cwd(), 'postcss.config.js');
  if (fs.existsSync(postcssConfigPath)) {
    const postcssConfig = fs.readFileSync(postcssConfigPath, 'utf8');
    log(`PostCSS uses @tailwindcss/postcss (v4): ${postcssConfig.includes('@tailwindcss/postcss')}`);
  }
  
  // Check CSS syntax
  const globalsPath = path.join(process.cwd(), 'src/app/globals.css');
  if (fs.existsSync(globalsPath)) {
    const globalsCSS = fs.readFileSync(globalsPath, 'utf8');
    log(`CSS uses v4 @theme directive: ${globalsCSS.includes('@theme inline')}`);
    log(`CSS uses standard import syntax: ${globalsCSS.includes('@import "tailwindcss"')}`);
  }
  
  // Check tailwind config
  const tailwindConfigPath = path.join(process.cwd(), 'tailwind.config.ts');
  if (fs.existsSync(tailwindConfigPath)) {
    const tailwindConfig = fs.readFileSync(tailwindConfigPath, 'utf8');
    log(`Config imports animatePlugin (common pattern): ${tailwindConfig.includes('animatePlugin')}`);
  }
} catch (err) {
  log(`Error validating Tailwind: ${err.message}`);
}

// Check if we're running in Vercel
const isVercel = !!process.env.VERCEL;
log(`Running in Vercel: ${isVercel}`);

// List all environment variables (excluding secrets)
log('Environment variables:');
Object.keys(process.env)
  .filter(key => !key.includes('TOKEN') && !key.includes('SECRET') && !key.includes('KEY'))
  .forEach(key => {
    log(`  ${key}: ${process.env[key]}`);
  });

// Check for the existence of key packages
try {
  log('Checking for installed packages:');
  
  // Check for Tailwind
  try {
    const tailwindPath = require.resolve('tailwindcss');
    const tailwindPackage = require('tailwindcss/package.json');
    log(`Tailwind CSS found at ${tailwindPath}, version ${tailwindPackage.version}`);
  } catch (err) {
    log(`Tailwind CSS not found: ${err.message}`);
  }
  
  // Check for Lightning CSS
  try {
    const lightningPath = require.resolve('lightningcss');
    log(`Lightning CSS found at ${lightningPath}`);
    
    // Check for native modules
    const lightningDir = path.dirname(lightningPath);
    const nodeDir = path.join(lightningDir, 'node');
    
    if (fs.existsSync(nodeDir)) {
      log(`Lightning CSS node directory exists at ${nodeDir}`);
      const nodeFiles = fs.readdirSync(nodeDir);
      log(`Files in node directory: ${JSON.stringify(nodeFiles)}`);
      
      // Look for platform-specific binaries
      const parentDir = path.dirname(lightningDir);
      const parentFiles = fs.readdirSync(parentDir);
      log(`Files in parent directory: ${JSON.stringify(parentFiles)}`);
      
      // Check for specific .node files
      const nativeModules = parentFiles.filter(f => f.endsWith('.node'));
      if (nativeModules.length > 0) {
        log(`Found native modules: ${nativeModules.join(', ')}`);
      } else {
        log('No native modules found');
      }
    } else {
      log(`Lightning CSS node directory does not exist`);
    }
  } catch (err) {
    log(`Lightning CSS not found: ${err.message}`);
  }
  
  // Check for Lightning CSS WASM
  try {
    const wasmPath = require.resolve('lightningcss-wasm');
    log(`Lightning CSS WASM found at ${wasmPath}`);
  } catch (err) {
    log(`Lightning CSS WASM not found: ${err.message}`);
  }
  
  // Examine Next.js font modules
  try {
    const nextFontPath = require.resolve('next/font/google');
    log(`Next.js font module found at ${nextFontPath}`);
    
    // Check related modules
    const fontDir = path.dirname(nextFontPath);
    const fontFiles = fs.readdirSync(fontDir);
    log(`Files in font directory: ${JSON.stringify(fontFiles)}`);
  } catch (err) {
    log(`Next.js font module check failed: ${err.message}`);
  }

} catch (err) {
  log(`Error during package checks: ${err.message}`);
  log(err.stack);
}

// Export the log function for use in other modules
module.exports = { log };

log('Prestart configuration complete');
