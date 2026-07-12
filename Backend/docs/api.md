# API Reference

Quick reference for every endpoint that exists today: method, path, auth
requirement, request body, and response shape. For the auth *system* itself
(tokens, rotation, RBAC internals) see [`auth.md`](./auth.md) — this doc is
just "what do I send, what do I get back."

This file only documents what's actually implemented. Vehicles, drivers,
trips, maintenance, fuel/expenses, dashboard, and reports are planned but not
built yet — see `../PLAN.md` for the full roadmap. Update this file as each
phase lands; don't let it drift from the code.

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

## Roles

For reference when RBAC-gated endpoints (vehicles, trips, etc.) land — see
`Role` enum in `prisma/schema.prisma` and the RBAC matrix in `../PLAN.md` §6:

`ADMIN`, `FLEET_MANAGER`, `DRIVER` (dispatcher permissions — see `auth.md` for
why this name is a bit misleading), `SAFETY_OFFICER`, `FINANCIAL_ANALYST`.
