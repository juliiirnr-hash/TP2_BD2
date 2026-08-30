# AGENTS.md

## What this is
University Databases 2 (BD2) assignment (repo `juliiirnr-hash/TP2_BD2`): a food ordering/catalog system. Deliverable is **only a PostgreSQL SQL schema** — there is no app layer, no build/test/lint tooling.

## Canonical file — root repo is the source of truth
- Develop and commit the **root** `schema.sql`. It is tracked by the root git repo and holds the full, real DDL.
- There is no `TP2_BD2/schema.sql` file on disk (the nested repo's copy is deleted; both committed versions were empty placeholders). Do not recreate or edit one there — work only in root `schema.sql`.
- Root `schema.sql` is re-runnable and wraps all DDL in a single `BEGIN`...`COMMIT` block; keep that structure when editing.

## Git trap
- `TP2_BD2/` is a **nested, independent git repo** pointing at the **same remote** as the root, not a submodule. The root repo reports it as untracked (`?? TP2_BD2/`).
- Never `git add` the `TP2_BD2/` directory into the root repo. Commit/push only from the root repo.
- Verify nothing got swallowed: `git status` should show nothing unexpected.

## Canonical conventions live in the nested repo docs
Read these before writing schema code — they are the authoritative project rules:
- `TP2_BD2/.kiro/steering/product.md` — entities, ENUMs (rol_usuario, estado_pedido, forma_pago)
- `TP2_BD2/.kiro/steering/structure.md` — naming, types, constraints, logical delete
- `TP2_BD2/.kiro/steering/tech.md` — stack, re-runnable script rules
- `TP2_BD2/protocolo_seguridad.md` — DB safety workflow (read-only; never edit)

## Schema rules (non-negotiable)
- Postgres idioms only: PKs with `GENERATED ALWAYS AS IDENTITY` (never `SERIAL`), `TIMESTAMPTZ`, `NUMERIC(10,2)` with `CHECK (valor >= 0)`, `CREATE TYPE ... AS ENUM`.
- snake_case Spanish naming: tables in singular (`usuario`, `producto`), PK `id_<tabla>`, FK uses the referenced PK name, ENUM values UPPERCASE.
- Every table gets `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` and `eliminado BOOLEAN NOT NULL DEFAULT FALSE`.
- Prefer logical delete; normal queries filter `WHERE eliminado = FALSE`; use partial indexes (`WHERE eliminado = FALSE`) where relevant.
- `ON DELETE RESTRICT` on FKs by default; `CASCADE` only for dependent children (e.g. `detalle_pedido` → `pedido`).
- Denormalization is intentional: `pedido.total` is a cached sum; `detalle_pedido.precio_unitario` is a purchase-time snapshot (never reference `producto.precio` in historical queries).
- Scripts must be re-runnable: use `DROP ... IF EXISTS` / `CREATE OR REPLACE` where applicable.

## DB safety workflow
- Work only against the dev copy `food_store_dev` (fake data). Never touch the original/real-data DB.
- Wrap every change in a transaction: `BEGIN` → verify → `ROLLBACK` (and only then `COMMIT`).

## Verification
- No lint/typecheck exists. Validate by applying the schema to a local Postgres instance: `psql -U <user> -d <database> -f schema.sql`, confirming tables/constraints load without errors. `psql` is not on PATH here — install/start Postgres first.

## Conventions
- Commit messages in Spanish (e.g. "Agrego schema"); keep new commits in Spanish.
- Single-file schema: keep everything in `schema.sql`; do not split into migration scripts unless the user asks.
