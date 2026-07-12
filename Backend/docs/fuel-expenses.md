# Fuel Logs & Expenses

Per-vehicle operating costs (brief §3.7): **fuel purchases** and **non-fuel
operational expenses** (tolls / misc). Two sibling resources with near-identical
shapes and rules, so they're documented together.

- Fuel logs: `FuelLog` model → `schemas/fuelLog.schema.ts` →
  `services/fuelLog.service.ts` → `controllers/fuelLog.controller.ts` →
  `routes/fuelLog.routes.ts`, mounted at **`/api/fuel-logs`**.
- Expenses: `Expense` model → `schemas/expense.schema.ts` →
  `services/expense.service.ts` → `controllers/expense.controller.ts` →
  `routes/expense.routes.ts`, mounted at **`/api/expenses`**.

For the request/response envelope and shared error codes, see
[`api.md`](./api.md); this doc is the behavioral detail.

## Why maintenance isn't an expense category

There is **no `MAINTENANCE` category**. Maintenance costs live on the
`MaintenanceLog` model instead, because the operational-cost formula the reports
use is **fuel + maintenance**, reading maintenance straight from that log. A
`MAINTENANCE` expense category would double-count it. So expenses here are only
`TOLL` and `MISC` — costs the operational-cost formula deliberately excludes.

## The models

### FuelLog

| Field | Type | Notes |
|---|---|---|
| `id` | string (cuid) | server-generated |
| `vehicleId` | string | required; must reference an existing vehicle |
| `tripId` | string \| null | optional; if set, the trip must belong to `vehicleId` |
| `liters` | float | must be **> 0** |
| `cost` | Decimal(12,2) | **≥ 0**; serialized as a string in JSON to keep precision |
| `date` | ISO 8601 | defaults to now() at the DB layer when omitted |
| `createdAt` | ISO 8601 | server-managed |

### Expense

| Field | Type | Notes |
|---|---|---|
| `id` | string (cuid) | server-generated |
| `vehicleId` | string | required; must reference an existing vehicle |
| `tripId` | string \| null | optional; if set, the trip must belong to `vehicleId` |
| `category` | enum | `TOLL` \| `MISC` |
| `amount` | Decimal(12,2) | must be **> 0**; string-encoded in JSON |
| `description` | string \| null | optional, ≤ 500 chars |
| `date` | ISO 8601 | defaults to now() at the DB layer when omitted |
| `createdAt` | ISO 8601 | server-managed |

### Why money fields are strings

`cost` / `amount` are `Decimal(12,2)`. A JS `number` can't represent every such
value exactly, so the API accepts a number **or** a numeric string on input and
always returns a **string** in responses. Parse it with a decimal-safe library
on the client if you do arithmetic on it — not `parseFloat`.

### The `vehicle` summary on reads

List and get-by-id responses **include** a compact vehicle summary alongside the
log/expense (the create response does not — it returns the bare record):

```json
"vehicle": { "id": "cmr...", "registrationNumber": "MH12AB1234", "name": "Tata Ace", "status": "AVAILABLE" }
```

## The trip-must-match-vehicle rule

`tripId` is optional. When you *do* attribute a fuel log or expense to a trip,
that trip must belong to the same `vehicleId` — otherwise per-vehicle cost and
fuel-efficiency figures would be skewed by activity that happened on a different
vehicle. Violations are rejected with **400** `"Trip does not belong to the
specified vehicle"`. A `vehicleId` or `tripId` that doesn't exist at all is
**404** (`"Vehicle not found"` / `"Trip not found"`).

## Access control

Applied per-route. Every endpoint requires a valid access token
(`authenticate`). Roles come from the RBAC matrix (`../PLAN.md` §6):

| Action | Fuel logs | Expenses |
|---|---|---|
| Read (`GET`) | `FLEET_MANAGER`, `ADMIN`, `FINANCIAL_ANALYST`, `DRIVER` | `FLEET_MANAGER`, `ADMIN`, `FINANCIAL_ANALYST` |
| Create (`POST`) | `FLEET_MANAGER`, `ADMIN`, `DRIVER` | `FLEET_MANAGER`, `ADMIN` |

The difference: the `DRIVER` (dispatcher) role may **log fuel** — it's a routine
field operation — but not record expenses, which are a manager task. Financial
analysts read both for cost analysis but write neither. An unauthenticated
caller is `401`; an authenticated caller with the wrong role is `403`.

There are **no update or delete** endpoints — fuel logs and expenses are
append-only records today.

---

## Fuel-log endpoints

All under `/api/fuel-logs`; all require `Authorization: Bearer <accessToken>`.

### `GET /api/fuel-logs` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST / DRIVER

List fuel logs, most recent first (`date desc`), with optional filters and
pagination. All query params optional.

| Param | Type | Default | Notes |
|---|---|---|---|
| `vehicleId` | string | — | exact match |
| `tripId` | string | — | exact match |
| `page` | int ≥ 1 | `1` | |
| `limit` | int 1–100 | `20` | capped at 100 |

```json
// GET /api/fuel-logs?vehicleId=cmr...&page=1&limit=20
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "cmrf...",
        "vehicleId": "cmr...",
        "tripId": null,
        "liters": 45.5,
        "cost": "4200.00",
        "date": "2026-07-11T08:15:00.000Z",
        "createdAt": "2026-07-11T08:16:02.114Z",
        "vehicle": {
          "id": "cmr...",
          "registrationNumber": "MH12AB1234",
          "name": "Tata Ace",
          "status": "AVAILABLE"
        }
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
  }
}
```

### `GET /api/fuel-logs/:id` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST / DRIVER

Fetch one fuel log (with its `vehicle` summary). **404** `"Fuel log not found"`
if unknown.

### `POST /api/fuel-logs` 🔒 FLEET_MANAGER / ADMIN / DRIVER

Record a fuel purchase.

| Field | Type | Required | Notes |
|---|---|---|---|
| `vehicleId` | string | yes | must exist |
| `liters` | number > 0 | yes | |
| `cost` | number/string ≥ 0 | yes | |
| `tripId` | string | no | must belong to `vehicleId` |
| `date` | ISO date | no | defaults to now() |

```json
// Request
{ "vehicleId": "cmr...", "liters": 45.5, "cost": "4200.00" }
```

**201** `"Fuel log recorded"`, `data` is the created FuelLog (no `vehicle`
summary). **404** if the vehicle or trip is unknown; **400** if the trip belongs
to a different vehicle.

---

## Expense endpoints

All under `/api/expenses`; all require `Authorization: Bearer <accessToken>`.

### `GET /api/expenses` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST

List expenses, most recent first (`date desc`), with optional filters and
pagination. All query params optional.

| Param | Type | Default | Notes |
|---|---|---|---|
| `vehicleId` | string | — | exact match |
| `tripId` | string | — | exact match |
| `category` | `TOLL`\|`MISC` | — | exact match |
| `page` | int ≥ 1 | `1` | |
| `limit` | int 1–100 | `20` | capped at 100 |

```json
// GET /api/expenses?category=TOLL
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "cme...",
        "vehicleId": "cmr...",
        "tripId": "cmt...",
        "category": "TOLL",
        "amount": "250.00",
        "description": "Expressway toll",
        "date": "2026-07-11T09:00:00.000Z",
        "createdAt": "2026-07-11T09:01:10.552Z",
        "vehicle": {
          "id": "cmr...",
          "registrationNumber": "MH12AB1234",
          "name": "Tata Ace",
          "status": "ON_TRIP"
        }
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
  }
}
```

### `GET /api/expenses/:id` 🔒 FLEET_MANAGER / ADMIN / FINANCIAL_ANALYST

Fetch one expense (with its `vehicle` summary). **404** `"Expense not found"` if
unknown.

### `POST /api/expenses` 🔒 FLEET_MANAGER / ADMIN

Record a non-fuel operational expense.

| Field | Type | Required | Notes |
|---|---|---|---|
| `vehicleId` | string | yes | must exist |
| `category` | `TOLL` \| `MISC` | yes | |
| `amount` | number/string > 0 | yes | |
| `tripId` | string | no | must belong to `vehicleId` |
| `description` | string | no | ≤ 500 chars |
| `date` | ISO date | no | defaults to now() |

```json
// Request
{ "vehicleId": "cmr...", "category": "TOLL", "amount": "250.00", "description": "Expressway toll" }
```

**201** `"Expense recorded"`, `data` is the created Expense (no `vehicle`
summary). **404** if the vehicle or trip is unknown; **400** if the trip belongs
to a different vehicle.

---

## Validation & errors

Every body/params/query is zod-validated before the controller runs; failures
are `400 "Invalid body"` / `"Invalid params"` / `"Invalid query"` with
field-level `details` (see [`api.md`](./api.md#conventions)). Beyond validation:

| Status | When |
|---|---|
| 401 | no / invalid access token |
| 403 | authenticated but role not permitted for this action |
| 400 | `tripId` given but the trip belongs to a different vehicle |
| 404 | unknown `vehicleId`, `tripId`, or (`GET /:id`) unknown record |

## How this feeds the reports

Fuel spend rolls into the **operational-cost** and **fuel-efficiency** reports
and the per-vehicle `GET /api/vehicles/:id/costs` figure. Expenses (`TOLL` /
`MISC`) are recorded for completeness but are **deliberately excluded** from
operational cost and ROI, keeping those formulas to fuel + maintenance. See the
Reports section of [`api.md`](./api.md).

## Known gaps / not yet built

- **Append-only.** No update or delete endpoints — a mistaken entry can't be
  corrected via the API yet.
- **No aggregate endpoint** on these routes; totals come from the reports.
- **`date` isn't range-filterable** — you can filter by vehicle/trip/category
  but not by a date window; paginate and filter client-side for now.
