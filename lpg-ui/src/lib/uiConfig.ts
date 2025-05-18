import React from 'react';
import { NavigationMenu } from "@/components/ui/navigation-menu";
import { Sheet } from "@/components/ui/sheet";
import { CommandDialog } from "@/components/ui/command";
import { Switch } from "@/components/ui/switch";
import { Avatar } from "@/components/ui/avatar";
import { DropdownMenu } from "@/components/ui/dropdown-menu";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Table } from "@/components/ui/table";
import { Dialog } from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Toaster } from "@/components/ui/sonner";
import { Button } from "@/components/ui/button";
import { SafeAppShell } from "@/components/SafeAppShell";

// Import custom components
import { FormField, EmptyState, PageHeader, ConfirmationModal, Section } from "@/components/custom";

// Environment variable to toggle enhanced components
const IS_WOW_ENABLED = process.env.NEXT_PUBLIC_UI_WOW === 'true';

// Lazy-loaded wow components
const WowNavBar = React.lazy(() => import('@/components/custom/wow/WowNavBar'));
const WowRetroGridBackground = React.lazy(() => import('@/components/custom/wow/WowRetroGridBackground'));
const WowButton = React.lazy(() => import('@/components/custom/wow/WowButton').then(mod => ({ default: mod.WowButton })));

export const ui = {
  // Layout stays custom
  AppShell: SafeAppShell,

  // Pure-shadcn defaults (with wow alternatives where available)
  NavBar: IS_WOW_ENABLED ? WowNavBar : NavigationMenu,
  MobileDrawer: Sheet,
  CommandPalette: CommandDialog,
  ThemeToggle: Switch,
  UserAvatarMenu: DropdownMenu,
  InfoCard: Card,
  StatusBadge: Badge,
  DataTable: Table,
  Modal: Dialog,
  TimelineWrapper: ScrollArea,
  ToastProvider: Toaster,
  Button: IS_WOW_ENABLED ? WowButton : Button,
  
  // Background effects
  RetroGridBackground: IS_WOW_ENABLED ? WowRetroGridBackground : () => null,

  // Custom components
  FormField,
  EmptyState,
  PageHeader,
  ConfirmationModal,
  Section,
}; 