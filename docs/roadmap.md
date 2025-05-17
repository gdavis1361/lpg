# Chattanooga Prep Relationship-Centered Platform  🚀 Roadmap

> **Workflow-first philosophy:** Ship thin vertical slices that deliver visible relationship value every 2–3 weeks.  Each phase ends with a demo to real users.
>
> **Duration:** 12 weeks (Mon 4 → Fri 12).  Buffer ≈ 15 % already baked in.

| Phase | Calendar | Theme | Demo headline (definition-of-done) |
|-------|----------|-------|------------------------------------|
| 1 | **Wk 1 – 3** | **Foundation** | A logged-in user sees a Responsive Shell + People Directory populated from Supabase and can log an interaction. |
| 2 | **Wk 4 – 6** | **Relationship Core** | Relationship timeline & health badges update live across two browsers when an interaction is created. |
| 3 | **Wk 7 – 9** | **Multi-Role Intelligence** | User can switch roles and watch the dashboard, nav, and search results adapt without reload. |
| 4 | **Wk 10 – 12** | **Relationship Analytics & Mobile** | Network graph + mobile PWA installed on phone; pattern alerts appear based on seeded data. |

---

## 📌 Phase 1 – Foundation (Weeks 1-3)

### Objectives
* Stand-up secure infrastructure & skeletal UI
* Produce live data flows end-to-end (Supabase → Next.js → Tailwind component)

### Key Deliverables
| Category | Task |
|----------|------|
| **Infra** | • Supabase project + `.env.local` secrets  
• Enable `uuid-ossp`, `pgcrypto` extensions  
• Row-level policies on `people` (`SELECT` by auth user only) |
| **Auth** | • Email magic-link login + new-user onboarding  
• Seed roles: *admin*, *mentor*, *donor*, *alumni* |
| **Logging** | • `pino` logger with field-level redaction (`email`, `phone`) |
| **Design System** | • Install **shadcn/ui** primitives: `button`, `card`, `input`, `avatar`, `navigation-menu` |
| **Layout** | • `<AppShell>` component with global nav, role badge, notification bell |
| **Pages** | • `/login`  
• `/dashboard` (placeholder widgets)  
• `/people` list  
• `/people/[id]` core profile |
| **Interaction MVP** | • "Add Interaction" modal writes to `interactions` + `interaction_participants` |
| **Tests** | • Vitest unit tests for `cn`, logger  
• Playwright E2E: login flow, create interaction |

### Exit Criteria
* Lighthouse score ≥ 90 (desktop) for `/dashboard`
* 100 % Type-safe Supabase queries via `supabase-js`
* CI passes: `npm run lint`, `npm run test`, `npm run type-check`

---

## 📌 Phase 2 – Relationship Core (Weeks 4-6)

### Objectives
* Visualize relationship timelines & health
* CRUD for people, organizations, tags

### Key Deliverables
| Category | Task |
|----------|------|
| **UI** | • Timeline component (virtualized list)  
• Health badge (green / amber / red)  
• Relationship card with strength score |
| **Back-end** | • Functions: `calculate_relationship_strength`, `update_updated_at_column`  
• Realtime channels (`supabase.realtime`) for relationship/table events |
| **Domain CRUD** | • Forms + validation (`zod`) for People, Org, Tags |
| **Search** | • Global search bar (`supabase.rpc('person_search')`) |
| **Docs** | • ER diagram (`docs/data-model.svg`) generated via db-diagram.io |

### Exit Criteria
* Creating an interaction updates timeline & health badge in < 5 s on another browser.
* At least 5 Playwright flows: create person → assign tag → log interaction → see timeline.

---

## 📌 Phase 3 – Multi-Role Intelligence (Weeks 7-9)

### Objectives
* Context persistence when switching roles
* Role-aware dashboards & navigation

### Key Deliverables
| Category | Task |
|----------|------|
| **Role Switcher** | • Header dropdown toggles `currentRole` cookie + React context |
| **Dashboards** | • Fundraising, Mentorship, Guidance widgets (same layout, different data) |
| **Cross-role indicators** | • Pill badges on profile (e.g. *Donor • Mentor*) |
| **Search** | • Relationship-centered search results ranking by role |
| **Tests** | • Cypress spec: switch role → nav mutates; search reflects role weighting |

### Exit Criteria
* Switching roles does **not** reload the page; dashboard KPIs change in <1 s.
* 95 % of components are role-agnostic (checked via ESLint rule). 

---

## 📌 Phase 4 – Relationship Analytics & Mobile (Weeks 10-12)

### Objectives
* Deliver first analytics slice (network graph, risk alerts)
* Provide lightweight mobile experience via PWA

### Key Deliverables
| Category | Task |
|----------|------|
| **Analytics UI** | • Relationship network graph (vis-network)  
• At-risk list powered by `identify_at_risk_relationships()`  
• Health trend spark-lines |
| **Notifications** | • Supabase `realtime.broadcast` push → toast via Sonner |
| **Mobile** | • PWA manifest + service worker  
• `/m` route with compact cards & briefs  
• Touch-first nav drawer |
| **Comms** | • Template system (`@react-email`)  
• Scheduled send via Supabase cron |
| **Release Prep** | • Load/perf test (k6)  
• Data backup & migration plan |

### Exit Criteria
* PWA installable on iOS & Android, core flows usable offline.
* Network graph renders < 2 s with 1 k relationships.
* Error budget (Sentry) ≤ 0.1 % over 7-day canary.

---

## 🔍 Monitoring & Metrics
| Metric | Target |
|--------|--------|
| Interaction latency (create → dashboard) | ≤ 5 s |
| Daily Active Mentors / Mentored Students | +20 % month-over-month post-launch |
| Donor repeat-gift rate | +15 % in year 1 |
| Relationship at-risk false-positive rate | < 10 % |
| Lighthouse PWA score | ≥ 85 mobile |

---

## 🛡️ Risk Register
| Risk | Mitigation |
|------|-----------|
| Supabase RLS misconfig exposes data | Automated tests per table + SECURITY.md checklist |
| Relationship timeline perf | Use react-virtual + pagination; avoid N+1 queries via prefetch RPC |
| Role context race conditions | Central `RoleProvider` + React Query `queryKey` partitioning |
| Analytics requires data volume | Seed scripts + staged feature flags until data accrues |

---

## 🗂️ Project Hygiene
* **Monorepo** (pnpm workspaces) if/when we add mobile shell or infra scripts.
* `CONTRIBUTING.md` with 5-line quick-start.
* PR title style: `feat(dashboard): add health badge`.

---

## ✨ MVP Recap
* **Unified People Directory**
* **Multi-Dimensional Profile**
* **Relationship Timeline**
* **Cross-Role Indicators**
* **Interaction Logging**

Delivering these by **Week 6** positions us for user validation before deeper analytics.   

> "Ship something valuable every sprint.  Protect the relationship." – Workflow-First Mantra 