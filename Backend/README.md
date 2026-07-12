# backend

To install dependencies:

```bash
bun install
```

## Database

No Docker or local Postgres install needed — Prisma can run a local Postgres
for you:

```bash
bunx prisma dev --detach   # starts a local Postgres, prints connection URLs
```

Copy `.env.example` to `.env` and fill in `DATABASE_URL`/`SHADOW_DATABASE_URL`
with the **raw TCP** URLs `prisma dev` prints (`bunx prisma dev ls` to see them
again) — not the `prisma+postgres://` proxy URL `prisma init` generates by
default, which doesn't reliably support `migrate dev` in this setup.

Then apply migrations and seed some users:

```bash
bun run db:migrate   # applies prisma/migrations, prompts for a name if the schema changed
bun run db:seed      # creates one user per role, each with a random password printed once to the console
```

### Changing the schema

1. Edit `prisma/schema.prisma`.
2. `bun run db:migrate` — creates a new file under `prisma/migrations/` and applies it. Commit that folder.
3. Teammates pulling your change run `bun run db:deploy` (applies pending migrations, no prompts — safe for CI/teammates) instead of `db:migrate`.

If `db:migrate` ever fails on the shadow database (a PGlite quirk we hit once), fall back to `bun run db:push` to sync the schema directly, then hand-write the migration SQL with `bunx prisma migrate diff --from-migrations prisma/migrations --to-schema prisma/schema.prisma --script` and `prisma migrate resolve --applied <name>` to record it.

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
