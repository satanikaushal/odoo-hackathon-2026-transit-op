# API Reference

Quick reference for every endpoint that exists today: method, path, auth
requirement, request body, and response shape. For the auth *system* itself
(tokens, rotation, RBAC internals) see [`auth.md`](./auth.md) — this doc is
just "what do I send, what do I get back."

This file only documents what's actually implemented. Vehicles, trips,
maintenance, fuel/expenses, dashboard, and reports are planned but not built
yet — see `../PLAN.md` for the full roadmap. Update this file as each phase
lands; don't let it drift from the code.

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

```json
// Request
{ "email": "admin@transitops.dev", "password": "..." }
```

**Response 200**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "5c2e89cd...",
    "user": {
      "id": "cmrhcmxt10000ntpb9nn55x6l",
      "name": "Admin",
      "email": "admin@transitops.dev",
      "role": "ADMIN"
    }
  }
}
```

**401** `"Invalid email or password"` — wrong password, unknown email, or
deactivated account (same message for all three, on purpose).

### `POST /api/auth/refresh`

No auth (the refresh token itself is the credential).

| Field | Type | Required |
|---|---|---|
| `refreshToken` | string, non-empty | yes |

```json
// Request
{ "refreshToken": "5c2e89cd..." }
```

**Response 200**
```json
{
  "success": true,
  "message": "OK",
  "data": { "accessToken": "eyJhbGciOi...", "refreshToken": "16ff0598..." }
}
```

Note: the `refreshToken` you get back is a **new** one — the one you sent is
revoked as part of this call. Store the new value and discard the old one.

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

## Drivers (`/api/drivers`) 🔒

Driver profiles (name, license, safety score, status) that get assigned to
trips. These are operational records, **not** login accounts — see the naming
note in `../PLAN.md` §2.

**Every endpoint requires a valid access token.** Reading (`GET`) is open to
any authenticated role. Writing (`POST`/`PATCH`/`DELETE`) is restricted to
`FLEET_MANAGER`, `SAFETY_OFFICER`, and `ADMIN` per the RBAC matrix
(`../PLAN.md` §6); other roles get `403`.

A driver object:

```json
{
  "id": "cmrhd0000driver0001",
  "name": "Jane Doe",
  "licenseNumber": "DL-0451-2027",
  "licenseCategory": "LMV",
  "licenseExpiryDate": "2027-05-01T00:00:00.000Z",
  "contactNumber": "+91-9876543210",
  "safetyScore": 100,
  "status": "AVAILABLE",
  "createdAt": "2026-07-12T05:24:43.814Z",
  "updatedAt": "2026-07-12T05:24:43.814Z"
}
```

`status` is one of `AVAILABLE`, `ON_TRIP`, `OFF_DUTY`, `SUSPENDED`.

### `GET /api/drivers` 🔒

List drivers, newest first. Optional filters:

| Query | Type | Effect |
|---|---|---|
| `status` | one of the `DriverStatus` values | exact-match filter |
| `q` | string | case-insensitive substring match on name / license number / contact number |

**Response 200**: `data` is an array of driver objects.

### `POST /api/drivers` 🔒 (write roles)

| Field | Type | Required |
|---|---|---|
| `name` | string, non-empty | yes |
| `licenseNumber` | string, non-empty, **unique** | yes |
| `licenseCategory` | string, non-empty | yes |
| `licenseExpiryDate` | date (ISO string, e.g. `2027-05-01`) | yes |
| `contactNumber` | string, non-empty | yes |
| `safetyScore` | number `0`–`100` | no (defaults to `100`) |
| `status` | `DriverStatus` | no (defaults to `AVAILABLE`) |

**Response 201**: the created driver object.

**409** `"A driver with this license number already exists"` — duplicate
`licenseNumber`.

### `GET /api/drivers/:id` 🔒

**Response 200**: the driver object. **404** `"Driver not found"`.

### `PATCH /api/drivers/:id` 🔒 (write roles)

Partial update — send any subset of the `POST` body fields (at least one; an
empty body is rejected with `400`).

**Response 200**: the updated driver object.

**404** `"Driver not found"`. **409** duplicate `licenseNumber` (same message
as `POST`).

### `DELETE /api/drivers/:id` 🔒 (write roles)

Hard-delete a driver.

**Response**: `204 No Content`.

**404** `"Driver not found"`.

**409** `"Driver has associated trips and cannot be deleted; set status to
SUSPENDED or OFF_DUTY instead"` — a driver referenced by any trip can't be
deleted (the trip history must stay intact); change their `status` instead.

---

## Roles

For reference when RBAC-gated endpoints (vehicles, trips, etc.) land — see
`Role` enum in `prisma/schema.prisma` and the RBAC matrix in `../PLAN.md` §6:

`ADMIN`, `FLEET_MANAGER`, `DRIVER` (dispatcher permissions — see `auth.md` for
why this name is a bit misleading), `SAFETY_OFFICER`, `FINANCIAL_ANALYST`.
