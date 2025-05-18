import React, { useState, Suspense } from 'react';
import { ui } from '@/lib/uiConfig';
import { cn } from '@/lib/utils';
import { AlertCircle, Bell, Check, ChevronDown, FileText, Github, Moon, Sun } from 'lucide-react';
import { Switch } from '@/components/ui/switch';

const fallbackLoader = (
  <div className="flex h-24 w-full items-center justify-center">
    <div className="h-6 w-6 animate-spin rounded-full border-b-2 border-primary"></div>
  </div>
);

export function ComponentShowcase() {
  const [isWowEnabled, setIsWowEnabled] = useState(process.env.NEXT_PUBLIC_UI_WOW === 'true');
  const [isDarkMode, setIsDarkMode] = useState(false);
  
  // Toggle between enhanced and standard components
  const toggleWowMode = () => {
    // In a real app, this would update the environment variable and trigger a reload
    // For demo purposes, we'll just update the state
    setIsWowEnabled(!isWowEnabled);
  };
  
  // Toggle dark mode
  const toggleTheme = () => {
    const newMode = !isDarkMode;
    setIsDarkMode(newMode);
    
    if (newMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };
  
  return (
    <div className="min-h-screen w-full bg-background relative">
      {/* RetroGrid background when "wow" mode is enabled */}
      <Suspense fallback={null}>
        {isWowEnabled && <ui.RetroGridBackground color="oklch(var(--background) / 0.8)" />}
      </Suspense>
      
      <div className="container mx-auto py-20 px-4 space-y-12">
        <header className="text-center space-y-4">
          <h1 className="text-4xl font-bold">LPG UI Framework</h1>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            A modern, responsive UI system that integrates shadcn/ui with enhanced animations and effects
          </p>
          
          <div className="flex items-center justify-center space-x-8 mt-6">
            <div className="flex items-center space-x-2">
              <span className="text-sm font-medium">Standard</span>
              <Switch 
                checked={isWowEnabled} 
                onCheckedChange={toggleWowMode} 
                className="data-[state=checked]:bg-gradient-to-r from-navy-600 to-gold-500"
              />
              <span className="text-sm font-medium">Enhanced</span>
            </div>
            
            <div className="flex items-center space-x-2">
              <Sun className="h-4 w-4" />
              <Switch 
                checked={isDarkMode} 
                onCheckedChange={toggleTheme}
              />
              <Moon className="h-4 w-4" />
            </div>
          </div>
        </header>
        
        <section className="grid gap-8 md:grid-cols-2">
          <div className="bg-card rounded-lg shadow-sm p-6 space-y-4">
            <h2 className="text-2xl font-bold">Buttons</h2>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <Suspense fallback={fallbackLoader}>
                <ui.Button>Default</ui.Button>
              </Suspense>
              
              <Suspense fallback={fallbackLoader}>
                <ui.Button variant="destructive">Destructive</ui.Button>
              </Suspense>
              
              <Suspense fallback={fallbackLoader}>
                <ui.Button variant="outline">Outline</ui.Button>
              </Suspense>
              
              <Suspense fallback={fallbackLoader}>
                <ui.Button variant="secondary">Secondary</ui.Button>
              </Suspense>
              
              <Suspense fallback={fallbackLoader}>
                <ui.Button variant="ghost">Ghost</ui.Button>
              </Suspense>
              
              <Suspense fallback={fallbackLoader}>
                <ui.Button variant="link">Link</ui.Button>
              </Suspense>
              
              {isWowEnabled && (
                <>
                  <Suspense fallback={fallbackLoader}>
                    {/* Use type assertion for wow-specific props */}
                    {React.createElement(ui.Button as any, { 
                      variant: "gradient", 
                      icon: <Github className="h-4 w-4" />
                    }, "Gradient")}
                  </Suspense>
                  
                  <Suspense fallback={fallbackLoader}>
                    {React.createElement(ui.Button as any, { 
                      variant: "bronze",
                      shimmer: true
                    }, "Bronze")}
                  </Suspense>
                  
                  <Suspense fallback={fallbackLoader}>
                    {React.createElement(ui.Button as any, { 
                      variant: "navy",
                      glow: true
                    }, "Navy Glow")}
                  </Suspense>
                  
                  <Suspense fallback={fallbackLoader}>
                    {React.createElement(ui.Button as any, { 
                      variant: "gold",
                      ripple: true
                    }, "Gold Ripple")}
                  </Suspense>
                </>
              )}
            </div>
          </div>
          
          <div className="bg-card rounded-lg shadow-sm p-6 space-y-4">
            <h2 className="text-2xl font-bold">Status Indicators</h2>
            <div className="flex flex-wrap gap-4">
              <ui.StatusBadge variant="default">Default</ui.StatusBadge>
              <ui.StatusBadge variant="secondary">Secondary</ui.StatusBadge>
              <ui.StatusBadge variant="outline">Outline</ui.StatusBadge>
              <ui.StatusBadge variant="destructive">Error</ui.StatusBadge>
              
              <ui.StatusBadge className="bg-emerald-500 hover:bg-emerald-600">
                <Check className="h-3 w-3 mr-1" /> Success
              </ui.StatusBadge>
              
              <ui.StatusBadge className="bg-amber-500 hover:bg-amber-600">
                <AlertCircle className="h-3 w-3 mr-1" /> Warning
              </ui.StatusBadge>
              
              <ui.StatusBadge className="bg-bronze-600 hover:bg-bronze-700 text-white">
                Bronze
              </ui.StatusBadge>
              
              <ui.StatusBadge className="bg-navy-700 hover:bg-navy-800 text-white">
                Navy
              </ui.StatusBadge>
              
              <ui.StatusBadge className="bg-gold-500 hover:bg-gold-600 text-navy-900">
                Gold
              </ui.StatusBadge>
            </div>
          </div>
        </section>
        
        <section>
          <ui.PageHeader
            title="Page Components"
            description="Reusable components for consistent page layouts"
            actions={
              <Suspense fallback={fallbackLoader}>
                {React.createElement(ui.Button as any, { 
                  icon: <FileText className="h-4 w-4" />
                }, "View Documentation")}
              </Suspense>
            }
          />
          
          <div className="grid md:grid-cols-2 gap-8 mt-8">
            <ui.Section>
              <h3 className="text-xl font-semibold mb-2">Section Component</h3>
              <p className="text-muted-foreground">Sections help organize content into logical groups with consistent styling.</p>
            </ui.Section>
            
            <div className="rounded-lg border bg-card text-card-foreground shadow-sm">
              <div className="flex flex-col space-y-1.5 p-6">
                <h3 className="text-lg font-semibold leading-none tracking-tight">Card Component</h3>
                <p className="text-sm text-muted-foreground">
                  Cards provide a container for related information and actions.
                </p>
              </div>
              <div className="p-6 pt-0">
                <p>Content can include text, images, and interactive elements.</p>
              </div>
              <div className="flex items-center p-6 pt-0 justify-end">
                <Suspense fallback={fallbackLoader}>
                  <ui.Button variant="outline" size="sm">Learn More</ui.Button>
                </Suspense>
              </div>
            </div>
          </div>
        </section>
        
        <section>
          <ui.EmptyState
            icon={<Bell className="h-10 w-10 text-muted-foreground" />}
            title="No Notifications"
            description="You don't have any notifications at the moment. We'll notify you when something important happens."
            action={{
              text: "Check Settings",
              onClick: () => console.log("Settings clicked"),
              buttonProps: { variant: "outline" }
            }}
          />
        </section>
      </div>
    </div>
  );
} 