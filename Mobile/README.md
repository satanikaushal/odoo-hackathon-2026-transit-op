# TransitOps Mobile

Flutter client for **TransitOps** — a smart transport operations platform built for the Odoo Hackathon 2026. The app gives fleet operators, dispatchers, safety officers, and finance teams a single place to monitor KPIs, manage vehicles and drivers, run trips, track maintenance, and control fuel and operational costs.

This repository is the **mobile / cross-platform client**. The REST API lives in [`../Backend`](../Backend).

---

## What the app covers

| Module | Capabilities |
|--------|----------------|
| **Dashboard** | Live KPIs with vehicle type, region, and status filters |
| **Fleet** | Vehicle list/detail, status updates, operational cost breakdown (`GET /vehicles/:id/costs`) |
| **Drivers** | Driver profiles, license info, status management |
| **Trips** | Create, dispatch, complete, and cancel trips with lifecycle tracking |
| **Maintenance** | Open and close maintenance logs tied to vehicles |
| **Fuel & Expenses** | Tabbed hub for fuel logs and expense records with role-aware create access |
| **Analytics** | Fleet utilization, fuel efficiency, operational cost, and vehicle ROI reports with CSV export |
| **Settings** | Account info, theme (System / Light / Dark), sign out |

All modules talk to the backend over a consistent JSON envelope (`success`, `message`, `data`) and paginated list endpoints where applicable.

---

## Role-based access (RBAC)

Access is enforced at **three layers** on the client:

1. **Route guards** — `go_router` redirects unauthorized paths to `/unauthorized`
2. **Navigation** — sidebar / drawer items are filtered per role via `RoleAccess`
3. **UI actions** — create/edit FABs and detail actions use per-module permission extensions

| Role | Primary experience |
|------|--------------------|
| **Admin** | Full access to every module |
| **Fleet Manager** | Fleet, maintenance, fuel & expenses |
| **Driver** (dispatcher persona) | Dashboard, trips, fuel log creation |
| **Safety Officer** | Driver management |
| **Financial Analyst** | Expenses and analytics |

The backend remains the source of truth for authorization; the mobile app mirrors expected access so users only see what they can use.

---

## Tech stack

- **Flutter** (Dart 3.11+) — iOS, Android, and desktop-friendly layout
- **Riverpod** — state management and dependency wiring
- **go_router** — declarative routing with auth redirects
- **Dio** — HTTP client with token refresh, retry, and envelope parsing
- **GetIt** — service locator for repositories and Firebase services
- **flutter_secure_storage** — access/refresh token persistence
- **Firebase** — Crashlytics, Analytics, and FCM (device token sent at login)

---

## Architecture

The codebase follows a **feature-first** layout under `lib/features/`:

```
lib/
├── core/           # Router, theme, DI, network, Firebase, env config
├── features/       # One folder per domain (auth, fleet, trips, …)
│   └── <feature>/
│       ├── application/   # Riverpod notifiers / providers
│       ├── data/          # Repositories (Dio + ApiEnvelope)
│       ├── domain/        # Models, formatters, permissions
│       └── presentation/  # Screens and widgets
└── shared/         # Reusable UI, responsive helpers, user role model
```

**Design choices worth noting for reviewers:**

- **Responsive shell** — persistent sidebar on wide screens (≥840px), drawer on phones; list screens switch between cards and data tables at the same breakpoint.
- **Pull-to-refresh** on listing screens only; detail and form screens rely on explicit refresh signals from related actions.
- **Opaque sub-route scaffold** — nested flows (add/edit/detail) render above the shell without losing navigation context.
- **Token refresh** — access tokens are refreshed proactively using server-provided expiry; 401s trigger a single retry then sign-out.
- **Refresh signals** — cross-module invalidation (e.g. fuel log created → vehicle operational cost card refreshes).

---

## Prerequisites

- Flutter SDK compatible with `sdk: ^3.11.0` (see `pubspec.yaml`)
- A running TransitOps backend (local or dev tunnel)
- For push notifications on device: Firebase project configured (`firebase_options.dart`, platform configs)

---

## Setup & run

```bash
cd Mobile
flutter pub get
flutter run
```

### API environment

The active environment is set in `lib/main.dart`:

```dart
AppEnvironment.setUp(Env.DEV); // DEV | STAGING | PRODUCTION
```

| Environment | Base URL |
|-------------|----------|
| **DEV** | `https://rnhnrsg9-3001.inc1.devtunnels.ms/api` |
| **STAGING** | `https://staging-api.transitops.in/api` |
| **PRODUCTION** | `https://api.transitops.in/api` |

Point `Env.DEV` at your local backend by editing `lib/core/config/app_environment.dart`.

### Demo accounts

Users are seeded by the backend — there is no self-service signup:

```bash
cd ../Backend
docker compose up -d
bun run db:migrate
bun run db:seed   # prints one-time passwords to the console
```

Seeded emails (passwords from seed output):

- `admin@transitops.dev`
- `fleet.manager@transitops.dev`
- `dispatcher@transitops.dev`
- `safety.officer@transitops.dev`
- `financial.analyst@transitops.dev`

---

## Quality checks

```bash
flutter analyze
flutter test
```

---

## Backend & API docs

- [Backend README](../Backend/README.md) — database, migrations, run commands
- [API reference](../Backend/docs/api.md) — endpoints and response shapes
- [Auth & RBAC](../Backend/docs/auth.md) — JWT rotation and role model

---

## Known scope notes

These are intentional or backend-driven limits, not mobile bugs:

- Fuel logs and expenses are **append-only** (no edit/delete in API)
- Dashboard API exposes **KPIs + filters** only (no embedded trip/chart payloads)
- Settings are **client-side** (theme, sign out); no `/api/settings` on backend
- CSV export uses the platform share sheet on mobile and a save dialog on desktop

---

## Hackathon submission highlights

- **End-to-end fleet ops** — not just CRUD: trip dispatch/complete flows, maintenance lifecycle, and per-vehicle cost aggregation
- **Production-minded mobile patterns** — secure token storage, refresh rotation, envelope error handling, shimmer loading, pagination + infinite scroll
- **Role-aware UX** — each persona gets a focused nav and action set instead of a one-size-fits-all admin panel
- **Cross-form-factor** — same codebase targets phone and wider layouts with adaptive navigation and tables
- **Observable in production** — Firebase Crashlytics and Analytics wired from app start

Built for **Odoo Hackathon 2026 · Transit Operations**.
