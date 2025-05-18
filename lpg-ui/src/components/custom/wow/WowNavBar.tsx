import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Command, ChevronDown, Menu, Sparkles } from 'lucide-react';
import { Avatar } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Switch } from '@/components/ui/switch';
import { CommandDialog } from '@/components/ui/command';
import { cn } from '@/lib/utils';

// Define navigation items
const navigationItems = [
  { label: 'Dashboard', href: '/dashboard' },
  { label: 'Projects', href: '/projects' },
  { label: 'Calendar', href: '/calendar' },
  { label: 'Reports', href: '/reports' },
];

// Create custom GlassBackground since Magic UI may not have it
const GlassBackground = ({ 
  blur = 8, 
  opacity = 0.5, 
  color = 'transparent', 
  className = '' 
}: { 
  blur?: number; 
  opacity?: number; 
  color?: string; 
  className?: string;
}) => (
  <div 
    className={cn("absolute inset-0 z-[-1]", className)} 
    style={{ 
      backdropFilter: `blur(${blur}px)`,
      backgroundColor: color,
      opacity
    }}
  />
);

// Custom AnimatedList component
function AnimatedList({ 
  className, 
  itemClassName, 
  items, 
  renderItem, 
  staggerDelay = 0.05 
}: { 
  className?: string; 
  itemClassName?: string; 
  items: any[]; 
  renderItem: (item: any, index: number) => React.ReactNode; 
  staggerDelay?: number;
}) {
  return (
    <motion.div className={className}>
      {items.map((item, index) => (
        <motion.div
          key={index}
          className={itemClassName}
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * staggerDelay }}
        >
          {renderItem(item, index)}
        </motion.div>
      ))}
    </motion.div>
  );
}

// Custom sparkles effect for logo
function SparklesEffect({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={cn("relative", className)}>
      <motion.div
        className="absolute inset-0 z-[-1]"
        initial={{ opacity: 0 }}
        animate={{ opacity: [0, 0.5, 0] }}
        transition={{ duration: 2, repeat: Infinity, repeatType: "reverse" }}
      >
        <div className="absolute w-1 h-1 bg-primary rounded-full top-0 right-0" />
        <div className="absolute w-1 h-1 bg-primary rounded-full bottom-0 left-0" />
        <div className="absolute w-1 h-1 bg-primary rounded-full top-1/2 left-1/4" />
      </motion.div>
      {children}
    </div>
  );
}

export default function WowNavBar() {
  const pathname = usePathname();
  const [scrolled, setScrolled] = useState(false);
  const [commandOpen, setCommandOpen] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(false);
  
  // Listen for scroll events to trigger animations
  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    
    // Check dark mode preference
    setIsDarkMode(document.documentElement.classList.contains('dark'));
    
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

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
    <>
      <motion.header
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: 'easeOut' }}
        className={cn(
          'fixed top-0 left-0 right-0 z-50 transition-all duration-300',
          scrolled 
            ? 'h-16 border-b shadow-sm' 
            : 'h-20'
        )}
      >
        {/* Glass background effect that increases on scroll */}
        <GlassBackground
          blur={scrolled ? 10 : 5}
          opacity={scrolled ? 0.8 : 0.5}
          color={scrolled ? 'var(--primary)' : 'transparent'}
          className="absolute inset-0 z-[-1]"
        />
        
        <div className="container mx-auto h-full flex items-center justify-between px-4">
          {/* Logo area */}
          <motion.div 
            className="flex items-center"
            whileHover={{ scale: 1.05 }}
            transition={{ type: 'spring', stiffness: 400, damping: 10 }}
          >
            <Link href="/" className="flex items-center space-x-2">
              <SparklesEffect className="text-primary w-8 h-8">
                <div className="w-8 h-8 bg-primary rounded-md flex items-center justify-center text-white font-bold">
                  LPG
                </div>
              </SparklesEffect>
              <span className="font-bold text-xl hidden sm:inline-block">LPG Platform</span>
            </Link>
          </motion.div>
          
          {/* Desktop Navigation */}
          <div className="hidden md:block">
            <AnimatedList
              className="flex space-x-1"
              itemClassName="relative"
              items={navigationItems}
              renderItem={(item, index) => (
                <NavItem 
                  key={item.href}
                  label={item.label} 
                  href={item.href}
                  isActive={pathname === item.href}
                />
              )}
              staggerDelay={0.05}
            />
          </div>
          
          {/* Right side actions */}
          <div className="flex items-center space-x-2 md:space-x-4">
            {/* Command palette trigger */}
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setCommandOpen(true)}
              className="rounded-md p-2 text-foreground hover:bg-primary/10 transition-colors"
              aria-label="Open command palette"
            >
              <Command className="w-4 h-4" />
            </motion.button>
            
            {/* Theme toggle */}
            <motion.div 
              whileTap={{ scale: 0.95 }}
              className="flex items-center"
            >
              <Switch
                checked={isDarkMode}
                onCheckedChange={toggleTheme}
                className="data-[state=checked]:bg-primary"
              />
            </motion.div>
            
            {/* User menu */}
            <UserMenu />
            
            {/* Mobile menu */}
            <div className="md:hidden">
              <Sheet>
                <SheetTrigger asChild>
                  <Button variant="ghost" size="icon" aria-label="Menu">
                    <Menu className="h-5 w-5" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="right" className="w-[300px]">
                  <div className="flex flex-col space-y-4 mt-6">
                    {navigationItems.map((item) => (
                      <Link 
                        key={item.href} 
                        href={item.href}
                        className={cn(
                          "p-2 rounded-md transition-colors",
                          pathname === item.href 
                            ? "bg-primary/10 text-primary font-medium" 
                            : "hover:bg-primary/5"
                        )}
                      >
                        {item.label}
                      </Link>
                    ))}
                  </div>
                </SheetContent>
              </Sheet>
            </div>
          </div>
        </div>
      </motion.header>
      
      {/* Command Dialog */}
      <CommandDialog open={commandOpen} onOpenChange={setCommandOpen}>
        {/* Command dialog content would be implemented here */}
      </CommandDialog>
      
      {/* Spacer to prevent content from hiding behind fixed header */}
      <div className={cn(
        "transition-all duration-300",
        scrolled ? "h-16" : "h-20"
      )} />
    </>
  );
}

// Navigation Item with animation effects
function NavItem({ label, href, isActive }: { label: string; href: string; isActive: boolean }) {
  return (
    <Link href={href} legacyBehavior>
      <motion.a
        className={cn(
          "relative px-3 py-2 rounded-md text-sm font-medium transition-colors",
          isActive 
            ? "text-primary" 
            : "text-foreground hover:text-primary"
        )}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
      >
        {label}
        {isActive && (
          <motion.div
            className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary"
            layoutId="navbar-indicator"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ type: "spring", stiffness: 500, damping: 30 }}
          />
        )}
      </motion.a>
    </Link>
  );
}

// User Menu component
function UserMenu() {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <motion.button
          className="flex items-center space-x-1 rounded-full overflow-hidden border p-1 hover:bg-primary/10 transition-colors"
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <Avatar className="h-6 w-6">
            <img src="https://github.com/shadcn.png" alt="User" />
          </Avatar>
          <ChevronDown className="h-4 w-4 text-muted-foreground" />
        </motion.button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <div className="flex items-center p-2">
          <div className="ml-2 space-y-1">
            <p className="text-sm font-medium">User Name</p>
            <p className="text-xs text-muted-foreground">user@example.com</p>
          </div>
        </div>
        <DropdownMenuSeparator />
        <DropdownMenuItem>Profile</DropdownMenuItem>
        <DropdownMenuItem>Settings</DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem>Log out</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
} 