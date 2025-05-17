// Debugging helper for Next.js configuration
// This will help us understand what's happening during build

const fs = require('fs');
const path = require('path');

function debugLog(message) {
  const logPath = path.join(process.cwd(), 'debug-build.log');
  fs.appendFileSync(logPath, `${new Date().toISOString()}: ${message}\n`);
}

// Check if native modules exist
function checkNativeModules() {
  try {
    const lightningcssPath = require.resolve('lightningcss/node/index.js');
    debugLog(`Lightning CSS path: ${lightningcssPath}`);
    
    // List files in the directory
    const dir = path.dirname(lightningcssPath);
    const files = fs.readdirSync(dir);
    debugLog(`Files in Lightning CSS dir: ${JSON.stringify(files)}`);
    
    // Check for specific native module
    const nativeModulePath = path.join(dir, '../lightningcss.linux-x64-gnu.node');
    const exists = fs.existsSync(nativeModulePath);
    debugLog(`Native module exists: ${exists}`);
  } catch (error) {
    debugLog(`Error checking modules: ${error.message}`);
  }
}

// Check if WASM module is available
function checkWasmModule() {
  try {
    const wasmPath = require.resolve('lightningcss-wasm');
    debugLog(`Lightning CSS WASM path: ${wasmPath}`);
    return true;
  } catch (error) {
    debugLog(`Error loading WASM module: ${error.message}`);
    return false;
  }
}

// Export the debug utility
module.exports = {
  debugLog,
  checkNativeModules,
  checkWasmModule
};
