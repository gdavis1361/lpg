/** @type {import('next').NextConfig} */
const nextConfig = {
  // Ensure SWC is explicitly enabled for Vercel
  swcMinify: true,
  // Explicitly set the output export format
  output: 'standalone',
  // Disable experimental features that might cause issues
  experimental: {
    // Reset any experimental features that might conflict
  },
  // Add React strict mode for better development experience
  reactStrictMode: true,
};

module.exports = nextConfig;
