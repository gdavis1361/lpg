import React from "react";
import { cn } from "@/lib/utils";

// Define section size variants for different spacing needs
export type SectionSize = "sm" | "md" | "lg" | "xl";

// Define section variants for different visual treatments
export type SectionVariant = "default" | "alternate" | "primary" | "muted";

interface SectionProps {
  children: React.ReactNode;
  id?: string;
  className?: string;
  size?: SectionSize;
  variant?: SectionVariant;
  containerClassName?: string;
  innerClassName?: string;
  fullWidth?: boolean;
}

// Define consistent spacing scales for sections
const sectionSizeVariants: Record<SectionSize, string> = {
  sm: "py-4 md:py-6",
  md: "py-8 md:py-12",
  lg: "py-12 md:py-16",
  xl: "py-16 md:py-24",
};

// Define visual variants for different section types
const sectionVariantStyles: Record<SectionVariant, string> = {
  default: "bg-background",
  alternate: "bg-muted/30",
  primary: "bg-primary text-primary-foreground",
  muted: "bg-muted text-muted-foreground",
};

export function Section({
  children,
  id,
  className,
  size = "md", // Default to medium spacing
  variant = "default", // Default to standard background
  containerClassName,
  innerClassName,
  fullWidth = false,
}: SectionProps) {
  return (
    <section
      id={id}
      className={cn(
        sectionSizeVariants[size],
        sectionVariantStyles[variant],
        className
      )}
    >
      <div
        className={cn(
          // If not fullWidth, constrain with container and add horizontal padding
          !fullWidth && "container mx-auto px-4 md:px-6",
          containerClassName
        )}
      >
        <div className={cn("flex flex-col", innerClassName)}>{children}</div>
      </div>
    </section>
  );
} 