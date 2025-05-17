// src/lib/logger.ts

const SENSITIVE_FIELDS = ['email', 'phone', 'password', 'token', 'authorization', 'firstName', 'lastName', 'address'];

function maskSensitiveData(data: any): any {
  if (typeof data !== 'object' || data === null) {
    return data;
  }

  if (Array.isArray(data)) {
    return data.map(maskSensitiveData);
  }

  const maskedObject: { [key: string]: any } = {};
  for (const key in data) {
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      if (SENSITIVE_FIELDS.includes(key.toLowerCase())) {
        maskedObject[key] = '[REDACTED]';
      } else if (typeof data[key] === 'string' && (key.toLowerCase().includes('token') || key.toLowerCase().includes('key'))) {
        maskedObject[key] = '[REDACTED_TOKEN]';
      } else {
        maskedObject[key] = maskSensitiveData(data[key]);
      }
    }
  }
  return maskedObject;
}

interface LogEntry {
  timestamp: string;
  level: 'INFO' | 'WARN' | 'ERROR' | 'DEBUG';
  message: string;
  context?: Record<string, any>;
  error?: {
    name?: string;
    message?: string;
    stack?: string;
  };
}

function formatLog(level: LogEntry['level'], message: string, context?: Record<string, any>, error?: Error): LogEntry {
  const entry: LogEntry = {
    timestamp: new Date().toISOString(),
    level,
    message,
  };
  if (context) {
    entry.context = maskSensitiveData(JSON.parse(JSON.stringify(context))); // Deep clone and mask
  }
  if (error) {
    entry.error = {
      name: error.name,
      message: error.message,
      stack: error.stack ? maskSensitiveData(error.stack) : undefined,
    };
  }
  return entry;
}

const logger = {
  info: (message: string, context?: Record<string, any>) => {
    if (process.env.NODE_ENV !== 'production') {
      console.log(JSON.stringify(formatLog('INFO', message, context), null, 2));
    }
    // TODO: Send to a remote logging service in production
  },
  warn: (message: string, context?: Record<string, any>, error?: Error) => {
    if (process.env.NODE_ENV !== 'production') {
      console.warn(JSON.stringify(formatLog('WARN', message, context, error), null, 2));
    }
    // TODO: Send to a remote logging service in production
  },
  error: (message: string, context?: Record<string, any>, error?: Error) => {
    console.error(JSON.stringify(formatLog('ERROR', message, context, error), null, 2));
    // TODO: Send to a remote logging service in production, always send errors
  },
  debug: (message: string, context?: Record<string, any>) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug(JSON.stringify(formatLog('DEBUG', message, context), null, 2));
    }
    // Debug logs are typically not sent to remote services unless explicitly enabled
  },
};

export default logger;