// lpg-ui/vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react'; // Required for React component testing

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true, // Makes Vitest's APIs (describe, it, expect, etc.) available globally
    environment: 'jsdom', // Simulates a browser environment for testing UI components
    setupFiles: './src/test-setup.ts', // Path to a setup file for global test configurations
    css: true, // If your components import CSS files
    // reporters: ['verbose'], // Optional: for more detailed test output
    coverage: {
      provider: 'v8', // or 'istanbul'
      reporter: ['text', 'json', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/types/**/*', 
        'src/**/index.ts', 
        'src/**/*.d.ts',
        'src/test-setup.ts',
        'src/app/api/**/*', // Exclude API route handlers if any
        '**/*.config.{js,ts,mjs}',
        '.next/**/*',
        'node_modules/**/*',
      ],
    },
  },
  resolve: {
    alias: {
      '@/': new URL('./src/', import.meta.url).pathname,
    },
  },
});