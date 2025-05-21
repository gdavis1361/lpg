// Simple logger utility for the seed scripts
export const logger = {
  info: (message: string, ...args: any[]) => {
    console.log(`\x1b[36m[INFO]\x1b[0m ${message}`, ...args);
  },
  
  success: (message: string, ...args: any[]) => {
    console.log(`\x1b[32m[SUCCESS]\x1b[0m ${message}`, ...args);
  },
  
  warn: (message: string, ...args: any[]) => {
    console.log(`\x1b[33m[WARN]\x1b[0m ${message}`, ...args);
  },
  
  error: (message: string, ...args: any[]) => {
    console.error(`\x1b[31m[ERROR]\x1b[0m ${message}`, ...args);
  },
  
  debug: (message: string, ...args: any[]) => {
    if (process.env.DEBUG) {
      console.log(`\x1b[90m[DEBUG]\x1b[0m ${message}`, ...args);
    }
  },
  
  // Log a progress bar
  progress: (current: number, total: number, label: string = '') => {
    const percent = Math.floor((current / total) * 100);
    const barLength = 30;
    const filledLength = Math.floor((current / total) * barLength);
    
    const bar = '█'.repeat(filledLength) + '░'.repeat(barLength - filledLength);
    
    process.stdout.write(`\r\x1b[36m[PROGRESS]\x1b[0m ${bar} ${percent}% ${label ? `(${label})` : ''}`);
    
    if (current === total) {
      process.stdout.write('\n');
    }
  }
}; 