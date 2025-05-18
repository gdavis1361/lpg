import type { Config } from "tailwindcss";
import animatePlugin from "tailwindcss-animate";

// Define brand colors in OKLCH color space for more vibrant transitions
const brandColors = {
  navy: {
    DEFAULT: "oklch(0.2 0.17 264)",
    50: "oklch(0.95 0.03 264)",
    100: "oklch(0.9 0.04 264)",
    200: "oklch(0.8 0.07 264)",
    300: "oklch(0.7 0.09 264)",
    400: "oklch(0.6 0.12 264)",
    500: "oklch(0.5 0.15 264)",
    600: "oklch(0.4 0.17 264)",
    700: "oklch(0.3 0.17 264)",
    800: "oklch(0.2 0.17 264)",
    900: "oklch(0.1 0.15 264)",
    950: "oklch(0.05 0.1 264)",
  },
  bronze: {
    DEFAULT: "oklch(0.6 0.13 63)",
    50: "oklch(0.97 0.03 63)",
    100: "oklch(0.94 0.05 63)",
    200: "oklch(0.88 0.07 63)",
    300: "oklch(0.82 0.09 63)",
    400: "oklch(0.75 0.11 63)",
    500: "oklch(0.68 0.13 63)",
    600: "oklch(0.6 0.13 63)",
    700: "oklch(0.52 0.12 63)",
    800: "oklch(0.43 0.1 63)",
    900: "oklch(0.35 0.08 63)",
    950: "oklch(0.25 0.06 63)",
  },
  gold: {
    DEFAULT: "oklch(0.8 0.15 85)",
    50: "oklch(0.98 0.03 85)",
    100: "oklch(0.96 0.05 85)",
    200: "oklch(0.94 0.08 85)",
    300: "oklch(0.9 0.1 85)",
    400: "oklch(0.86 0.13 85)",
    500: "oklch(0.82 0.15 85)",
    600: "oklch(0.76 0.15 85)",
    700: "oklch(0.7 0.14 85)",
    800: "oklch(0.62 0.12 85)",
    900: "oklch(0.55 0.1 85)",
    950: "oklch(0.45 0.08 85)",
  },
};

export default {
  darkMode: "class",
  content: [
    "./src/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      fontFamily: {
        sans: ["var(--font-geist-sans)", "system-ui", "sans-serif"],
        mono: ["var(--font-geist-mono)", "ui-monospace", "monospace"],
      },
      colors: {
        ...brandColors,
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "oklch(var(--primary))",
          foreground: "oklch(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "oklch(var(--secondary))",
          foreground: "oklch(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "oklch(var(--destructive))",
          foreground: "oklch(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
    },
  },
  plugins: [animatePlugin],
} satisfies Config; 