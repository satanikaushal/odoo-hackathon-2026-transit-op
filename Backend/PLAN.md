# TransitOps Backend — Implementation Plan

Source: `TransitOps Smart Transport Operations Platform.pdf` (hackathon brief).
This is a build plan for the backend only (Express + TypeScript on Bun, per
the stack already scaffolded in `src/`).

## 1. Tech stack decisions

| Concern | Choice | Why |
|---|---|---|
| Runtime | Bun | already the project runtime |
| HTTP framework | Express 5 | already scaffolded (`src/app.ts`) |
| Validation | Zod | already scaffolded (`src/middleware/validate.ts`) |
| Logging | pino / pino-http | already scaffolded |
| Database | PostgreSQL | relational data with many FKs (vehicle↔trip↔driver↔maintenance↔fuel); needs real transactions for the status-transition rules |
| ORM | Prisma | fastest path to migrations + type-safe client for an 8-hour build; alternative: Drizzle (lighter, no codegen) if the team prefers Bun-native `Bun.sql` |
| Password hashing | `Bun.password` (built-in, Argon2id) | native, no extra dependency |
| Auth tokens | JWT via `jsonwebtoken` (or `jose`) — short-lived access token + longer-lived refresh token | stateless, works for both a future web client and the Flutter mobile app (no cookie dependency) |
| Scheduled jobs (bonus) | `node-cron` | license-expiry email reminders |
| Email (bonus) | `nodemailer` (SMTP) or `resend` | license-expiry reminders |
| CSV export | `csv-stringify` (or hand-rolled, it's a mandatory feature so keep it dependency-light) | |
| PDF export (bonus) | `pdfkit` | |

**Assumption**: no DB is provisioned yet — Phase 0 sets one up. If you'd rather avoid running a Postgres instance during the hackathon, SQLite via Prisma is a drop-in fallback (`provider = "sqlite"`), swappable later with zero code changes outside `schema.prisma`.

## 2. Naming clarification (read this before coding)

The brief overloads the word "Driver":

- **Target user "Driver"** (§2) — an app *role* that "creates trips, assigns vehicles and drivers, monitors active deliveries." This is functionally a dispatcher permission, not a person driving.
- **Driver Management entity** (§3.4) — an operational *profile* (name, license, safety score) that gets assigned to a trip. Does **not** necessarily have a login.

Plan keeps the role name `DRIVER` (matches the brief's wording exactly, for grading fidelity) but treat it internally as "dispatcher permissions." The `Driver` **entity** is a separate table with no auth relationship to `User`. Flag this to the team early so frontend and backend agree.

Second gap: the ROI formula (§3.8) needs a `Revenue` figure that no entity in §6 provides. Plan adds a `revenue` field on `Trip` (entered on completion) and sums it per vehicle for the ROI report. Flag as an assumption to confirm with stakeholders/judges if possible.

## 3. Data model

Enums:
- `Role`: `FLEET_MANAGER | DRIVER | SAFETY_OFFICER | FINANCIAL_ANALYST | ADMIN`
- `VehicleStatus`: `AVAILABLE | ON_TRIP | IN_SHOP | RETIRED`
- `DriverStatus`: `AVAILABLE | ON_TRIP | OFF_DUTY | SUSPENDED`
- `TripStatus`: `DRAFT | DISPATCHED | COMPLETED | CANCELLED`
- `MaintenanceStatus`: `OPEN | CLOSED`
- `ExpenseCategory`: `TOLL | MAINTENANCE | MISC` (fuel is its own table, not an expense row)

Entities:

```
User
  id, name, email (unique), passwordHash, role, isActive, createdAt, updatedAt

RefreshToken               // enables logout / token revocation
  id, userId (FK), tokenHash, expiresAt, createdAt, revokedAt?

Vehicle
  id, registrationNumber (unique), name, type, maxLoadCapacity,
  odometer, acquisitionCost, status, region, createdAt, updatedAt

Driver
  id, name, licenseNumber (unique), licenseCategory, licenseExpiryDate,
  contactNumber, safetyScore, status, createdAt, updatedAt

Trip
  id, source, destination, vehicleId (FK), driverId (FK), cargoWeight,
  plannedDistance, actualDistance?, finalOdometer?, fuelConsumed?,
  revenue? (see §2 assumption), status,
  createdById (FK -> User), dispatchedAt?, completedAt?, cancelledAt?,
  createdAt, updatedAt

MaintenanceLog
  id, vehicleId (FK), description, cost, status, openedAt, closedAt?,
  createdAt

FuelLog
  id, vehicleId (FK), tripId? (FK), liters, cost, date, createdAt

Expense
  id, vehicleId (FK), tripId? (FK), category, amount, date, description,
  createdAt
```

Indexes: unique on `Vehicle.registrationNumber`, `Driver.licenseNumber`, `User.email`. Index `Trip.status`, `Vehicle.status`, `Driver.status` — the dashboard and dispatch-eligibility queries filter on these constantly.

## 4. Business rules → where they're enforced

All of §4 in the brief maps to **service-layer** functions (never controller-level, so rules are testable and reused by both REST handlers and future workers). Wrap every multi-row status change in a Prisma `$transaction`.

| Rule | Enforcement point |
|---|---|
| Vehicle registration number unique | DB unique constraint + friendly 409 from service |
| Retired/In Shop vehicles excluded from dispatch | `vehicle.service.listAvailableForDispatch()` filters `status = AVAILABLE`; trip-creation validates selected vehicle's current status server-side (don't trust client) |
| Expired-license / Suspended drivers can't be assigned | `trip.service.createTrip()` checks `licenseExpiryDate > now` and `status = AVAILABLE` |
| On-Trip driver/vehicle can't be double-booked | same check, inside a transaction to avoid race conditions |
| Cargo weight ≤ max load capacity | Zod schema does shape validation only; the *cross-field* check (against the vehicle's stored capacity) happens in the service, since it needs a DB read |
| Dispatch → both go `ON_TRIP` | `trip.service.dispatch(tripId)` transaction: update trip.status, vehicle.status, driver.status together |
| Complete → both go back `AVAILABLE` | `trip.service.complete(tripId, {finalOdometer, fuelConsumed, revenue})` transaction; also writes odometer back to `Vehicle.odometer` |
| Cancel dispatched trip → both restored | `trip.service.cancel(tripId)` transaction, only legal from `DISPATCHED` (cancelling a `DRAFT` trip doesn't need to touch vehicle/driver status since they were never flipped) |
| Open maintenance → vehicle `IN_SHOP` | `maintenance.service.create()` sets vehicle status in the same transaction |
| Close maintenance → vehicle `AVAILABLE` unless retired | `maintenance.service.close()` transaction; skip the status flip if vehicle was independently marked `RETIRED` |

## 5. API surface

All routes under `/api`, JSON in/out, `Authorization: Bearer <token>` required except `/auth/login`.

```
POST   /auth/login                     -> { accessToken, refreshToken, user }
POST   /auth/refresh                   -> { accessToken }
POST   /auth/logout                    -> revoke refresh token
GET    /auth/me                        -> current user profile
POST   /users                          -> create user (ADMIN only; no public signup per brief)
GET    /users                          -> list users (ADMIN)
PATCH  /users/:id/role                 -> change role (ADMIN)

GET    /vehicles          ?type=&status=&region=&q=
POST   /vehicles
GET    /vehicles/:id
PATCH  /vehicles/:id
DELETE /vehicles/:id                   -> soft-delete / set RETIRED, not a hard delete
GET    /vehicles/available-for-dispatch

GET    /drivers           ?status=&q=
POST   /drivers
GET    /drivers/:id
PATCH  /drivers/:id
DELETE /drivers/:id

GET    /trips             ?status=&vehicleId=&driverId=
POST   /trips                          -> creates in DRAFT
GET    /trips/:id
POST   /trips/:id/dispatch
POST   /trips/:id/complete             -> body: finalOdometer, fuelConsumed, revenue?
POST   /trips/:id/cancel

GET    /maintenance       ?vehicleId=&status=
POST   /maintenance                    -> opens a record, flips vehicle to IN_SHOP
POST   /maintenance/:id/close

GET    /fuel-logs         ?vehicleId=
POST   /fuel-logs
GET    /expenses          ?vehicleId=&category=
POST   /expenses

GET    /dashboard/kpis    ?type=&status=&region=
GET    /reports/fuel-efficiency
GET    /reports/fleet-utilization
GET    /reports/operational-cost
GET    /reports/vehicle-roi
GET    /reports/export.csv?report=<name>
```

## 6. RBAC matrix

| Module | FLEET_MANAGER | DRIVER (dispatcher) | SAFETY_OFFICER | FINANCIAL_ANALYST | ADMIN |
|---|---|---|---|---|---|
| Vehicles CRUD | full | read | read | read | full |
| Drivers CRUD | full | read | full (compliance fields) | read | full |
| Trips (create/dispatch/complete/cancel) | full | full | read | read | full |
| Maintenance | full | – | read | read | full |
| Fuel & Expenses | full | log fuel on own trips | – | read | full |
| Dashboard | full | full | full | full | full |
| Reports/export | full | – | read (safety-relevant) | full | full |
| Users/roles | – | – | – | – | full |

Implement as a single `requireRole(...roles)` Express middleware (`src/middleware/authorize.ts`) rather than per-route ad-hoc checks.

## 7. Step-by-step build order

### Phase 0 — Foundations ✅ done
1. Added Prisma 7 (`prisma`, `@prisma/client`) plus the Postgres driver adapter it now requires (`@prisma/adapter-pg`, `pg`) — Prisma 7's generated client has no built-in engine binary, `PrismaClient` must be constructed with an `adapter`.
2. `prisma/schema.prisma` written per §3 (see file — all 8 entities + enums).
3. DB: no Docker/Postgres install available in this environment, so used `bunx prisma dev --detach` (Prisma's embedded local Postgres, no Docker needed). Its default `prisma+postgres://` proxy URL didn't reliably support `migrate dev` here, so `DATABASE_URL`/`SHADOW_DATABASE_URL` in `.env` point at the **raw TCP** URLs it prints instead. Real migrations are set up: `prisma/migrations/20260712051431_init` is the baseline (generated via `prisma migrate diff` + `prisma migrate resolve --applied`, since the schema had already been pushed once with `db push` while diagnosing the proxy issue), and `bun run db:migrate` (`prisma migrate dev`) works normally for schema changes from here on — verified with a real follow-up migration. `db:push` stays available as a fallback if the shadow DB flakes again.
4. `src/lib/prisma.ts` — singleton `PrismaClient` wired with `PrismaPg` adapter (avoids multiple instances under `--hot`).
5. `src/config/env.ts` extended with `DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, token TTLs (fails fast if missing).
6. `prisma/seed.ts`: one user per role (`ADMIN`, `FLEET_MANAGER`, `DRIVER`, `SAFETY_OFFICER`, `FINANCIAL_ANALYST`), password `Password123!` via `Bun.password.hash`. Run with `bun run db:seed`.
7. `package.json` scripts: `db:push`, `db:generate`, `db:seed`, `db:studio`. See `README.md` for the day-to-day DB commands.

### Phase 1 — Auth & RBAC ✅ mostly done (login/refresh/logout/me + middleware)
1. ✅ `src/schemas/auth.schema.ts` — login body (`loginSchema`) and refresh/logout body (`refreshSchema`).
2. ✅ `src/services/auth.service.ts` — verifies password (`Bun.password.verify`), issues access JWT (`src/lib/jwt.ts`, 15m default) + opaque refresh token (`src/lib/refreshToken.ts`, sha256-hashed before storing in `RefreshToken`). Refresh **rotates**: each use revokes the old token row and issues a new pair; reuse of a spent/revoked/expired token is rejected.
3. ✅ `src/controllers/auth.controller.ts` + `src/routes/auth.routes.ts` — `POST /api/auth/login`, `POST /api/auth/refresh`, `POST /api/auth/logout`, `GET /api/auth/me`.
4. ✅ `src/middleware/authenticate.ts` — verifies the bearer access token, attaches `req.user = { sub, role }`.
5. ✅ `src/middleware/authorize.ts` — `authorize(...roles: Role[])`, checks `req.user.role`.
6. Not wired globally in `app.ts` yet — only `/auth/me` uses `authenticate` so far, since it's the only protected route so far. Once Phase 2+ resource routers exist, mount them after `authenticate` at the `/api` level (or apply `authenticate`/`authorize` per-router) rather than exempting individual auth routes from a blanket global middleware.
7. Still pending: `src/controllers/user.controller.ts` for admin user management (create/list/change role) — deferred, `prisma/seed.ts` covers initial users for now (one per role, random password printed once at seed time via `Bun.password.hash`, never stored in plaintext or committed).

### Phase 2 — Vehicle Registry
1. `src/schemas/vehicle.schema.ts` (create/update/query-filter schemas).
2. `src/services/vehicle.service.ts` — CRUD + `listAvailableForDispatch()` + unique-registration-number handling (catch Prisma P2002 → 409).
3. `src/controllers/vehicle.controller.ts`, `src/routes/vehicle.routes.ts`.
4. Enforce RBAC per §6.

### Phase 3 — Driver Management
1. `src/schemas/driver.schema.ts`.
2. `src/services/driver.service.ts` — CRUD; license-expiry check helper reused by Trip service.
3. Controller + routes, mirroring Phase 2.

### Phase 4 — Trip Management (core state machine)
1. `src/schemas/trip.schema.ts` — create, dispatch (no body), complete (`finalOdometer`, `fuelConsumed`, `revenue?`), cancel.
2. `src/services/trip.service.ts`:
   - `create()`: validate vehicle/driver exist & `AVAILABLE`, license not expired, cargo ≤ capacity → insert `DRAFT`.
   - `dispatch()`: transaction, re-check availability at commit time (race protection), flip trip/vehicle/driver.
   - `complete()`: transaction, flip vehicle/driver back to `AVAILABLE`, write `finalOdometer` onto `Vehicle.odometer`, store `fuelConsumed`/`revenue` on trip.
   - `cancel()`: transaction, only from `DISPATCHED` (or `DRAFT` with no side effects to undo).
3. Controller + routes.
4. Unit-test the state machine specifically (`bun test`) — this is the module graders will poke hardest.

### Phase 5 — Maintenance workflow
1. `src/schemas/maintenance.schema.ts`.
2. `src/services/maintenance.service.ts` — `create()` sets vehicle `IN_SHOP` in a transaction; guard against opening maintenance on a vehicle that's `ON_TRIP`; `close()` restores `AVAILABLE` unless vehicle is `RETIRED`.
3. Controller + routes.

### Phase 6 — Fuel & Expense tracking
1. `src/schemas/fuelLog.schema.ts`, `src/schemas/expense.schema.ts`.
2. `src/services/fuelLog.service.ts`, `src/services/expense.service.ts` — plain CRUD, scoped by `vehicleId`/`tripId`.
3. `src/services/cost.service.ts` — shared helper: `totalOperationalCost(vehicleId)` = sum(fuel.cost) + sum(maintenance.cost). Used by both Fuel/Expense responses and Reports.
4. Controllers + routes.

### Phase 7 — Dashboard KPIs
1. `src/services/dashboard.service.ts` — single aggregate query (or a few parallel ones) for: active vehicles, available vehicles, in-maintenance, active trips, pending (draft) trips, drivers on duty, fleet utilization % (`ON_TRIP vehicles / total non-retired vehicles`).
2. Accept `type`/`status`/`region` query filters, applied consistently to the underlying vehicle/trip counts.
3. Controller + route (`GET /dashboard/kpis`).

### Phase 8 — Reports & analytics
1. `src/services/report.service.ts`:
   - Fuel efficiency = `sum(trip.actualDistance or plannedDistance) / sum(fuelLog.liters)` per vehicle.
   - Fleet utilization (reuse dashboard logic, exposed as its own report too).
   - Operational cost = `cost.service.totalOperationalCost()` per vehicle.
   - Vehicle ROI = `(sum(trip.revenue) - (maintenanceCost + fuelCost)) / acquisitionCost`.
2. `GET /reports/export.csv?report=<name>` — stream CSV using `csv-stringify`; reuse the same service functions the JSON endpoints call (single source of truth, not a separate query path).
3. Controller + routes.

### Phase 9 — Hardening & cross-cutting
1. Ensure every mutating endpoint runs its multi-table writes inside `prisma.$transaction`.
2. Centralize Prisma error → `ApiError` mapping in `errorHandler.ts` (P2002 unique, P2025 not-found, etc.) instead of scattering `try/catch` in every service.
3. Pagination (`page`/`pageSize`) on all list endpoints — brief implies growing tables (trips/logs).
4. `bun test` coverage for: RBAC denial, trip state machine (happy path + every rule in §4), maintenance status side-effects, ROI/fuel-efficiency math.

### Phase 10 — Bonus features (time-permitting, in priority order)
1. **Search/filter/sort** — extend list-endpoint query schemas (`q`, `sortBy`, `sortDir`) — cheap, high value, do this before the flashier bonuses.
2. **License-expiry email reminders** — `node-cron` job (daily) scanning `Driver.licenseExpiryDate` within N days, `nodemailer`/`resend` to send. Put the cron bootstrap in its own `src/jobs/licenseReminder.job.ts`, started from `index.ts`, not buried in `app.ts`.
3. **PDF export** — mirror the CSV export path with `pdfkit`, same report-service functions.
4. **Vehicle document management** — new `VehicleDocument` entity (vehicleId, type, fileUrl, expiryDate?) + file upload (local disk for hackathon speed, or S3-compatible if time allows).
5. Charts/dark mode are frontend concerns, not backend — no action needed here beyond exposing the data the frontend needs (already covered by Phases 7–8).

## 8. Open questions to confirm with the team/judges

- Is `revenue` actually meant to live on `Trip`, or is there a separate invoicing concept we're missing? (needed for ROI, §3.8)
- Does "Driver" as a *login role* need its own account, or do Fleet Managers create trips on drivers' behalf? Affects whether `Driver` entities ever need `User` accounts.
- Any multi-tenancy requirement ("region" in filters suggests multiple sites) — single-org assumption for now.
