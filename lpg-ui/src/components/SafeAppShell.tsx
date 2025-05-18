import React, { Suspense, useState } from "react";
import { ui } from "@/lib/uiConfig";
import { cn } from "@/lib/utils";
import { Menu, X } from "lucide-react";
import { Button } from "@/components/ui/button";

interface SafeAppShellProps {
  children: React.ReactNode;
  /**
   * Enable or disable RetroGrid background - defaults to respecting NEXT_PUBLIC_UI_WOW
   */
  showBackground?: boolean;
  /**
   * Optional custom background props
   */
  backgroundProps?: {
    color?: string;
    lineColor?: string;
    dotColor?: string;
    cellSize?: number;
    speed?: number;
  };
  /**
   * Optional footer content
   */
  footer?: React.ReactNode;
  /**
   * Whether to show a footer (default: true)
   */
  showFooter?: boolean;
  /**
   * CSS classname to apply to the main content area
   */
  contentClassName?: string;
}

export function SafeAppShell({ 
  children, 
  showBackground,
  backgroundProps,
  footer,
  showFooter = true,
  contentClassName,
}: SafeAppShellProps) {
  const [isMobileNavOpen, setIsMobileNavOpen] = useState(false);
  const isWowEnabled = typeof showBackground !== 'undefined' 
    ? showBackground 
    : process.env.NEXT_PUBLIC_UI_WOW === 'true';

  return (
    <div className="relative min-h-dvh flex flex-col">
      {/* Background layer using container queries for responsive design */}
      {isWowEnabled && (
        <Suspense fallback={null}>
          <ui.RetroGridBackground 
            {...backgroundProps}
          />
        </Suspense>
      )}

      {/* Header */}
      <header className="relative z-10 sticky top-0">
        <Suspense fallback={
          <div className="h-16 md:h-20 border-b flex items-center px-4">
            <div className="animate-pulse w-32 h-6 bg-muted rounded-md" />
          </div>
        }>
          <ui.NavBar />
        </Suspense>

        {/* Mobile menu toggle button - only visible on small screens */}
        <div className="absolute top-0 right-0 md:hidden p-4">
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={() => setIsMobileNavOpen(!isMobileNavOpen)}
            aria-label={isMobileNavOpen ? "Close menu" : "Open menu"}
            className="size-10 flex items-center justify-center" // Using Tailwind v4 size utility
          >
            {isMobileNavOpen ? <X className="size-5" /> : <Menu className="size-5" />}
          </Button>
        </div>
      </header>

      {/* Mobile navigation - slides in from right */}
      <Suspense fallback={null}>
        <ui.MobileDrawer
          open={isMobileNavOpen}
          onOpenChange={setIsMobileNavOpen}
        >
          {/* Mobile drawer content is handled by the ui.MobileDrawer component */}
        </ui.MobileDrawer>
      </Suspense>

      {/* Main content area */}
      <main 
        className={cn(
          "flex-1 flex flex-col relative z-0 container mx-auto px-4 md:px-6",
          // New Tailwind v4 container query classes give us more power than media queries
          "@container", // Mark as a container query context
          contentClassName
        )}
      >
        {children}
      </main>

      {/* Optional footer */}
      {showFooter && (
        <footer className="border-t mt-auto py-6 relative z-10">
          <div className="container mx-auto px-4 md:px-6">
            {footer ? (
              footer
            ) : (
              <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
                <div className="text-sm text-muted-foreground">
                  © {new Date().getFullYear()} LPG Platform. All rights reserved.
                </div>
                <div className="flex items-center gap-4 text-sm text-muted-foreground">
                  <a href="#" className="hover:text-foreground transition-colors">Privacy</a>
                  <a href="#" className="hover:text-foreground transition-colors">Terms</a>
                  <a href="#" className="hover:text-foreground transition-colors">Contact</a>
                </div>
              </div>
            )}
          </div>
        </footer>
      )}

      {/* Global toast notifications */}
      <Suspense fallback={null}>
        <ui.ToastProvider />
      </Suspense>

      {/* Command palette - triggered from NavBar */}
      <Suspense fallback={null}>
        <ui.CommandPalette />
      </Suspense>
    </div>
  );
} 