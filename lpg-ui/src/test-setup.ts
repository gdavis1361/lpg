// lpg-ui/src/test-setup.ts

// Extends Vitest's expect functionality with matchers from @testing-library/jest-dom
// This allows you to use matchers like .toBeInTheDocument(), .toHaveTextContent(), etc.
import '@testing-library/jest-dom/vitest';

// You can add other global setup configurations here if needed.
// For example, mocking global objects or setting up MSW (Mock Service Worker).

// Example: Mocking localStorage (if your components use it)
// const localStorageMock = (() => {
//   let store: { [key: string]: string } = {};
//   return {
//     getItem: (key: string) => store[key] || null,
//     setItem: (key: string, value: string) => {
//       store[key] = value.toString();
//     },
//     removeItem: (key: string) => {
//       delete store[key];
//     },
//     clear: () => {
//       store = {};
//     },
//   };
// })();
// Object.defineProperty(window, 'localStorage', {
//   value: localStorageMock,
// });

// Clean up after each test (optional, but good practice for UI tests)
// import { cleanup } from '@testing-library/react';
// afterEach(() => {
//   cleanup();
// });