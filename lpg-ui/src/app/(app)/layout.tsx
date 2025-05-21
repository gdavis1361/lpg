import { MainLayout } from '@/components/layout/MainLayout';
import React from 'react';

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <MainLayout>{children}</MainLayout>;
}
