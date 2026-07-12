# API Reference

Quick reference for every endpoint that exists today: method, path, auth
requirement, request body, and response shape. For the auth *system* itself
(tokens, rotation, RBAC internals) see [`auth.md`](./auth.md) — this doc is
just "what do I send, what do I get back."

This file only documents what's actually implemented. Drivers, trips,
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

### `GET /api/vehicles/:id` 🔒

`data` is the Vehicle object. **404** `"Vehicle not found"` if unknown.

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

## Roles

For reference when RBAC-gated endpoints (vehicles, trips, etc.) land — see
`Role` enum in `prisma/schema.prisma` and the RBAC matrix in `../PLAN.md` §6:

`ADMIN`, `FLEET_MANAGER`, `DRIVER` (dispatcher permissions — see `auth.md` for
why this name is a bit misleading), `SAFETY_OFFICER`, `FINANCIAL_ANALYST`.
