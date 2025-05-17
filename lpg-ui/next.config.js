/** @type {import('next').NextConfig} */
const nextConfig = {
  // Explicitly set the output export format
  output: 'standalone',
  // Add React strict mode for better development experience
  reactStrictMode: true,
  // Ensure transpilation of the tailwindcss package
  transpilePackages: [
    'tailwindcss',
    '@tailwindcss/postcss',
  ],
  // Disable image optimization which might depend on missing binaries
  images: {
    unoptimized: true
  },
};

module.exports = nextConfig;
