# LPG UI Implementation Todos

## Design Foundation Tasks

- [x] Define heading scale (`text-2xl`, `font-bold`, etc.) in *PageHeader* component
- [x] Decide on base Tailwind palette (e.g., Zinc)
- [x] Add brand color overrides in `globals.css` if needed
- [x] Establish section spacing helpers (e.g., `Section` component)
- [x] Install `lucide-react` with `pnpm add lucide-react`
- [x] Use contrast checker for accessibility
- [x] Test keyboard navigation

## Component Implementation Checklist

- [x] Run shadcn scaffold and add core components
- [x] Create basic `uiConfig.ts` with component mappings
- [x] Create component prop interfaces
- [x] Create custom abstractions (`FormField`, `EmptyState`, etc.)
- [x] Build **Safe** pages using shadcn baseline components
- [x] Commit baseline branch `feat/shadcn-baseline`
- [x] Prototype 1-2 🚀 upgrades (e.g., Wow NavBar) to validate lazy swap & theming
- [x] Create "Wow backlog" for future sprints

## Component-Specific Todos

- [x] `SafeAppShell`: Create custom wrapper supporting optional Parallax/RetroGrid background
- [ ] `NavBar`: Implement standard NavigationMenu with configurable items
- [ ] `Mobile Drawer`: Implement Sheet component for mobile navigation
- [ ] `Command Palette`: Set up CommandDialog for global search
- [ ] `Theme Toggle`: Implement theme switching with Switch component
- [ ] `User Menu`: Create Avatar + DropdownMenu combination
- [ ] `Info Card`: Implement reusable Card component with title and actions
- [ ] `Status Badge`: Create Badge variants for different statuses
- [ ] `Data Table`: Set up Table component with sorting and filtering
- [ ] `Timeline`: Create ScrollArea + virtual list implementation
- [ ] `Modal/Dialog`: Implement standard Dialog component
- [ ] `Toast/Notify`: Set up Sonner for notifications
- [ ] `Progress`: Implement linear Progress component

## Integration Tasks

- [x] Implement lazy loading mechanism in `uiConfig.ts` for swappable components
- [x] Set up environment variable `NEXT_PUBLIC_UI_WOW` for toggling enhanced components
- [x] Create Suspense wrappers for lazy-loaded components
- [ ] Integrate Magic UI components as enhanced alternatives
- [ ] Add 21st Magic components where applicable

## Wow Component Backlog

- [x] Parallax / RetroGrid background (Magic UI) for AppShell
- [x] Custom motion top-bar, Bento Grid header (Magic UI) for NavBar
- [ ] Glass-blur slide-in with framer-motion for Mobile Drawer
- [ ] AI-chat search (21st Magic → *AI Chat*) for Command Palette
- [ ] Shimmer/Rainbow toggle (Magic UI Button) for Theme Toggle
- [ ] Avatar Circles w/ presence (Magic UI) for User Menu
- [ ] Tilt / Warp-background (Magic UI) for Info Card
- [ ] GradientChip (Magic UI) for Status Badge
- [ ] TanStack table w/ row pinning (21st Magic Tables) for Data Table
- [ ] Animated List (Magic UI) for Timeline
- [ ] Hero-Video Dialog (Magic UI) for Modal/Dialog
- [ ] Multi-channel Notification Center (21st Magic) for Toast/Notify
- [ ] Circular / Scroll Progress (Magic UI) for Progress 