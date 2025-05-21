import React from 'react';

interface MainContentProps {
  children: React.ReactNode;
}

export function MainContent({ children }: MainContentProps) {
  return (
    <main className="flex flex-1 flex-col gap-4 p-4 md:gap-8 md:p-8 min-h-[calc(100vh-4rem)]"> {/* Adjusted: Removed ml-0 sm:ml-60 as parent handles padding, added min-height */}
      {children}
    </main>
  );
}
