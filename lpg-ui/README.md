This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.

## Apple Silicon (M1/M2) Compatibility

If you're using an Apple Silicon Mac, you might encounter issues with Tailwind CSS native modules. The project includes fixes for this, but if you still have problems:

### Troubleshooting Tailwind on Apple Silicon

1. Run the diagnostic script to check your setup:
   ```bash
   npm run diagnose
   ```

2. If you encounter errors about incompatible binaries, try reinstalling with architecture-specific flags:
   ```bash
   npm install --platform=darwin --arch=arm64
   ```

3. You can also try cleaning your installation and reinstalling:
   ```bash
   rm -rf node_modules
   rm package-lock.json
   npm install
   ```

4. The project includes a `postinstall` script that automatically removes incompatible Linux binaries, which should prevent most issues.
