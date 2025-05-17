#!/usr/bin/env node

/**
 * Deployment Monitoring Script
 * 
 * This script provides monitoring for Vercel deployments and build health:
 * 1. Tracks deployment success rates
 * 2. Monitors build times and performance trends
 * 3. Checks for runtime issues in production
 * 4. Sends alerts on critical failures
 * 
 * Usage:
 *   node scripts/deployment-monitor.js [--check] [--verbose]
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const VERBOSE = process.argv.includes('--verbose');
const CHECK_ONLY = process.argv.includes('--check');
const PROJECT_NAME = 'lpg-ui';
const ROOT_DIR = path.resolve(__dirname, '..');
const METRICS_FILE = path.join(ROOT_DIR, '.deployment-metrics.json');
const PRODUCTION_URL = process.env.VERCEL_PRODUCTION_URL || 'lpg-ui.vercel.app';
const GITHUB_REPO = 'gdavis1361/lpg';

// Helper for colorized output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

// Load existing metrics or initialize
function loadMetrics() {
  try {
    if (fs.existsSync(METRICS_FILE)) {
      return JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
    }
  } catch (e) {
    console.warn(`Could not load metrics file: ${e.message}`);
  }
  
  return {
    deployments: [],
    checkResults: [],
    lastUpdated: new Date().toISOString()
  };
}

// Save metrics to file
function saveMetrics(metrics) {
  metrics.lastUpdated = new Date().toISOString();
  fs.writeFileSync(METRICS_FILE, JSON.stringify(metrics, null, 2));
  if (VERBOSE) {
    console.log(`${colors.green}✓ Metrics saved to ${METRICS_FILE}${colors.reset}`);
  }
}

// Get latest git commit
function getLatestCommit() {
  try {
    const gitOutput = execSync('git log -1 --format="%h %s"', { cwd: ROOT_DIR }).toString().trim();
    const [hash, ...messageParts] = gitOutput.split(' ');
    const message = messageParts.join(' ');
    
    return { hash, message };
  } catch (e) {
    console.warn(`${colors.yellow}⚠ Could not get latest commit: ${e.message}${colors.reset}`);
    return { hash: 'unknown', message: 'unknown' };
  }
}

// Check if Vercel deployment exists and is healthy
function checkVercelDeployment(callback) {
  const url = `https://${PRODUCTION_URL}`;
  
  console.log(`${colors.blue}Checking production deployment at ${url}${colors.reset}`);
  
  https.get(url, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      const statusCode = res.statusCode;
      const isHealthy = statusCode >= 200 && statusCode < 400;
      
      const result = {
        url,
        statusCode,
        isHealthy,
        timestamp: new Date().toISOString(),
        responseTime: 0, // We're not measuring this accurately yet
        checkType: 'http'
      };
      
      if (isHealthy) {
        console.log(`${colors.green}✓ Deployment is healthy (${statusCode})${colors.reset}`);
      } else {
        console.log(`${colors.red}✗ Deployment check failed (${statusCode})${colors.reset}`);
      }
      
      callback(result);
    });
  }).on('error', (err) => {
    console.log(`${colors.red}✗ Error checking deployment: ${err.message}${colors.reset}`);
    
    const result = {
      url,
      statusCode: 0,
      isHealthy: false,
      timestamp: new Date().toISOString(),
      error: err.message,
      checkType: 'http'
    };
    
    callback(result);
  });
}

// Check for common runtime issues
function checkForRuntimeIssues(callback) {
  const url = `https://${PRODUCTION_URL}`;
  
  console.log(`${colors.blue}Checking for runtime issues...${colors.reset}`);
  
  // Simple Playwright-like check using plain Node.js
  const req = https.request(url, {
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 LPG-UI Deployment Monitor'
    }
  }, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      const issues = [];
      
      // Check for common error patterns in HTML
      if (data.includes('Internal Server Error') || data.includes('500')) {
        issues.push('Possible 500 error detected in HTML');
      }
      
      if (data.includes('TypeError:') || data.includes('ReferenceError:')) {
        issues.push('JavaScript error detected in HTML');
      }
      
      if (data.includes('Failed to load resource')) {
        issues.push('Resource loading error detected');
      }
      
      // Look for missing Next.js chunks
      if (data.includes('chunks') && !data.includes('/_next/static/chunks')) {
        issues.push('Possible missing Next.js chunks');
      }
      
      const result = {
        url,
        timestamp: new Date().toISOString(),
        issues,
        hasIssues: issues.length > 0,
        checkType: 'runtime'
      };
      
      if (issues.length === 0) {
        console.log(`${colors.green}✓ No obvious runtime issues detected${colors.reset}`);
      } else {
        console.log(`${colors.red}✗ Runtime issues detected:${colors.reset}`);
        issues.forEach(issue => console.log(`  - ${issue}`));
      }
      
      callback(result);
    });
  });
  
  req.on('error', (err) => {
    console.log(`${colors.red}✗ Error checking for runtime issues: ${err.message}${colors.reset}`);
    
    const result = {
      url,
      timestamp: new Date().toISOString(),
      issues: [err.message],
      hasIssues: true,
      error: err.message,
      checkType: 'runtime'
    };
    
    callback(result);
  });
  
  req.end();
}

// Track a new deployment
function trackDeployment() {
  const metrics = loadMetrics();
  const commit = getLatestCommit();
  
  const deployment = {
    project: PROJECT_NAME,
    environment: 'production',
    timestamp: new Date().toISOString(),
    commit,
    url: `https://${PRODUCTION_URL}`,
    github: `https://github.com/${GITHUB_REPO}/commit/${commit.hash}`
  };
  
  metrics.deployments.unshift(deployment);
  
  // Keep only the last 20 deployments
  if (metrics.deployments.length > 20) {
    metrics.deployments = metrics.deployments.slice(0, 20);
  }
  
  saveMetrics(metrics);
  
  console.log(`${colors.green}✓ Tracked deployment of ${commit.hash}: ${commit.message}${colors.reset}`);
}

// Check deployment health
function checkDeploymentHealth() {
  const metrics = loadMetrics();
  
  checkVercelDeployment((deploymentResult) => {
    checkForRuntimeIssues((runtimeResult) => {
      // Add results to metrics
      metrics.checkResults.unshift(deploymentResult);
      metrics.checkResults.unshift(runtimeResult);
      
      // Keep only the last 100 check results
      if (metrics.checkResults.length > 100) {
        metrics.checkResults = metrics.checkResults.slice(0, 100);
      }
      
      saveMetrics(metrics);
      
      // Generate a summary
      generateHealthSummary(metrics);
    });
  });
}

// Generate a health summary
function generateHealthSummary(metrics) {
  console.log(`\n${colors.blue}Deployment Health Summary${colors.reset}`);
  console.log(`${colors.blue}==========================${colors.reset}`);
  
  // Count recent issues
  const recentChecks = metrics.checkResults.slice(0, 10);
  const failedChecks = recentChecks.filter(check => 
    (check.isHealthy === false) || (check.hasIssues === true)
  );
  
  // Latest deployment
  const latestDeployment = metrics.deployments[0];
  if (latestDeployment) {
    console.log(`\nLatest deployment: ${latestDeployment.timestamp}`);
    console.log(`Commit: ${latestDeployment.commit.hash} - ${latestDeployment.commit.message}`);
    console.log(`URL: ${latestDeployment.url}`);
  }
  
  // Health status
  if (failedChecks.length === 0) {
    console.log(`\n${colors.green}✓ All recent checks passed${colors.reset}`);
  } else {
    console.log(`\n${colors.red}✗ ${failedChecks.length} of ${recentChecks.length} recent checks failed${colors.reset}`);
    
    // Show the latest failure
    const latestFailure = failedChecks[0];
    console.log(`\nLatest failure (${latestFailure.timestamp}):`);
    
    if (latestFailure.statusCode) {
      console.log(`Status Code: ${latestFailure.statusCode}`);
    }
    
    if (latestFailure.issues && latestFailure.issues.length > 0) {
      console.log('Issues:');
      latestFailure.issues.forEach(issue => console.log(`  - ${issue}`));
    }
    
    if (latestFailure.error) {
      console.log(`Error: ${latestFailure.error}`);
    }
  }
  
  // Deployment success trend
  const successRate = ((recentChecks.length - failedChecks.length) / recentChecks.length) * 100;
  console.log(`\nSuccess rate: ${successRate.toFixed(1)}%`);
  
  // Recommendations
  console.log(`\n${colors.blue}Recommendations:${colors.reset}`);
  
  if (failedChecks.length > 0) {
    console.log(`${colors.yellow}⚠ Investigate recent failures${colors.reset}`);
    console.log(`${colors.yellow}⚠ Check Vercel logs for errors${colors.reset}`);
    console.log(`${colors.yellow}⚠ Verify environment variables in Vercel and Doppler${colors.reset}`);
  } else {
    console.log(`${colors.green}✓ Deployment looks healthy${colors.reset}`);
    console.log(`${colors.green}✓ Continue monitoring for any changes${colors.reset}`);
  }
  
  console.log(`\nUse the following commands for further investigation:`);
  console.log(`  npx vercel logs ${PROJECT_NAME} --prod`);
  console.log(`  node scripts/env-monitor.js --check-doppler`);
}

// Main function
function main() {
  console.log(`${colors.cyan}Deployment Monitor${colors.reset}`);
  console.log(`${colors.cyan}==================${colors.reset}\n`);
  
  if (CHECK_ONLY) {
    console.log(`Running health check only (not tracking a new deployment)`);
    checkDeploymentHealth();
  } else {
    console.log(`Tracking new deployment and running health check`);
    trackDeployment();
    checkDeploymentHealth();
  }
}

// Run the script
main();
