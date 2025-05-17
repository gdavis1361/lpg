// src/lib/logger.ts

// Define log levels and their priorities
type LogLevel = 'debug' | 'info' | 'warn' | 'error';
const LOG_LEVEL_PRIORITY: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3
};

// Customizable through environment variables
const DEFAULT_LOG_LEVEL = 'info';
const DEFAULT_LOG_FORMAT = 'console';

// Fields that should be redacted for privacy
const SENSITIVE_FIELDS = [
  'email', 'mail', // Email addresses
  'phone', 'phoneNumber', 'mobile', // Phone numbers
  'password', 'pass', 'secret', // Passwords and secrets
  'token', 'authorization', 'auth', 'jwt', // Authentication
  'firstName', 'lastName', 'fullName', // Names
  'address', 'street', 'city', 'zip', 'postal', // Address information
  'ssn', 'socialSecurity', 'tax', // Government IDs
  'creditCard', 'cc', 'cvv', // Payment information
  'dob', 'birthDate', 'birthDay' // Date of birth
];

/**
 * Get the configured log level from environment variables
 * Supports both Doppler and local environment variables
 */
function getConfiguredLogLevel(): LogLevel {
  const envLogLevel = (process.env.LOG_LEVEL || DEFAULT_LOG_LEVEL).toLowerCase();
  if (envLogLevel === 'debug' || envLogLevel === 'info' || 
      envLogLevel === 'warn' || envLogLevel === 'error') {
    return envLogLevel;
  }
  return DEFAULT_LOG_LEVEL as LogLevel;
}

/**
 * Get the configured log format from environment variables
 */
function getConfiguredLogFormat(): 'json' | 'console' {
  const envLogFormat = (process.env.LOG_FORMAT || DEFAULT_LOG_FORMAT).toLowerCase();
  return envLogFormat === 'json' ? 'json' : 'console';
}

/**
 * Check if the given log level should be logged based on the configured level
 */
function shouldLog(level: LogLevel): boolean {
  const configuredLevel = getConfiguredLogLevel();
  return LOG_LEVEL_PRIORITY[level] >= LOG_LEVEL_PRIORITY[configuredLevel];
}

/**
 * Recursively mask sensitive data in objects
 */
// Type definitions for structured JSON values
type JsonValue = string | number | boolean | null | JsonObject | JsonArray;
type JsonArray = JsonValue[];
interface JsonObject { [key: string]: JsonValue; }

/**
 * Recursively mask sensitive data in objects
 * @param data The data to mask sensitive fields from
 * @returns A copy of the data with sensitive fields masked
 */
function maskSensitiveData(data: JsonValue): JsonValue {
  if (typeof data !== 'object' || data === null) {
    return data;
  }

  if (Array.isArray(data)) {
    return data.map(maskSensitiveData);
  }

  const maskedObject: { [key: string]: JsonValue } = {};
  for (const key in data) {
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      // Match common patterns for sensitive data
      const lowerKey = key.toLowerCase();
      
      // Check if this is a sensitive field that should be masked
      if (SENSITIVE_FIELDS.some(field => lowerKey.includes(field))) {
        maskedObject[key] = '[REDACTED]';
      } 
      // Special handling for tokens and keys
      else if (typeof data[key] === 'string' && 
               (lowerKey.includes('token') || lowerKey.includes('key') || lowerKey.includes('secret'))) {
        maskedObject[key] = '[REDACTED_TOKEN]';
      } 
      // Email pattern detection
      else if (typeof data[key] === 'string' && 
               /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/.test(data[key] as string)) {
        maskedObject[key] = '[REDACTED_EMAIL]';
      }
      // Recursive mask for nested objects
      else {
        maskedObject[key] = maskSensitiveData(data[key]);
      }
    }
  }
  return maskedObject;
}

// Standard log entry format matching the structured logging best practices
interface LogEntry {
  timestamp: string;      // RFC3339 format
  level: string;          // debug|info|warn|error
  message: string;        // Main log message
  component?: string;     // Application component generating this log
  request_id?: string;    // For tracking related logs in HTTP requests
  duration_ms?: number;   // For performance monitoring
  caller?: string;        // Source file and line number
  environment?: string;   // dev|test|prod
  // Additional context and error information
  context?: Record<string, JsonValue>;
  error?: {
    name?: string;
    message?: string;
    stack?: string;
  };
}

/**
 * Format a log entry according to our structured logging standards
 */
function formatLog(
  level: LogLevel,
  message: string, 
  context?: Record<string, JsonValue>, 
  error?: Error
): LogEntry {
  // Start with the standard log structure
  const entry: LogEntry = {
    timestamp: new Date().toISOString(), // RFC3339 format
    level: level.toUpperCase(),
    message,
    environment: process.env.NODE_ENV || 'development',
  };

  // Add structured context if provided
  if (context) {
    const contextRecord = context as Record<string, JsonValue>;
    
    // Extract special fields that should be at the top level
    if ('component' in contextRecord && typeof contextRecord.component === 'string') {
      entry.component = contextRecord.component;
      delete contextRecord.component;
    }
    
    if ('request_id' in contextRecord && typeof contextRecord.request_id === 'string') {
      entry.request_id = contextRecord.request_id;
      delete contextRecord.request_id;
    }
    
    if ('duration_ms' in contextRecord && typeof contextRecord.duration_ms === 'number') {
      entry.duration_ms = contextRecord.duration_ms;
      delete contextRecord.duration_ms;
    }
    
    // Only add context field if there's remaining context
    if (Object.keys(contextRecord).length > 0) {
      // Deep clone and mask sensitive data
      try {
        const safeContext = JSON.parse(JSON.stringify(contextRecord)) as Record<string, JsonValue>;
        entry.context = maskSensitiveData(safeContext) as Record<string, JsonValue>;
      } catch (error) {
        // If JSON serialization fails, use a simplified approach
        console.warn('Failed to serialize log context:', error);
        entry.context = { error: 'Context contained non-serializable values' };
      }
    }
  }

  // Add error information if provided
  if (error) {
    entry.error = {
      name: error.name,
      message: error.message,
    };
    
    // Only include stack traces in development or for high-severity issues
    if ((process.env.NODE_ENV === 'development' || level === 'error') && error.stack) {
      entry.error.stack = maskSensitiveData(error.stack) as string;
    }
  }

  return entry;
}

/** 
 * Special logging functions for specific types of events
 */
function logHTTPRequest(method: string, url: string, statusCode: number, durationMs: number): void {
  if (!shouldLog('info')) return;
  
  logger.info(`HTTP ${method} ${statusCode}`, {
    component: 'http',
    duration_ms: durationMs,
    method,
    status: statusCode,
    // Don't log the full URL to avoid logging sensitive query parameters
    path: url.split('?')[0]
  });
}

function logAuthAttempt(userIdentifier: string, success: boolean, reason?: string): void {
  const level = success ? 'info' : 'warn';
  if (!shouldLog(level)) return;
  
  // Safely mask the user identifier
  const maskedIdentifier = typeof userIdentifier === 'string' 
    ? userIdentifier.replace(/(.{2})(.*)(@.*)/, '$1***$3')
    : '[INVALID_IDENTIFIER]';
  
  logger[level](`Authentication attempt: ${success ? 'Success' : 'Failed'}`, {
    component: 'auth',
    success,
    user: maskedIdentifier,
    reason: reason || (success ? 'Successful login' : 'Failed login attempt')
  });
}

// The main logger object
const logger = {
  debug: (message: string, context?: Record<string, JsonValue>) => {
    if (!shouldLog('debug')) return;
    
    const logEntry = formatLog('debug', message, context);
    
    if (getConfiguredLogFormat() === 'json') {
      console.debug(JSON.stringify(logEntry));
    } else {
      console.debug(`DEBUG [${logEntry.timestamp}]${logEntry.component ? ` [${logEntry.component}]` : ''}: ${message}`);
      if (logEntry.context) console.debug(logEntry.context);
    }
  },
  
  info: (message: string, context?: Record<string, JsonValue>) => {
    if (!shouldLog('info')) return;
    
    const logEntry = formatLog('info', message, context);
    
    if (getConfiguredLogFormat() === 'json') {
      console.log(JSON.stringify(logEntry));
    } else {
      console.log(`INFO [${logEntry.timestamp}]${logEntry.component ? ` [${logEntry.component}]` : ''}: ${message}`);
      if (logEntry.context) console.log(logEntry.context);
    }
  },
  
  warn: (message: string, context?: Record<string, JsonValue>, error?: Error) => {
    if (!shouldLog('warn')) return;
    
    const logEntry = formatLog('warn', message, context, error);
    
    if (getConfiguredLogFormat() === 'json') {
      console.warn(JSON.stringify(logEntry));
    } else {
      console.warn(`WARN [${logEntry.timestamp}]${logEntry.component ? ` [${logEntry.component}]` : ''}: ${message}`);
      if (logEntry.context) console.warn(logEntry.context);
      if (error) console.warn(error);
    }
  },
  
  error: (message: string, context?: Record<string, JsonValue>, error?: Error) => {
    if (!shouldLog('error')) return;
    
    const logEntry = formatLog('error', message, context, error);
    
    if (getConfiguredLogFormat() === 'json') {
      console.error(JSON.stringify(logEntry));
    } else {
      console.error(`ERROR [${logEntry.timestamp}]${logEntry.component ? ` [${logEntry.component}]` : ''}: ${message}`);
      if (logEntry.context) console.error(logEntry.context);
      if (error) console.error(error);
    }
  },
  
  // Special logging functions
  http: logHTTPRequest,
  authAttempt: logAuthAttempt
};

export default logger;