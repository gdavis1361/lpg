#!/usr/bin/env node

/**
 * Build Performance Optimization Script
 * 
 * This script analyzes and optimizes Next.js build performance by:
 * 1. Measuring build times for different configurations
 * 2. Implementing incremental TypeScript checking when ready
 * 3. Setting up telemetry for tracking build performance
 * 
 * Usage:
 *   node scripts/optimize-build.js [--analyze] [--profile] [--incremental-ts]
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Configuration
const ENABLE_INCREMENTAL_TS = process.argv.includes('--incremental-ts');
const ENABLE_ANALYSIS = process.argv.includes('--analyze');
const ENABLE_PROFILING = process.argv.includes('--profile');

// Paths
const ROOT_DIR = path.resolve(__dirname, '..');
const NEXT_CONFIG_PATH = path.join(ROOT_DIR, 'next.config.js');
const TSCONFIG_PATH = path.join(ROOT_DIR, 'tsconfig.json');
const BUILD_METRICS_PATH = path.join(ROOT_DIR, '.build-metrics.json');

// Load existing metrics or create new
let buildMetrics = {};
try {
  if (fs.existsSync(BUILD_METRICS_PATH)) {
    buildMetrics = JSON.parse(fs.readFileSync(BUILD_METRICS_PATH, 'utf8'));
  }
} catch (e) {
  console.warn('Could not load existing build metrics, starting fresh');
}

// Capture system info
const systemInfo = {
  platform: os.platform(),
  cpus: os.cpus().length,
  totalMemory: Math.round(os.totalmem() / (1024 * 1024 * 1024)),
  freeMemory: Math.round(os.freemem() / (1024 * 1024 * 1024)),
  nodeVersion: process.version
};

console.log('🚀 Build Optimization Tool');
console.log('==========================');
console.log(`System: ${systemInfo.platform}, ${systemInfo.cpus} CPUs, ${systemInfo.totalMemory}GB RAM (${systemInfo.freeMemory}GB free)`);
console.log(`Node.js: ${systemInfo.nodeVersion}`);
console.log();

// Measure current build performance
function measureBuildTime(buildCommand) {
  console.log(`Running build: ${buildCommand}`);
  console.log('---------------------------');
  
  const startTime = Date.now();
  try {
    // Capture build output but show it in real-time
    execSync(buildCommand, { 
      stdio: 'inherit',
      cwd: ROOT_DIR,
      env: {
        ...process.env,
        // Add any additional env vars needed for the build
        NEXT_TELEMETRY_DISABLED: '1',
        NODE_OPTIONS: process.env.NODE_OPTIONS || ''
      }
    });
    
    const duration = (Date.now() - startTime) / 1000;
    console.log(`\n✅ Build completed in ${duration.toFixed(2)}s`);
    return {
      success: true,
      duration,
      timestamp: new Date().toISOString(),
      command: buildCommand,
      systemInfo
    };
  } catch (error) {
    const duration = (Date.now() - startTime) / 1000;
    console.error(`\n❌ Build failed after ${duration.toFixed(2)}s`);
    console.error(error.message);
    return {
      success: false,
      duration,
      timestamp: new Date().toISOString(),
      command: buildCommand,
      error: error.message,
      systemInfo
    };
  }
}

// Enable incremental TypeScript if requested
function setupIncrementalTypeScript() {
  if (!ENABLE_INCREMENTAL_TS) {
    return false;
  }
  
  console.log('Setting up incremental TypeScript checking...');
  
  try {
    // Read tsconfig.json
    const tsConfig = JSON.parse(fs.readFileSync(TSCONFIG_PATH, 'utf8'));
    
    // Update for incremental builds
    tsConfig.compilerOptions = {
      ...tsConfig.compilerOptions,
      incremental: true,
      tsBuildInfoFile: ".tsbuildinfo"
    };
    
    // Write updated config
    fs.writeFileSync(TSCONFIG_PATH, JSON.stringify(tsConfig, null, 2));
    console.log('✅ Updated tsconfig.json for incremental builds');
    
    return true;
  } catch (error) {
    console.error('❌ Failed to set up incremental TypeScript:');
    console.error(error);
    return false;
  }
}

// Setup build analysis if requested
function setupBuildAnalysis() {
  if (!ENABLE_ANALYSIS) {
    return false;
  }
  
  console.log('Setting up build analysis...');
  
  try {
    // Read next.config.js
    let nextConfigContent = fs.readFileSync(NEXT_CONFIG_PATH, 'utf8');
    
    // Check if @next/bundle-analyzer is already configured
    if (nextConfigContent.includes('@next/bundle-analyzer')) {
      console.log('⚠️ Bundle analyzer already configured');
      return true;
    }
    
    // Add bundle analyzer
    const analyzerConfig = `
// Bundle Analyzer
const withBundleAnalyzer = process.env.ANALYZE === 'true'
  ? require('@next/bundle-analyzer')({
      enabled: true,
    })
  : (config) => config;
`;
    
    // Update the config to use the analyzer
    if (nextConfigContent.includes('module.exports')) {
      // For CommonJS format
      nextConfigContent = nextConfigContent.replace(
        'module.exports =',
        `${analyzerConfig}\nmodule.exports =`
      );
      nextConfigContent = nextConfigContent.replace(
        'module.exports =', 
        'module.exports = withBundleAnalyzer('
      );
      
      // Find the end of the config object and add closing parenthesis
      const lastBrace = nextConfigContent.lastIndexOf('}');
      if (lastBrace !== -1) {
        nextConfigContent = 
          nextConfigContent.substring(0, lastBrace + 1) + 
          ')' + 
          nextConfigContent.substring(lastBrace + 1);
      }
    }
    
    // Write updated config
    fs.writeFileSync(NEXT_CONFIG_PATH, nextConfigContent);
    console.log('✅ Added bundle analyzer to next.config.js');
    
    // Check if @next/bundle-analyzer is installed
    try {
      require.resolve('@next/bundle-analyzer');
    } catch (e) {
      console.log('⚠️ @next/bundle-analyzer not installed. Installing...');
      execSync('npm install --save-dev @next/bundle-analyzer', {
        stdio: 'inherit',
        cwd: ROOT_DIR
      });
    }
    
    return true;
  } catch (error) {
    console.error('❌ Failed to set up build analysis:');
    console.error(error);
    return false;
  }
}

// Main execution
async function main() {
  // Measure baseline build
  console.log('📊 Measuring current build performance...');
  const baselineResult = measureBuildTime('npm run build');
  
  // Save metrics
  const metricId = `build-${Date.now()}`;
  buildMetrics[metricId] = baselineResult;
  fs.writeFileSync(BUILD_METRICS_PATH, JSON.stringify(buildMetrics, null, 2));
  console.log(`📝 Saved build metrics to ${BUILD_METRICS_PATH}`);
  
  // Implement performance enhancements
  let enhancementsMade = false;
  
  if (ENABLE_INCREMENTAL_TS) {
    const tsSuccess = setupIncrementalTypeScript();
    enhancementsMade = enhancementsMade || tsSuccess;
  }
  
  if (ENABLE_ANALYSIS) {
    const analysisSuccess = setupBuildAnalysis();
    enhancementsMade = enhancementsMade || analysisSuccess;
  }
  
  if (enhancementsMade) {
    console.log('\n🔄 Measuring build with enhancements...');
    const enhancedResult = measureBuildTime('npm run build');
    
    // Save enhanced metrics
    const enhancedMetricId = `build-enhanced-${Date.now()}`;
    buildMetrics[enhancedMetricId] = enhancedResult;
    fs.writeFileSync(BUILD_METRICS_PATH, JSON.stringify(buildMetrics, null, 2));
    
    // Calculate improvement
    if (baselineResult.success && enhancedResult.success) {
      const improvement = (baselineResult.duration - enhancedResult.duration) / baselineResult.duration * 100;
      console.log(`\n📈 Performance change: ${improvement.toFixed(2)}%`);
      console.log(`   Before: ${baselineResult.duration.toFixed(2)}s`);
      console.log(`   After:  ${enhancedResult.duration.toFixed(2)}s`);
    }
  }
  
  // Recommendations
  console.log('\n📋 Recommendations:');
  
  if (!ENABLE_INCREMENTAL_TS) {
    console.log('- Enable incremental TypeScript with --incremental-ts flag once TypeScript checking is restored');
  }
  
  if (!ENABLE_ANALYSIS) {
    console.log('- Run with --analyze flag to identify large dependencies');
  }
  
  if (!ENABLE_PROFILING) {
    console.log('- Run with --profile flag to identify slow build phases');
  }
  
  console.log('\n✨ Optimization complete!');
}

main().catch(error => {
  console.error('❌ Error during optimization:');
  console.error(error);
  process.exit(1);
});
