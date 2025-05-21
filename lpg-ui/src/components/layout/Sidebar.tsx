"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@lpg-ui/lib/utils";
import { Button } from "@lpg-ui/components/ui/button";
import * as LucideIcons from "lucide-react";

interface NavItem {
  href: string;
  label: string;
  icon: keyof typeof LucideIcons;
}

interface SidebarNavProps {
  items: NavItem[];
}

export function SidebarNav({ items }: SidebarNavProps) {
  const pathname = usePathname();

  return (
    <nav className="flex flex-col gap-1 px-2 py-2">
      {items.map((item) => {
        const IconComponent = LucideIcons[item.icon] || LucideIcons.HelpCircle; // Fallback icon
        return (
          <Link key={item.href} href={item.href} legacyBehavior passHref>
            <Button
              variant={pathname === item.href ? "secondary" : "ghost"}
              className={cn(
                "w-full justify-start",
                pathname === item.href && "font-semibold"
              )}
              asChild
            >
              <a>
                <IconComponent className="mr-2 h-4 w-4" />
                {item.label}
              </a>
            </Button>
          </Link>
        );
      })}
    </nav>
  );
}

interface SidebarSectionProps {
  title: string;
  children: React.ReactNode;
}

export function SidebarSection({ title, children }: SidebarSectionProps) {
  return (
    <div className="py-2">
      <h2 className="mb-2 px-4 text-lg font-semibold tracking-tight">
        {title}
      </h2>
      {children}
    </div>
  );
}

interface SidebarProps {
  children: React.ReactNode;
}

export function Sidebar({ children }: SidebarProps) {
  return (
    <aside className="fixed inset-y-0 left-0 z-10 hidden w-60 flex-col border-r bg-background sm:flex">
      <div className="flex h-16 items-center border-b px-6">
        {/* Placeholder for Logo or App Name */}
        <Link href="/dashboard" className="text-lg font-semibold">
          LPG Platform
        </Link>
      </div>
      <div className="flex-1 overflow-y-auto">
        {children}
      </div>
    </aside>
  );
}
