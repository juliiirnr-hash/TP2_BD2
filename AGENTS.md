# AGENTS.md

## What this is
University Databases 2 assignment (repo `juliiirnr-hash/TP2_BD2`): a single SQL schema file plus an empty `schema.sql` placeholder. Target RDBMS is **PostgreSQL**. There is no build/test/lint tooling.

## Canonical file
- Develop and commit the **root** `schema.sql`. It is the file tracked by the root git repo.
- `TP2_BD2/schema.sql` is a stale duplicate — do not edit or commit from it.

## Git trap
- `TP2_BD2/` is a **nested, independent git repo** pointing at the same remote as the root, not a submodule. The root repo reports it as untracked (`?? TP2_BD2/`).
- Never `git add` the `TP2_BD2/` directory into the root repo. Commit/push only from the root repo.
- Verify nothing got swallowed accidentally: `git status` should only show `schema.sql`.

## Verification
- No lint/typecheck exists. Validate by applying the schema to a local Postgres instance, e.g. `psql -d <db> -f schema.sql`, and confirm tables/constraints load without errors. `psql` is not on PATH here, so install/start Postgres first if needed.

## Conventions
- Commit messages in this repo are Spanish (e.g. "Agrego schema"); keep new commits in Spanish.
- Similar dialect: avoid MySQL/SQL Server syntax — use Postgres idioms (`SERIAL`/`IDENTITY`, `TIMESTAMP WITH TIME ZONE`, `TEXT`, `CREATE TABLE IF NOT EXISTS`).
- Single-file schema: keep everything in `schema.sql`; do not split into migration scripts unless the user asks.