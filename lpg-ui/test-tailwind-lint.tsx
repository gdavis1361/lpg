import React from 'react';

// This component should trigger ESLint errors
export default function TestComponent() {
  return (
    <div className="flex flex-col p-4 bg-blue-500 text-white rounded-lg shadow-md">
      <h1 className="text-2xl font-bold">Hello World</h1>
      <p className="mt-2">This component uses direct Tailwind classes</p>
      <button className="mt-4 px-4 py-2 bg-white text-blue-500 rounded hover:bg-gray-100">
        Click me
      </button>
    </div>
  );
} 