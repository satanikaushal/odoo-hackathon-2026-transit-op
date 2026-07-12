# backend

To install dependencies:

```bash
bun install
```

## Database

Real Postgres 16 in Docker (we tried `bunx prisma dev`'s embedded PGlite
server first — it kept corrupting its prepared-statement state under
concurrent connections and eventually broke `migrate reset` entirely; a real
Postgres doesn't have that problem):

```bash
docker compose up -d   # starts Postgres + creates the shadow DB, both on first boot
```

This creates two databases in the same container: `transitops` (the real one)
and `transitops_shadow` (empty, only used by `prisma migrate dev` to compute
diffs — created automatically by `docker/init-shadow-db.sql` the first time
the container starts). `.env.example` already has matching connection strings
— copy it to `.env` as-is, nothing to fill in.

Then apply migrations and seed some users:

```bash
bun run db:migrate   # applies prisma/migrations, prompts for a name if the schema changed
bun run db:seed      # creates one user per role, each with a random password printed once to the console
```

### Changing the schema

1. Edit `prisma/schema.prisma`.
2. `bun run db:migrate` — creates a new file under `prisma/migrations/` and applies it. Commit that folder.
3. Teammates pulling your change run `bun run db:deploy` (applies pending migrations, no prompts — safe for CI/teammates) instead of `db:migrate`.

Other useful commands:

```bash
bun run db:generate  # regenerate the Prisma client after editing schema.prisma
bun run db:studio    # browse the DB in Prisma Studio
```

## Run

```bash
bun run dev     # hot reload
bun run start   # no hot reload
```

## Docs

- [`docs/api.md`](docs/api.md) — every endpoint: method, path, request body, response shape.
- [`docs/auth.md`](docs/auth.md) — how auth actually works (tokens, rotation, RBAC).
- [`PLAN.md`](PLAN.md) — full backend build plan and roadmap.

This project was created using `bun init` in bun v1.3.14. [Bun](https://bun.com) is a fast all-in-one JavaScript runtime.
