# API Reference

Quick reference for every endpoint that exists today: method, path, auth
requirement, request body, and response shape. For the auth *system* itself
(tokens, rotation, RBAC internals) see [`auth.md`](./auth.md) — this doc is
just "what do I send, what do I get back."

This file only documents what's actually implemented. Drivers, trips,
maintenance, and the dashboard are built but not yet documented here; see
`../PLAN.md` for the full roadmap. Update this file as each phase lands; don't
let it drift from the code.

## Conventions

**Base URL**: `http://localhost:3000` in dev (`PORT` env var).

**Every response is JSON**, wrapped in one of two envelopes:

```json
// success (2xx)
{ "success": true, "message": "OK", "data": { ... } }

// error (4xx/5xx)
{ "success": false, "message": "...", "details": { ... } }
```

`details` is present on validation errors (see below) and omitted (`null`)
otherwise. A `204 No Content` response (e.g. logout) has no body at all.

**Auth header**, on every endpoint marked 🔒 below:

```
Authorization: Bearer <accessToken>
```

**Validation errors** — any endpoint with a request body/params validates it
with zod before the controller runs. On failure you get `400` with
field-level detail:

```json
{
  "success": false,
  "message": "Invalid body",
  "details": {
    "formErrors": [],
    "fieldErrors": { "email": ["Invalid email address"] }
  }
}
```

**Common error status codes** (thrown as `ApiError` from `src/lib/ApiError.ts`,
formatted by `src/middleware/errorHandler.ts`):

| Status | Meaning | Example |
|---|---|---|
| 400 | Bad request / validation failure | malformed body, wrong types |
| 401 | Missing/invalid/expired credentials | no bearer token, wrong password |
| 403 | Authenticated but not permitted | wrong role for this action |
| 404 | Not found | unknown route, missing resource |
| 409 | Conflict | duplicate unique field (planned, e.g. vehicle registration number) |
| 500 | Unhandled server error | logged server-side, message is generic — never leaks internals |

Any request to a route that doesn't exist gets a `404` in the envelope shape
above (`src/middleware/notFound.ts`), not Express's default HTML 404 page.

---

## Health

### `GET /health`

No auth. Liveness/readiness check.

**Response 200**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "status": "ok",
    "uptime": 123.456,
    "timestamp": "2026-07-12T05:24:43.814Z"
  }
}
```

---

## Auth (`/api/auth`)

Full behavioral detail (token lifetimes, rotation, revocation) is in
[`auth.md`](./auth.md). Request/response bodies:

### `POST /api/auth/login`

No auth.

| Field | Type | Required |
|---|---|---|
| `email` | string, valid email | yes |
| `password` | string, non-empty | yes |
| `deviceType` | `"ANDROID"` \| `"IOS"` | only if `deviceToken` is set |
| `deviceToken` | string, non-empty (FCM push token) | only if `deviceType` is set |

`deviceType`/`deviceToken` are optional but must be given together — omit
both for a session with no push notifications, or send both to register this
login for push (e.g. from the Flutter app). A `400` is returned if only one
of the two is present.

```json
// Request
{
  "email": "admin@transitops.dev",
  "password": "...",
  "deviceType": "ANDROID",
  "deviceToken": "fcm-token-abc123"
}
```

**Response 200**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "accessTokenExpiresAt": "2026-07-12T06:11:09.000Z",
    "refreshToken": "5c2e89cd...",
    "refreshTokenExpiresAt": "2026-07-19T05:56:09.844Z",
    "user": {
      "id": "cmrhcmxt10000ntpb9nn55x6l",
      "name": "Admin",
      "email": "admin@transitops.dev",
      "role": "ADMIN"
    }
  }
}
```

`accessTokenExpiresAt`/`refreshTokenExpiresAt` are ISO 8601 timestamps —
use them to know when to call `/refresh` rather than guessing from the
`JWT_ACCESS_TTL`/`JWT_REFRESH_TTL_DAYS` config.

**401** `"Invalid email or password"` — wrong password, unknown email, or
deactivated account (same message for all three, on purpose).

### `POST /api/auth/refresh`

No auth (the refresh token itself is the credential).

| Field | Type | Required |
|---|---|---|
| `refreshToken` | string, non-empty | yes |

No need to resend `deviceType`/`deviceToken` here — whatever was registered
at login carries over automatically to the new refresh token.

```json
// Request
{ "refreshToken": "5c2e89cd..." }
```

**Response 200**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "accessTokenExpiresAt": "2026-07-12T06:11:18.000Z",
    "refreshToken": "16ff0598...",
    "refreshTokenExpiresAt": "2026-07-19T05:56:18.545Z"
  }
}
```

Note: the `refreshToken` you get back is a **new** one — the one you sent is
revoked as part of this call. Store the new value (and its new expiry) and
discard the old one.

**401** `"Invalid or expired refresh token"` — unknown, already-used, expired,
or belongs to a deactivated user.

### `POST /api/auth/logout`

No auth (same as refresh — the token is the credential).

| Field | Type | Required |
|---|---|---|
| `refreshToken` | string, non-empty | yes |

```json
// Request
{ "refreshToken": "5c2e89cd..." }
```

**Response**: `204 No Content`, whether or not the token was valid (doesn't
reveal which).

### `GET /api/auth/me` 🔒

Requires a valid access token. Re-reads the user from the DB (not just the
JWT payload).

**Response 200**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "cmrhcmxt10000ntpb9nn55x6l",
    "name": "Admin",
    "email": "admin@transitops.dev",
    "role": "ADMIN",
    "isActive": true,
    "createdAt": "2026-07-12T05:24:43.814Z"
  }
}
```

**401** — missing/invalid/expired access token, or the account was
deactivated since the token was issued.

---

## Vehicles (`/api/vehicles`)

The fleet's master vehicle list (brief §3.3). Full behavioral detail — status
lifecycle, registration-number normalization, why deletes are blocked — is in
[`vehicles.md`](./vehicles.md). Every endpoint requires a bearer token 🔒;
writes require the `ADMIN` or `FLEET_MANAGER` role.

**Vehicle object** (returned by every read and after create/update):

```json
{
  "id": "cmrh...",
  "registrationNumber": "MH12AB1234",
  "name": "Tata Ace",
  "type": "Truck",
  "maxLoadCapacity": 1000,
  "odometer": 0,
  "acquisitionCost": "550000.50",
  "status": "AVAILABLE",
  "region": "West",
  "createdAt": "2026-07-12T05:24:43.814Z",
  "updatedAt": "2026-07-12T05:24:43.814Z"
}
```

`status` is one of `AVAILABLE` \| `ON_TRIP` \| `IN_SHOP` \| `RETIRED`.
`acquisitionCost` is a **string** (a `Decimal(12,2)`, string-encoded to keep
precision). `registrationNumber` is always uppercase.

### `GET /api/vehicles` 🔒

List with optional filters + pagination. All query params optional.

| Param | Type | Default | Notes |
|---|---|---|---|
| `status` | status enum | — | exact match |
| `type` | string | — | exact match |
| `region` | string | — | exact match |
| `search` | string | — | case-insensitive substring of registration number or name |
| `page` | int ≥ 1 | `1` | |
| `limit` | int 1–100 | `20` | |

**Response 200** — `data` is `{ items: Vehicle[], pagination }`:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [ /* Vehicle objects */ ],
    "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
  }
}
```

### `GET /api/vehicles/available-for-dispatch` 🔒

The dispatch selection pool: `data` is an array of every `AVAILABLE` vehicle
(ordered by registration number), unpaginated since it backs a picker.
`IN_SHOP` / `ON_TRIP` / `RETIRED` vehicles are excluded.

### `GET /api/vehicles/:id` 🔒

`data` is the Vehicle object. **404** `"Vehicle not found"` if unknown.

### `GET /api/vehicles/:id/costs` 🔒

Total operational cost for one vehicle (§3.7). `data`:

```json
{
  "vehicleId": "clx...",
  "fuelCost": 12500.75,
  "maintenanceCost": 8000,
  "operationalCost": 20500.75
}
```

`operationalCost = fuelCost + maintenanceCost` (tolls/misc expenses are tracked
separately and deliberately excluded — see the Fuel & Expenses section).
**404** `"Vehicle not found"` if unknown.

### `POST /api/vehicles` 🔒 ADMIN / FLEET_MANAGER

| Field | Type | Required |
|---|---|---|
| `registrationNumber` | string (unique, uppercased) | yes |
| `name` | string | yes |
| `type` | string | yes |
| `maxLoadCapacity` | number > 0 | yes |
| `acquisitionCost` | number/string ≥ 0 | yes |
| `odometer` | number ≥ 0 (default `0`) | no |
| `status` | status enum (default `AVAILABLE`) | no |
| `region` | string | no |

```json
// Request
{
  "registrationNumber": "MH12AB1234",
  "name": "Tata Ace",
  "type": "Truck",
  "maxLoadCapacity": 1000,
  "acquisitionCost": "550000.50",
  "region": "West"
}
```

**201** `"Vehicle created"`, `data` is the created Vehicle.
**409** on a duplicate registration number.

### `PATCH /api/vehicles/:id` 🔒 ADMIN / FLEET_MANAGER

Partial update — any subset of the create fields (at least one required;
empty body is `400`). `region` accepts `null` to clear it. **200**
`"Vehicle updated"`. **404** if unknown, **409** on a duplicate registration
number.

### `PATCH /api/vehicles/:id/status` 🔒 ADMIN / FLEET_MANAGER

| Field | Type | Required |
|---|---|---|
| `status` | status enum | yes |

```json
// Request
{ "status": "IN_SHOP" }
```

**200** `"Vehicle status updated"`, `data` is the updated Vehicle. **404** if
unknown.

### `DELETE /api/vehicles/:id` 🔒 ADMIN / FLEET_MANAGER

**204 No Content** on success. **404** if unknown. **409** if the vehicle is
referenced by trips or logs — retire it (`status: "RETIRED"`) instead. See
[`vehicles.md`](./vehicles.md#deletion).

---

## Fuel & Expenses (§3.7)

Fuel purchases and non-fuel operational expenses (tolls / misc) are recorded
per vehicle, optionally attributed to a trip. Maintenance is **not** an expense
category here — its costs live on the maintenance log so the operational-cost
formula (fuel + maintenance) never double-counts. Full behavioral detail —
the trip-must-match-vehicle rule, the `vehicle` summary on reads, why these
are append-only — is in [`fuel-expenses.md`](./fuel-expenses.md).

Money fields accept a number or numeric string and are stored with 2-decimal
precision. A trip-attributed log must reference a trip that belongs to the same
vehicle, else **400** `"Trip does not belong to the specified vehicle"`.

### `GET /api/fuel-logs` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST / DRIVER

Query: `vehicleId`, `tripId`, `page` (default `1`), `limit` (default `20`,
max `100`). `data` is `{ items, pagination }`; each item includes a compact
`vehicle` summary. Ordered by `date` desc.

### `GET /api/fuel-logs/:id` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST / DRIVER

`data` is the FuelLog. **404** `"Fuel log not found"` if unknown.

### `POST /api/fuel-logs` 🔒 FLEET_MANAGER / ADMIN / DRIVER

| Field | Type | Required |
|---|---|---|
| `vehicleId` | string | yes |
| `liters` | number > 0 | yes |
| `cost` | number/string ≥ 0 | yes |
| `tripId` | string | no |
| `date` | ISO date (default now) | no |

**201** `"Fuel log recorded"`, `data` is the created FuelLog. **404** if the
vehicle or trip is unknown.

### `GET /api/expenses` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST

Query: `vehicleId`, `tripId`, `category` (`TOLL` | `MISC`), `page`, `limit`.
`data` is `{ items, pagination }`, ordered by `date` desc.

### `GET /api/expenses/:id` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST

`data` is the Expense. **404** `"Expense not found"` if unknown.

### `POST /api/expenses` 🔒 FLEET_MANAGER / ADMIN

| Field | Type | Required |
|---|---|---|
| `vehicleId` | string | yes |
| `category` | `TOLL` \| `MISC` | yes |
| `amount` | number/string > 0 | yes |
| `tripId` | string | no |
| `description` | string | no |
| `date` | ISO date (default now) | no |

**201** `"Expense recorded"`, `data` is the created Expense. **404** if the
vehicle or trip is unknown.

---

## Reports (`/api/reports`) 🔒

Read-only fleet analytics. Every endpoint requires a valid access token and is
restricted to `FLEET_MANAGER`, `FINANCIAL_ANALYST`, `SAFETY_OFFICER`, and
`ADMIN` per the RBAC matrix (`../PLAN.md` §6) — the `DRIVER` (dispatcher) role
gets `403`.

All four analytics also export as CSV via `GET /api/reports/export.csv?report=<name>`
(see below) — same numbers, different serialization.

**Conventions used across the per-vehicle reports:**

- Rows are ordered by `registrationNumber` ascending, and **every** vehicle is
  included (retired ones too), so a vehicle with no activity shows zeros / `null`.
- "Trips that ran" means status `DISPATCHED` or `COMPLETED`. `DRAFT` (never
  dispatched) and `CANCELLED` trips are excluded from distance and revenue.
- **Operational cost = fuel spend + maintenance spend only.** Expenses
  (tolls/misc) are tracked separately and are deliberately *not* included, to
  stay consistent with the ROI formula.
- Money and percentages are rounded to 2 decimals; ROI (a small ratio) to 4.
- Divide-by-zero yields `null` rather than `Infinity`/`NaN`.

### `GET /api/reports/fuel-efficiency` 🔒

Distance driven per litre consumed, per vehicle.
`kmPerLiter = totalDistance / totalLiters` (`null` when the vehicle has no fuel logs).

**Response 200** — `data` is an array of:
```json
{
  "vehicleId": "cmr...",
  "registrationNumber": "V-001",
  "name": "Truck A",
  "totalDistance": 200,
  "totalLiters": 50,
  "kmPerLiter": 4
}
```

### `GET /api/reports/fleet-utilization` 🔒

Fleet-wide utilization: share of the usable fleet currently `ON_TRIP`.
`utilizationPct = onTripVehicles / nonRetiredVehicles * 100` (`null` when there
are no non-retired vehicles).

**Response 200** — `data` is a single object:
```json
{
  "onTripVehicles": 1,
  "nonRetiredVehicles": 2,
  "totalVehicles": 3,
  "utilizationPct": 50
}
```

### `GET /api/reports/operational-cost` 🔒

Fuel + maintenance spend per vehicle.

**Response 200** — `data` is an array of:
```json
{
  "vehicleId": "cmr...",
  "registrationNumber": "V-001",
  "name": "Truck A",
  "fuelCost": 4500,
  "maintenanceCost": 2500,
  "operationalCost": 7000
}
```

### `GET /api/reports/vehicle-roi` 🔒

Return on investment per vehicle.
`netProfit = totalRevenue − operationalCost`; `roi = netProfit / acquisitionCost`
(`null` when `acquisitionCost` is 0).

**Response 200** — `data` is an array of:
```json
{
  "vehicleId": "cmr...",
  "registrationNumber": "V-002",
  "name": "Van B",
  "totalRevenue": 4000,
  "operationalCost": 1600,
  "acquisitionCost": 50000,
  "netProfit": 2400,
  "roi": 0.048
}
```

### `GET /api/reports/export.csv?report=<name>` 🔒

CSV download of any of the four reports above (same service functions, so the
numbers always match the JSON).

| Query | Required | Values |
|---|---|---|
| `report` | yes | `fuel-efficiency` \| `fleet-utilization` \| `operational-cost` \| `vehicle-roi` |

**Response 200**: `Content-Type: text/csv; charset=utf-8`,
`Content-Disposition: attachment; filename="<report>.csv"`. Body is the report
as CSV (header row + one row per vehicle; `fleet-utilization` is a single row).

**400** — missing `report`, or a value not in the list above.

---

## Roles

For reference when RBAC-gated endpoints (vehicles, trips, etc.) land — see
`Role` enum in `prisma/schema.prisma` and the RBAC matrix in `../PLAN.md` §6:

`ADMIN`, `FLEET_MANAGER`, `DRIVER` (dispatcher permissions — see `auth.md` for
why this name is a bit misleading), `SAFETY_OFFICER`, `FINANCIAL_ANALYST`.
