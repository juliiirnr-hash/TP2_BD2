# Project Structure

```
schema/               ← root repo (fuente de verdad)
├── schema.sql        # DDL completo: tipos, tablas, constraints, índices
├── AGENTS.md         # Reglas para el asistente IA
└── .kiro/
    └── steering/     # Este directorio

TP2_BD2/              # Repo git independiente (mismo remote) — NO hacer git add de esta carpeta
├── schema.sql        # Placeholder vacío — no editar
└── .kiro/steering/   # Docs de convenciones (leer, no editar)
```

El único archivo a modificar es el `schema.sql` raíz.

---

## Convenciones de nombrado

- `snake_case` minúsculas, español.
- Tablas en singular: `usuario`, `producto`, `pedido`, `detalle_pedido`.
- PK: `id_<tabla>` (ej. `id_usuario`).
- FK: mismo nombre que la PK referenciada.
- Valores de ENUM en `MAYÚSCULAS`.

## Columnas estándar (toda tabla)

```sql
created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
eliminado   BOOLEAN      NOT NULL DEFAULT FALSE
```

## Borrado lógico

Preferir borrado lógico. Consultas normales filtran `WHERE eliminado = FALSE`. Usar `DELETE` físico solo cuando el contexto lo justifique. Índices sobre tablas con borrado lógico deben ser parciales:

```sql
CREATE INDEX idx_... ON tabla(columna) WHERE eliminado = FALSE;
```

## Tipos de datos

| Uso | Tipo |
|---|---|
| PKs / FKs | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| Texto | `VARCHAR(n)` con largo apropiado |
| Precios | `NUMERIC(10,2)` + `CHECK (valor >= 0)` |
| Fechas | `TIMESTAMPTZ` |
| Booleanos | `BOOLEAN NOT NULL DEFAULT <valor>` |
| Enumerados | `CREATE TYPE ... AS ENUM` |

## Constraints

- `CHECK` en numéricos que no admiten negativos.
- `UNIQUE` donde aplique.
- `ON DELETE RESTRICT` por defecto; `ON DELETE CASCADE` solo para hijos dependientes (`detalle_pedido` → `pedido`).
- FKs inline (`REFERENCES ... ON DELETE ...`), sin nombre de constraint explícito.

## Desnormalización intencional

- `pedido.total` — suma cacheada; no recalcular desde detalles en consultas.
- `detalle_pedido.precio_unitario` — snapshot del precio al momento de la compra; nunca referenciar `producto.precio` en consultas históricas.
