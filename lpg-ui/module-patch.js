// Module patching for Tailwind CSS and Lightning CSS in Vercel environment
const fs = require('fs');
const path = require('path');
const Module = require('module');

// Log file for diagnostics
const logFile = path.join(process.cwd(), 'module-patch.log');
fs.writeFileSync(logFile, `Module patching started at ${new Date().toISOString()}\n`);

// Log critical environment information
const envInfo = {
  platform: process.platform,
  arch: process.arch, 
  nodeVersion: process.version,
  nodePath: process.execPath,
  npmVersion: process.env.npm_config_user_agent,
  vercelEnv: process.env.VERCEL_ENV || 'not-vercel'
};
fs.appendFileSync(logFile, `Environment: ${JSON.stringify(envInfo, null, 2)}\n`);
fs.appendFileSync(logFile, `NODE_OPTIONS: ${process.env.NODE_OPTIONS || 'not set'}\n`);

function log(message) {
  fs.appendFileSync(logFile, `${new Date().toISOString()}: ${message}\n`);
}

// Store the original Module._load function
const originalLoad = Module._load;

// Create a patched version that intercepts Lightning CSS native module loads
Module._load = function(request, parent, isMain) {
  if (request.includes('lightningcss') && request.includes('.node')) {
    log(`Intercepted native module load: ${request}`);
    log(`Parent module: ${parent ? parent.filename : 'unknown'}`);
    
    // Try to load the WASM version instead
    try {
      log('Attempting to load WASM version instead');
      const wasmPath = require.resolve('lightningcss-wasm');
      log(`WASM module located at: ${wasmPath}`);
      return originalLoad(wasmPath, parent, isMain);
    } catch (err) {
      log(`Failed to load WASM version: ${err.message}`);
      // Continue to original behavior if WASM fails
    }
  }
  
  // For Lightning CSS main module, check what it's trying to do
  if (request === 'lightningcss' || request === 'lightningcss/node') {
    log(`Lightningcss module requested: ${request}`);
    log(`Parent module: ${parent ? parent.filename : 'unknown'}`);
    
    // Try to see what's in the module's directory
    try {
      const resolvedPath = require.resolve(request);
      log(`Resolved to: ${resolvedPath}`);
      
      const dir = path.dirname(resolvedPath);
      const files = fs.readdirSync(dir);
      log(`Files in directory: ${JSON.stringify(files)}`);
    } catch (err) {
      log(`Error examining lightningcss: ${err.message}`);
    }
  }
  
  // Continue with the original loading behavior
  return originalLoad(request, parent, isMain);
};

// Apply patches for specific platform modules
try {
  // Create a shim for the missing native module
  const shimNativeModule = () => {
    log('Creating shim for native module');
    
    // Target paths that might be accessed
    const potentialPaths = [
      path.join(process.cwd(), 'node_modules/lightningcss/lightningcss.linux-x64-gnu.node'),
      path.join(process.cwd(), 'node_modules/lightningcss/node/lightningcss.linux-x64-gnu.node'),
      // Add other potential paths here
    ];
    
    // Check if WASM is available
    let wasmExports = null;
    try {
      // Attempt to load the WASM module and get its exports
      const wasmModule = require('lightningcss-wasm');
      wasmExports = wasmModule;
      log('Successfully loaded WASM module');
    } catch (err) {
      log(`Failed to load WASM module: ${err.message}`);
    }
    
    // Create directories if needed
    potentialPaths.forEach(p => {
      const dir = path.dirname(p);
      if (!fs.existsSync(dir)) {
        try {
          fs.mkdirSync(dir, { recursive: true });
          log(`Created directory: ${dir}`);
        } catch (err) {
          log(`Failed to create directory ${dir}: ${err.message}`);
        }
      }
    });
    
    return wasmExports;
  };
  
  // Execute the shim creation
  const shimResult = shimNativeModule();
  log(`Shim created with result: ${shimResult ? 'success' : 'failure'}`);
  
} catch (err) {
  log(`Error in module patching: ${err.message}`);
  log(err.stack);
}

// Export the module for Next.js to use
module.exports = {
  patchApplied: true,
  log
};
