import React from 'react';
import { Sidebar, SidebarNav, SidebarSection } from "./Sidebar";
import { Header, HeaderActions, UserMenu } from "./Header";
import { MainContent } from "./MainContent";

interface MainLayoutProps {
  children: React.ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  const mainNavItems = [
    { href: "/dashboard", label: "Dashboard", icon: "Home" as const },
    { href: "/people", label: "People", icon: "Users" as const }
  ];

  const relationshipNavItems = [
    { href: "/people?filter=donor", label: "Donors", icon: "Heart" as const },
    { href: "/people?filter=mentor", label: "Mentors", icon: "Briefcase" as const },
    { href: "/people?filter=alumni", label: "Alumni", icon: "GraduationCap" as const }
  ];

  return (
    <div className="relative flex min-h-screen w-full bg-muted/40">
      <Sidebar>
        <SidebarSection title="Main">
          <SidebarNav items={mainNavItems} />
        </SidebarSection>
        <SidebarSection title="Relationships">
          <SidebarNav items={relationshipNavItems} />
        </SidebarSection>
      </Sidebar>
      
      <div className="flex flex-1 flex-col sm:pl-60"> {/* Adjusted: sm:pl-60 to account for fixed sidebar of w-60. Removed gap and py for direct children control */}
        <Header>
          <HeaderActions>
            {/* Add other header actions here if needed, e.g., Bell icon for notifications */}
            <UserMenu />
          </HeaderActions>
        </Header>
        <MainContent>{children}</MainContent>
      </div>
    </div>
  );
}
