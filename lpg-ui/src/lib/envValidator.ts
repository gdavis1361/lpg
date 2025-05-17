// src/lib/envValidator.ts
import logger from './logger';

const REQUIRED_ENV_VARS = [
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  // Add other essential frontend env vars here as the project grows
  // e.g., 'NEXT_PUBLIC_API_URL' if it's consistently used and critical
];

export function validateEnvVariables(): void {
  logger.info('Validating environment variables...');
  const missingVariables: string[] = [];

  REQUIRED_ENV_VARS.forEach((varName) => {
    if (!process.env[varName]) {
      missingVariables.push(varName);
    }
  });

  // Example of a more specific validation (e.g., for URL format)
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (supabaseUrl) {
    try {
      new URL(supabaseUrl);
    } catch (e) {
      logger.error(
        `Invalid format for NEXT_PUBLIC_SUPABASE_URL: ${supabaseUrl}. It should be a valid URL.`,
        { variable: 'NEXT_PUBLIC_SUPABASE_URL', value: supabaseUrl },
        e instanceof Error ? e : new Error(String(e))
      );
      // Depending on severity, you might want to throw an error here
      // or add to a list of invalid (not just missing) variables.
    }
  }

  if (missingVariables.length > 0) {
    const message = `Missing critical environment variables: ${missingVariables.join(', ')}. Please check your .env.local or environment configuration.`;
    logger.error(message, { missingVariables });
    // In a development environment, it's useful to throw an error to halt execution.
    // In production, you might handle this more gracefully, e.g., show a maintenance page.
    if (process.env.NODE_ENV === 'development') {
      throw new Error(message);
    }
  } else {
    logger.info('Environment variables validation passed.');
  }

  // Validate NEXT_PUBLIC_API_URL if it's defined, as it's used in apiClient
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;
  if (apiUrl) {
    try {
      new URL(apiUrl);
      logger.info('NEXT_PUBLIC_API_URL is valid.', { apiUrl });
    } catch (e) {
      const message = `Invalid format for NEXT_PUBLIC_API_URL: ${apiUrl}. It should be a valid URL. Falling back to '/api' if not set, but this explicit value is invalid.`;
      logger.warn(
        message,
        { variable: 'NEXT_PUBLIC_API_URL', value: apiUrl },
        e instanceof Error ? e : new Error(String(e))
      );
      // Not throwing an error here as apiClient has a fallback, but it's a warning.
    }
  } else {
    logger.info('NEXT_PUBLIC_API_URL is not set. apiClient will use default fallback /api.');
  }
}