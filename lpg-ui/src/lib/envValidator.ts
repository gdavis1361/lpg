// src/lib/envValidator.ts
import logger from './logger';

const REQUIRED_ENV_VARS = [
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  // Add other essential frontend env vars here as the project grows
  // e.g., 'NEXT_PUBLIC_API_URL' if it's consistently used and critical
];

/**
 * Check if Doppler is being used to provide environment variables
 */
export function isDopplerActive(): boolean {
  return Boolean(process.env.DOPPLER_PROJECT || process.env.DOPPLER_CONFIG);
}

/**
 * Validates all required environment variables
 * Works with both local .env files and Doppler-injected variables
 */
export function validateEnvVariables(): void {
  const startTime = performance.now();
  logger.info('Validating environment variables...', {
    component: 'environment',
    dopplerActive: isDopplerActive(),
  });
  
  const missingVariables: string[] = [];
  const invalidVariables: {name: string, reason: string}[] = [];

  // Check for required variables
  REQUIRED_ENV_VARS.forEach((varName) => {
    if (!process.env[varName]) {
      missingVariables.push(varName);
    }
  });

  // Validate Supabase URL format
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (supabaseUrl) {
    try {
      new URL(supabaseUrl);
    } catch (e) {
      invalidVariables.push({
        name: 'NEXT_PUBLIC_SUPABASE_URL',
        reason: 'Invalid URL format'
      });
      
      logger.error(
        `Invalid format for NEXT_PUBLIC_SUPABASE_URL. It should be a valid URL.`,
        { 
          component: 'environment',
          variable: 'NEXT_PUBLIC_SUPABASE_URL',
          // Don't log the actual value for security in case it contains sensitive parts
          error: e instanceof Error ? e.message : String(e)
        }
      );
    }
  }

  // Handle missing variables
  if (missingVariables.length > 0) {
    const configSource = isDopplerActive() ? 'Doppler configuration' : '.env.local file';
    const message = `Missing critical environment variables: ${missingVariables.join(', ')}. Please check your ${configSource}.`;
    
    logger.error(message, { 
      component: 'environment',
      missingVariables,
      dopplerActive: isDopplerActive()
    });
    
    // In development, throw an error to halt execution
    if (process.env.NODE_ENV === 'development') {
      throw new Error(message);
    }
  }
  
  // Handle invalid variables
  if (invalidVariables.length > 0) {
    const message = `Found ${invalidVariables.length} invalid environment variables. Check logs for details.`;
    
    logger.error(message, { 
      component: 'environment',
      invalidCount: invalidVariables.length,
      invalidVariables: invalidVariables.map(v => v.name) // Just log the names, not values
    });
    
    // In development, throw an error for invalid variables too
    if (process.env.NODE_ENV === 'development') {
      throw new Error(message);
    }
  }

  // Validate API URL if present
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;
  if (apiUrl) {
    try {
      new URL(apiUrl);
      logger.info('API URL validation successful', { 
        component: 'environment',
        variable: 'NEXT_PUBLIC_API_URL'
        // Don't log the actual URL
      });
    } catch (e) {
      logger.warn(
        'Invalid API URL format. Will fall back to default /api path.',
        { 
          component: 'environment',
          variable: 'NEXT_PUBLIC_API_URL',
          error: e instanceof Error ? e.message : String(e)
        }
      );
    }
  } else {
    logger.info('Using default API path /api', { component: 'environment' });
  }

  // Log validation completion
  const duration = performance.now() - startTime;
  if (missingVariables.length === 0 && invalidVariables.length === 0) {
    logger.info('Environment validation completed successfully', { 
      component: 'environment',
      duration_ms: Math.round(duration),
      dopplerActive: isDopplerActive()
    });
  }
}