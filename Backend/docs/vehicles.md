# Vehicle Registry

The master list of fleet vehicles (brief §3.3). Each vehicle carries a unique
Registration Number, a Name/Model, Type, Maximum Load Capacity, Odometer,
Acquisition Cost, and a lifecycle Status. Backed by the `Vehicle` model in
`prisma/schema.prisma`; implemented as `schemas/vehicle.schema.ts` →
`services/vehicle.service.ts` → `controllers/vehicle.controller.ts` →
`routes/vehicle.routes.ts`, mounted at `/api/vehicles`.

For the request/response envelope and shared error codes, see
[`api.md`](./api.md); this doc is the behavioral detail.

## The model

| Field | Type | Notes |
|---|---|---|
| `id` | string (cuid) | server-generated |
| `registrationNumber` | string | **unique**, stored uppercased (see below) |
| `name` | string | vehicle name / model |
| `type` | string | free-text class, e.g. `"Truck"`, `"Van"` |
| `maxLoadCapacity` | float | must be positive |
| `odometer` | float | ≥ 0, defaults to `0` |
| `acquisitionCost` | Decimal(12,2) | ≥ 0; serialized as a string in JSON to keep precision |
| `status` | enum | `AVAILABLE` \| `ON_TRIP` \| `IN_SHOP` \| `RETIRED`, defaults to `AVAILABLE` |
| `region` | string \| null | optional; used by dashboard/report filters later |
| `createdAt` / `updatedAt` | ISO 8601 | server-managed |

### Registration number normalization

Registration numbers are trimmed and **uppercased** before they're stored or
matched (`vehicle.schema.ts`). So `mh12ab1234` and `MH12AB1234` are the same
vehicle, and the DB's unique constraint on `registrationNumber` enforces that
consistently — you can't sneak in a duplicate by changing the case. Callers can
send whatever case they like; what comes back is always uppercase.

### Why `acquisitionCost` is a string

The column is `Decimal(12,2)` (money). A JS `number` can't represent every such
value exactly, so the API accepts a number **or** a numeric string on input and
always returns it as a **string** in responses. Send `"550000.50"` or
`550000.5` — both are accepted; parse the returned string with a decimal-safe
library on the client, not `parseFloat`, if you're doing arithmetic on it.

## Status lifecycle

The four values come straight from the brief:

- `AVAILABLE` — in service, not currently on a trip; the default at creation.
- `ON_TRIP` — assigned to an active trip. Once trips are wired up this will be
  driven by dispatch/completion, not set by hand — but the API accepts it
  manually today.
- `IN_SHOP` — under maintenance, unavailable for dispatch.
- `RETIRED` — permanently out of service. This is the intended way to remove a
  vehicle that has history (see [Deletion](#deletion) below) — it stays in the
  registry for reporting but shouldn't be dispatched.

The registry does **not** enforce a state machine yet: any status can be set to
any other via `PATCH /:id` or `PATCH /:id/status`. Transition rules (e.g.
"can't retire a vehicle that's `ON_TRIP`") belong with the trips module that
owns that context and aren't implemented here.

## Access control

Applied per-route in `vehicle.routes.ts`. Every endpoint requires a valid
access token (`authenticate`); writes additionally require a manager role:

| Action | Roles |
|---|---|
| Read (`GET`) | any authenticated user |
| Create / update / delete | `ADMIN`, `FLEET_MANAGER` |

Reads are open because trips, dashboards, and reports across roles all need to
see the fleet. Mutations are limited to the two roles that own fleet
composition. A read by an unauthenticated caller is `401`; a write by an
authenticated non-manager is `403`.

## Endpoints

All paths are under `/api/vehicles` and all require
`Authorization: Bearer <accessToken>`.

### `GET /api/vehicles`

List vehicles, newest first (`createdAt desc`), with optional filters and
pagination. All query params are optional.

| Param | Type | Default | Notes |
|---|---|---|---|
| `status` | `AVAILABLE`\|`ON_TRIP`\|`IN_SHOP`\|`RETIRED` | — | exact match |
| `type` | string | — | exact match |
| `region` | string | — | exact match |
| `search` | string | — | case-insensitive substring of `registrationNumber` **or** `name` |
| `page` | int ≥ 1 | `1` | |
| `limit` | int 1–100 | `20` | capped at 100 |

```json
// GET /api/vehicles?status=AVAILABLE&search=tata&page=1&limit=20
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [
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
    ],
    "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
  }
}
```

### `GET /api/vehicles/available-for-dispatch`

The dispatch selection pool — every vehicle currently `status = AVAILABLE`,
ordered by `registrationNumber` ascending. `data` is a **plain array** of
vehicle objects (not the `{ items, pagination }` envelope the list endpoint
uses), since it backs a picker rather than a browsable table. `IN_SHOP`,
`ON_TRIP`, and `RETIRED` vehicles are excluded.

```json
// GET /api/vehicles/available-for-dispatch
{
  "success": true,
  "message": "OK",
  "data": [
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
  ]
}
```

Note the route is registered **before** `/:id` in `vehicle.routes.ts`, so
`available-for-dispatch` isn't mistaken for a vehicle id.

### `GET /api/vehicles/:id`

Fetch one vehicle by `id`. **404** `"Vehicle not found"` if it doesn't exist.
`data` is the vehicle object (same shape as an `items[]` entry above).

### `POST /api/vehicles` 🔒 ADMIN / FLEET_MANAGER

Create a vehicle.

| Field | Type | Required | Notes |
|---|---|---|---|
| `registrationNumber` | string | yes | uppercased; must be unique |
| `name` | string | yes | |
| `type` | string | yes | |
| `maxLoadCapacity` | number > 0 | yes | |
| `acquisitionCost` | number/string ≥ 0 | yes | |
| `odometer` | number ≥ 0 | no | defaults to `0` |
| `status` | status enum | no | defaults to `AVAILABLE` |
| `region` | string | no | |

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

**201** `"Vehicle created"`, `data` is the created vehicle.
**409** `"A vehicle with registration number \"MH12AB1234\" already exists"` on
a duplicate registration number.

### `PATCH /api/vehicles/:id` 🔒 ADMIN / FLEET_MANAGER

Partial update — send only the fields you want to change; at least one is
required (an empty body is `400`). Same field rules as create. `region` may be
set to `null` to clear it. Changing `registrationNumber` to one already in use
is **409**; a missing `id` is **404**.

**200** `"Vehicle updated"`, `data` is the updated vehicle.

### `PATCH /api/vehicles/:id/status` 🔒 ADMIN / FLEET_MANAGER

Convenience endpoint to change only the status (e.g. flip a vehicle to
`IN_SHOP`) without echoing the rest of the record.

```json
// Request
{ "status": "IN_SHOP" }
```

**200** `"Vehicle status updated"`, `data` is the updated vehicle. **404** if
the vehicle doesn't exist. Equivalent to `PATCH /:id` with `{ "status": ... }`;
it exists so clients don't have to use the general update route for the single
most common mutation.

### `DELETE /api/vehicles/:id` 🔒 ADMIN / FLEET_MANAGER

**204 No Content** on success. **404** if the vehicle doesn't exist.

**409** — `"Vehicle has related trips or logs and cannot be deleted; set its
status to RETIRED instead"` — if the vehicle is referenced by any trip,
maintenance log, fuel log, or expense. See below.

## Deletion

Delete is a hard delete, and it's deliberately narrow. Because the brief models
end-of-life through the `RETIRED` status (and trips/costs reference vehicles for
reporting), deleting a vehicle that has any history would either orphan those
rows or destroy financial records. So the database's foreign keys block it, and
the service turns that into a clean **409** telling you to retire the vehicle
instead.

In practice: `DELETE` is for undoing a mistakenly-created vehicle that was never
used. For anything that's ever been dispatched or incurred a cost, use
`PATCH /:id/status` with `{ "status": "RETIRED" }`.

## Validation & errors

Every body/params/query is zod-validated before the controller runs; failures
are `400 "Invalid body"` / `"Invalid params"` / `"Invalid query"` with
field-level `details` (see [`api.md`](./api.md#conventions)). Beyond
validation:

| Status | When |
|---|---|
| 401 | no / invalid access token |
| 403 | authenticated but not `ADMIN`/`FLEET_MANAGER` on a write |
| 404 | `id` doesn't match any vehicle |
| 409 | duplicate `registrationNumber`, or delete blocked by related records |

## Known gaps / not yet built

- **No status state machine.** Any status → any status is allowed; trip
  dispatch/completion doesn't yet drive `ON_TRIP` automatically (that lands with
  the trips module).
- **No soft-delete flag** — `RETIRED` is the soft-delete. Retired vehicles are
  still returned by `GET /api/vehicles` unless you filter `status`.
- **No bulk import / CSV** for onboarding an existing fleet.
- **`type` and `region` are free-text**, not enums — no controlled vocabulary,
  so `"truck"` and `"Truck"` are different `type` filters. Normalize on the
  client if that matters.
