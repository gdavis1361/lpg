import { FlatCompat } from '@eslint/eslintrc';
import localRules from './eslint-local-rules/index.js';
import noInlineStyles from 'eslint-plugin-no-inline-styles';

/**
 * ESLint configuration for Tailwind enforcement
 */
const compat = new FlatCompat();

export default [
  // Import base configs
  ...compat.config({
    extends: ['next/core-web-vitals'],
    parser: '@typescript-eslint/parser',
    plugins: ['@typescript-eslint'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': 'off',
      '@typescript-eslint/no-empty-interface': 'off',
      '@typescript-eslint/no-empty-object-type': 'off',
      '@typescript-eslint/ban-types': 'off',
      '@typescript-eslint/no-var-requires': 'off',
    },
  }),
  
  // Tailwind enforcement rules
  {
    files: ['**/*.{js,jsx,ts,tsx}'],
    ignores: [
      '**/*.js',
      '**/*.mjs',
      '**/*.d.ts',
      'node_modules/**',
      '.next/**',
      'src/types/supabase.ts',
      'eslint-local-rules/**',
    ],
    plugins: {
      'no-inline-styles': noInlineStyles,
      'local': { rules: localRules },
    },
    rules: {
      // Rules to prevent direct Tailwind usage
      'local/no-tailwind-classes': 'error',
      
      // Ban inline styles
      'no-inline-styles/no-inline-styles': 'error',
      
      // Ban className props in React components
      'react/forbid-component-props': [
        'error',
        { 
          forbid: [
            { 
              propName: 'className', 
              message: 'Use component library instead of direct Tailwind classes' 
            }
          ] 
        }
      ],
    },
  },
  
  // Exception for component library files
  {
    files: ['**/components/**/*.{jsx,tsx}'],
    rules: {
      'react/forbid-component-props': 'off',
      'local/no-tailwind-classes': 'off',
    },
  },
];
