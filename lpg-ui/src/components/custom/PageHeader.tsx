import React from "react";
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from "@/components/ui/breadcrumb";
import { cn } from "@/lib/utils";

// Define heading scale variant types
type HeadingVariant = "h1" | "h2" | "h3" | "h4" | "h5" | "h6";

// Define Tailwind classes for each heading variant
export const headingVariants: Record<HeadingVariant, string> = {
  h1: "text-3xl md:text-4xl font-bold tracking-tight",
  h2: "text-2xl md:text-3xl font-semibold tracking-tight",
  h3: "text-xl md:text-2xl font-medium",
  h4: "text-lg md:text-xl font-medium",
  h5: "text-base md:text-lg font-medium",
  h6: "text-sm md:text-base font-medium",
};

interface BreadcrumbItem {
  label: string;
  href?: string;
  isCurrentPage?: boolean;
}

interface PageHeaderProps {
  title: string;
  description?: string;
  breadcrumbs?: BreadcrumbItem[];
  actions?: React.ReactNode;
  variant?: HeadingVariant;
  className?: string;
  titleClassName?: string;
  descriptionClassName?: string;
  breadcrumbsClassName?: string;
  actionsClassName?: string;
}

export function PageHeader({
  title,
  description,
  breadcrumbs,
  actions,
  variant = "h1", // Default to h1 variant
  className,
  titleClassName,
  descriptionClassName,
  breadcrumbsClassName,
  actionsClassName,
}: PageHeaderProps) {
  // Render heading based on variant
  const renderHeading = () => {
    const headingClass = cn(headingVariants[variant], titleClassName);
    
    switch (variant) {
      case "h1":
        return <h1 className={headingClass}>{title}</h1>;
      case "h2":
        return <h2 className={headingClass}>{title}</h2>;
      case "h3":
        return <h3 className={headingClass}>{title}</h3>;
      case "h4":
        return <h4 className={headingClass}>{title}</h4>;
      case "h5":
        return <h5 className={headingClass}>{title}</h5>;
      case "h6":
        return <h6 className={headingClass}>{title}</h6>;
      default:
        return <h1 className={headingClass}>{title}</h1>;
    }
  };
  
  return (
    <div className={cn("pb-6 space-y-4", className)}>
      {breadcrumbs && breadcrumbs.length > 0 && (
        <Breadcrumb className={cn("mb-2", breadcrumbsClassName)}>
          <BreadcrumbList>
            {breadcrumbs.map((item, index) => (
              <React.Fragment key={item.label}>
                {item.isCurrentPage ? (
                  <BreadcrumbPage>{item.label}</BreadcrumbPage>
                ) : (
                  <BreadcrumbItem>
                    <BreadcrumbLink href={item.href ?? "#"}>{item.label}</BreadcrumbLink>
                  </BreadcrumbItem>
                )}
                {index < breadcrumbs.length - 1 && <BreadcrumbSeparator />}
              </React.Fragment>
            ))}
          </BreadcrumbList>
        </Breadcrumb>
      )}
      
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="space-y-1">
          {renderHeading()}
          
          {description && (
            <p className={cn("text-muted-foreground text-sm md:text-base", descriptionClassName)}>
              {description}
            </p>
          )}
        </div>
        
        {actions && (
          <div className={cn("flex items-center gap-2 mt-2 sm:mt-0", actionsClassName)}>
            {actions}
          </div>
        )}
      </div>
    </div>
  );
} 