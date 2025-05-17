/** @type {import('next').NextConfig} */
const nextConfig = {
  // Ensure SWC is explicitly enabled for Vercel
  swcMinify: true,
  // Explicitly set the output export format
  output: 'standalone',
  // Add React strict mode for better development experience
  reactStrictMode: true,
  // Disable image optimization which might depend on missing binaries
  images: {
    unoptimized: true
  },
};

module.exports = nextConfig;
