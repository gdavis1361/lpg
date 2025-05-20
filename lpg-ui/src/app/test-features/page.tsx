"use client";

import { useEffect, useState } from "react";

export default function TestFeaturesPage() {
  const [isDarkMode, setIsDarkMode] = useState(true); // Default to true since layout has dark class

  useEffect(() => {
    // Check HTML element for dark class on component mount
    const isDark = document.documentElement.classList.contains("dark");
    setIsDarkMode(isDark);
  }, []);

  const toggleDarkMode = () => {
    // Get current state directly from DOM to avoid stale state issues
    const htmlElement = document.documentElement;
    const currentlyDark = htmlElement.classList.contains("dark");
    
    if (currentlyDark) {
      // Currently dark, switching to light
      htmlElement.classList.remove("dark");
      setIsDarkMode(false);
    } else {
      // Currently light, switching to dark
      htmlElement.classList.add("dark");
      setIsDarkMode(true);
    }
  };

  return (
    <div className="p-8 flex flex-col items-center gap-8">
      <h1 className="text-3xl font-bold">Feature Test Page</h1>
      
      {/* Dark Mode Status */}
      <div className="w-full max-w-2xl text-center">
        <div className={`px-4 py-2 rounded-lg font-bold ${isDarkMode ? 'bg-blue-500 text-white' : 'bg-yellow-500 text-black'}`}>
          Current Mode: {isDarkMode ? '🌙 DARK MODE ENABLED' : '☀️ LIGHT MODE ENABLED'}
        </div>
      </div>

      {/* Font Test */}
      <section className="border dark:border-gray-600 p-6 rounded-lg w-full max-w-2xl bg-white dark:bg-gray-800 transition-colors duration-200">
        <h2 className="text-xl font-bold mb-4 dark:text-white">Font Test</h2>
        <p className="font-sans mb-2 dark:text-gray-300">
          This text should use Geist Sans (font-sans)
        </p>
        <p className="font-mono mb-2 dark:text-gray-300">
          This text should use Geist Mono (font-mono)
        </p>
      </section>

      {/* Animation Test */}
      <section className="border dark:border-gray-600 p-6 rounded-lg w-full max-w-2xl bg-white dark:bg-gray-800 transition-colors duration-200">
        <h2 className="text-xl font-bold mb-4 dark:text-white">Animation Test</h2>
        <div className="flex flex-wrap gap-8 justify-center p-4">
          <div className="text-center">
            <div className="animate-spin h-12 w-12 border-4 border-blue-500 border-t-transparent rounded-full mx-auto"></div>
            <p className="mt-2 dark:text-white">animate-spin</p>
          </div>
          <div className="text-center">
            <div className="animate-pulse h-12 w-12 bg-blue-500 rounded-full mx-auto"></div>
            <p className="mt-2 dark:text-white">animate-pulse</p>
          </div>
          <div className="text-center">
            <div className="animate-bounce h-12 w-12 bg-green-500 rounded-full mx-auto"></div>
            <p className="mt-2 dark:text-white">animate-bounce</p>
          </div>
          <div className="text-center relative h-12">
            <div className="animate-ping h-6 w-6 bg-red-500 rounded-full absolute left-1/2 -translate-x-1/2"></div>
            <div className="h-6 w-6 bg-red-500 rounded-full absolute left-1/2 -translate-x-1/2 opacity-75"></div>
            <p className="mt-16 dark:text-white">animate-ping</p>
          </div>
        </div>
      </section>

      {/* Dark Mode Test */}
      <section className="border dark:border-gray-600 p-6 rounded-lg w-full max-w-2xl bg-white dark:bg-gray-800 transition-colors duration-200">
        <h2 className="text-xl font-bold mb-4 dark:text-white">Dark Mode Test</h2>
        <p className="dark:text-white mb-4">
          This text should change color in dark mode
        </p>
        <div className="bg-gray-100 dark:bg-gray-900 p-4 rounded border dark:border-gray-700 transition-colors duration-200">
          <p className="text-black dark:text-white">
            This container should change background in dark mode
          </p>
        </div>
        <button
          onClick={toggleDarkMode}
          className={`mt-4 px-4 py-2 text-white rounded-lg transition-colors ${
            isDarkMode 
              ? 'bg-yellow-500 hover:bg-yellow-600' 
              : 'bg-blue-500 hover:bg-blue-600'
          }`}
        >
          {isDarkMode ? '☀️ Switch to Light Mode' : '🌙 Switch to Dark Mode'}
        </button>
      </section>
    </div>
  );
} 