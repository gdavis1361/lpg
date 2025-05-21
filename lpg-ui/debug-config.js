// Debugging helper for Next.js configuration
// This will help us understand what's happening during build

const fs = require('fs');
const path = require('path');
const os = require('os');

function debugLog(message) {
  const logPath = path.join(process.cwd(), 'debug-build.log');
  fs.appendFileSync(logPath, `${new Date().toISOString()}: ${message}\n`);
}

// Debug utility for checking native module compatibility
function checkNativeModules() {
  const platform = os.platform();
  const arch = os.arch();
  console.log(`Checking native modules for platform: ${platform}, architecture: ${arch}`);
  
  // Define paths to check
  const tailwindPaths = [
    path.join(process.cwd(), 'node_modules/@tailwindcss/oxide-darwin-arm64'),
    path.join(process.cwd(), 'node_modules/@tailwindcss/oxide-darwin-x64'),
    path.join(process.cwd(), 'node_modules/@tailwindcss/oxide-linux-x64-gnu'),
    path.join(process.cwd(), 'node_modules/@tailwindcss/postcss')
  ];
  
  const lightningPaths = [
    path.join(process.cwd(), 'node_modules/lightningcss-darwin-arm64'),
    path.join(process.cwd(), 'node_modules/lightningcss-darwin-x64'),
    path.join(process.cwd(), 'node_modules/lightningcss-linux-x64-gnu'),
    path.join(process.cwd(), 'node_modules/lightningcss-wasm')
  ];
  
  // Check Tailwind modules
  console.log('\nTailwind CSS modules:');
  tailwindPaths.forEach(checkPath);
  
  // Check Lightning CSS modules
  console.log('\nLightning CSS modules:');
  lightningPaths.forEach(checkPath);
  
  // Check for the ideal configuration on this platform
  console.log('\nRecommended configuration:');
  if (platform === 'darwin') {
    const archSuffix = arch === 'arm64' ? 'arm64' : 'x64';
    console.log(`Your platform should use: @tailwindcss/oxide-darwin-${archSuffix}`);
    console.log(`Your platform should use: lightningcss-darwin-${archSuffix}`);
    
    // Check if we have the right modules
    const hasTailwind = fs.existsSync(path.join(process.cwd(), `node_modules/@tailwindcss/oxide-darwin-${archSuffix}`));
    const hasLightning = fs.existsSync(path.join(process.cwd(), `node_modules/lightningcss-darwin-${archSuffix}`));
    
    if (!hasTailwind || !hasLightning) {
      console.log('\nMissing recommended modules. You may need to reinstall with:');
      console.log('npm install --platform=darwin --arch=' + arch);
    } else {
      console.log('\nYou have the correct architecture-specific modules installed!');
    }
  }
}

function checkPath(modulePath) {
  if (fs.existsSync(modulePath)) {
    console.log(`✅ Found: ${path.basename(modulePath)}`);
    // Check if it contains .node files
    try {
      const files = fs.readdirSync(modulePath);
      const nodeFiles = files.filter(f => f.endsWith('.node'));
      if (nodeFiles.length > 0) {
        console.log(`   Contains native modules: ${nodeFiles.join(', ')}`);
      }
    } catch (e) {
      console.log(`   Error reading directory: ${e.message}`);
    }
  } else {
    console.log(`❌ Missing: ${path.basename(modulePath)}`);
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

// If run directly
if (require.main === module) {
  checkNativeModules();
}
