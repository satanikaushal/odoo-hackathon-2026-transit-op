# Authentication & Authorization

Stateless JWT access tokens + rotating opaque refresh tokens, with role-based
access control (RBAC) enforced by middleware. No self-service signup — the
brief only calls for login (see §3.1 of the hackathon spec), so accounts are
provisioned by an admin or the seed script (`prisma/seed.ts`).

## Roles

Defined in `prisma/schema.prisma` as the `Role` enum:

- `ADMIN` — user/account management
- `FLEET_MANAGER`
- `DRIVER` — the brief's "Driver" persona is really dispatcher permissions (creates/dispatches trips); the `Driver` **entity** (license/profile data) is unrelated and has no login of its own — see `PLAN.md` §2
- `SAFETY_OFFICER`
- `FINANCIAL_ANALYST`

## Token model

| | Access token | Refresh token |
|---|---|---|
| Format | JWT (HS256), signed with `JWT_ACCESS_SECRET` | Opaque random string (`crypto.randomBytes(32).toString("hex")`) |
| Payload | `{ sub: userId, role }` | none — it's just a bearer secret |
| Lifetime | `JWT_ACCESS_TTL` (default `15m`) | `JWT_REFRESH_TTL_DAYS` (default `7`) |
| Storage | Not persisted — verified purely by signature/expiry | `RefreshToken` table stores only a **sha256 hash** of it, never the raw value |
| Sent to client | In the JSON response body | In the JSON response body |
| Sent back by client | `Authorization: Bearer <token>` header | In the request body (`{ "refreshToken": "..." }`) |

Why an opaque refresh token instead of a second JWT: it needs to be revocable
(logout, rotation) and checked against the DB anyway, so a JWT's self-contained
verification buys nothing — a random secret + hash lookup is simpler and
avoids a second signing secret to manage.

Both `/login` and `/refresh` return `accessTokenExpiresAt`/
`refreshTokenExpiresAt` (ISO 8601 timestamps) alongside the tokens
(`src/lib/jwt.ts: getAccessTokenExpiry()` decodes the JWT's own `exp` claim;
the refresh expiry is the same `Date` used when writing the `RefreshToken`
row). Clients should schedule their refresh off these values instead of
hardcoding the `JWT_ACCESS_TTL`/`JWT_REFRESH_TTL_DAYS` config.

### Refresh rotation

Every call to `POST /api/auth/refresh` **revokes the token it was given** and
issues a brand new access+refresh pair (`auth.service.ts: refresh()`). A
refresh token can therefore only be used once. If a stale or already-used
refresh token is replayed, the request is rejected with 401. This limits the
blast radius if a refresh token leaks — reuse breaks visibly instead of
silently working forever.

Logout (`POST /api/auth/logout`) sets `revokedAt` on the matching row directly.
Both operations are idempotent-ish: replaying an already-revoked or unknown
token just gets 401 (refresh) or a silent 204 (logout) — the endpoint never
reveals whether a token existed.

### Device tokens (push notifications)

`RefreshToken` optionally carries `deviceType` (`DeviceType` enum: `ANDROID` |
`IOS`) and `deviceToken` (an FCM push token), set at login and left `null` if
the caller didn't send them. Since a `RefreshToken` row already models one
login session on one device, this is the natural place to store it — a user
logged in on two phones has two `RefreshToken` rows, each with its own device
token, and each can be revoked (logged out) independently.

`refresh()` copies the device info from the token being rotated onto the new
one, so the client only needs to send it once at login, not on every refresh.
There's no endpoint yet to update a device token without a full re-login, or
to query "all active device tokens for user X" for sending a push — both are
straightforward additions on top of this table when push notifications are
actually wired up (nothing sends anything today; this only stores the token).

## Endpoints

All under `/api/auth`. None require CSRF handling (no cookies involved — pure
bearer tokens, so it works the same for a web client or the Flutter app).

### `POST /api/auth/login`

```json
// Request
{
  "email": "admin@transitops.dev",
  "password": "...",
  "deviceType": "ANDROID",
  "deviceToken": "fcm-token-abc123"
}

// 200 response
{
  "success": true,
  "message": "OK",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "accessTokenExpiresAt": "2026-07-12T06:11:09.000Z",
    "refreshToken": "5c2e89cd...",
    "refreshTokenExpiresAt": "2026-07-19T05:56:09.844Z",
    "user": { "id": "...", "name": "Admin", "email": "admin@transitops.dev", "role": "ADMIN" }
  }
}
```

`deviceType` (`"ANDROID"` | `"IOS"`) and `deviceToken` (an FCM push token) are
optional, but must be provided together — `400` if only one is set. They're
stored on the `RefreshToken` row created for this login (see Device tokens
below), not returned in the response since the client already has them.

401 with `"Invalid email or password"` for a wrong password, an unknown email,
or a deactivated (`isActive: false`) user — deliberately the same message in
all three cases so the endpoint doesn't leak which emails are registered.

### `POST /api/auth/refresh`

```json
// Request
{ "refreshToken": "5c2e89cd..." }

// 200 response
{
  "success": true,
  "message": "OK",
  "data": {
    "accessToken": "...",
    "accessTokenExpiresAt": "2026-07-12T06:11:18.000Z",
    "refreshToken": "...",
    "refreshTokenExpiresAt": "2026-07-19T05:56:18.545Z"
  }
}
```

401 (`"Invalid or expired refresh token"`) if the token is unknown, revoked,
expired, or belongs to a now-deactivated user.

### `POST /api/auth/logout`

```json
// Request
{ "refreshToken": "5c2e89cd..." }
```

204 No Content on success (and on an already-invalid token — see above).

### `GET /api/auth/me`

Requires `Authorization: Bearer <accessToken>`.

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "...", "name": "Admin", "email": "admin@transitops.dev",
    "role": "ADMIN", "isActive": true, "createdAt": "2026-07-12T05:24:43.814Z"
  }
}
```

Re-reads the user from the DB on every call (rather than trusting the JWT
payload) so a deactivated account stops passing `/me` immediately, even though
its still-valid access token would otherwise pass `authenticate` until it
naturally expires.

## Middleware

### `authenticate` (`src/middleware/authenticate.ts`)

Reads the `Authorization: Bearer <token>` header, verifies it against
`JWT_ACCESS_SECRET`, and sets `req.user = { sub, role }`. Missing header,
malformed header, or an invalid/expired token all produce a `401` via
`ApiError.unauthorized(...)` — handled centrally by `middleware/errorHandler.ts`.

It does **not** hit the database — it only validates the JWT signature and
expiry. This is the standard access-token tradeoff: fast and stateless, at the
cost of a role/deactivation change not taking effect until the token expires
(≤15 minutes by default). `/me` is the one place that re-checks the DB, for
callers that need up-to-the-second state.

### `authorize(...roles)` (`src/middleware/authorize.ts`)

Role gate, used **after** `authenticate` in a route chain:

```ts
router.post("/vehicles", authenticate, authorize("ADMIN", "FLEET_MANAGER"), createVehicle);
```

401 if `req.user` isn't set (i.e. `authenticate` wasn't run first or failed
open somehow), 403 if the role isn't in the allowed list.

### Wiring pattern for new routes

`app.ts` does **not** apply `authenticate` globally — `/api/auth/login`,
`/refresh`, and `/logout` must stay public, and at the time of writing they're
the only routes that exist. The convention going forward (see `PLAN.md`
Phase 1, item 6): mount future resource routers with `authenticate` (and
`authorize` where roles matter) applied explicitly per router or per route,
rather than threading a growing exclusion list through one global middleware.

## Password storage

Hashed with `Bun.password.hash` (Argon2id, Bun's built-in — no `bcrypt`
dependency needed) and verified with `Bun.password.verify`. Never logged,
never returned by any endpoint.

## Seeding accounts

`prisma/seed.ts` creates one user per role (see table above) with a **freshly
generated random password per user**, printed to the console exactly once at
seed time:

```bash
bun run db:seed
```

Passwords are never hardcoded and never stored in plaintext anywhere —
re-running the seed skips any email that already exists rather than resetting
its password, so save the printed credentials somewhere before you lose that
terminal output.

## Environment variables

| Var | Required | Default | Notes |
|---|---|---|---|
| `JWT_ACCESS_SECRET` | yes | — | HS256 signing secret for access tokens; app fails to boot without it (`config/env.ts`) |
| `JWT_ACCESS_TTL` | no | `15m` | any `jsonwebtoken` `expiresIn` value |
| `JWT_REFRESH_TTL_DAYS` | no | `7` | refresh token lifetime in days |

There is deliberately no `JWT_REFRESH_SECRET` — refresh tokens are opaque
random values, not JWTs, so there's nothing to sign.

## Known gaps / not yet built

- No admin endpoints to create/list/change-role users yet (`PLAN.md` Phase 1,
  item 7) — accounts currently come only from `prisma/seed.ts`.
- No rate limiting on `/login` — worth adding before this goes anywhere near
  a public network.
- No multi-session visibility (e.g. "log out all devices") — logout only
  revokes the one refresh token it's given.
- Device tokens are stored but nothing sends push notifications with them yet
  — no FCM integration, no endpoint to look up a user's active device tokens.
