# Tech Stack

**PostgreSQL** — SQL puro, sin ORM ni framework. Todo el trabajo vive en `schema.sql`.

## Sintaxis obligatoria de Postgres

- PKs: `GENERATED ALWAYS AS IDENTITY` — nunca `SERIAL`
- Fechas: `TIMESTAMPTZ`
- Enumerados: `CREATE TYPE ... AS ENUM`
- Monetarios: `NUMERIC(10,2)` con `CHECK (valor >= 0)`
- Índices parciales: `WHERE eliminado = FALSE` donde aplique

## Scripts re-ejecutables

Los scripts deben poder correrse más de una vez sin error. Usar `DROP TYPE IF EXISTS` / `DROP TABLE IF EXISTS` antes de cada `CREATE`, o `CREATE OR REPLACE` cuando el objeto lo admita.

## Comandos

```bash
# Aplicar el schema a una base existente
psql -U <user> -d <database> -f schema.sql

# Sesión interactiva
psql -U <user> -d <database>
```

## Workflow de seguridad

- Trabajar siempre contra la base de desarrollo `food_store_dev` (datos falsos).
- Envolver cada cambio en una transacción: `BEGIN` → verificar → `ROLLBACK` (y solo entonces `COMMIT`).
