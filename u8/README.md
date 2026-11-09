# Food Store — TP8

Tablet offline en una feria sin señal. La tablet consulta el catálogo y arma
borradores; el servidor decide precio, stock y ventas.

**Regla de oro:** el móvil propone, el servidor dispone.
`SIMULADO_APROBADO` **no es una venta**.

## Estructura

```
food-store/                  (en el repositorio: u8/)
├── README.md
├── movil/
│   ├── schema_sqlite.sql        consigna 1.b
│   ├── pruebas_sqlite.sql       consigna 1.c
│   ├── semaforo.sql             consigna 2.b
│   ├── servidor_snapshot.csv    consigna 2.a (se genera)
│   └── foodstore_movil.db       base de la tablet (se genera)
└── docs/
    ├── informe.md               1.a, 2.c, 3.a, 3.b, 3.c (fuente)
    ├── informe.pdf              el mismo informe listo para entregar (4 paginas)
    ├── bitacora_ia.md           consigna 4.b
    ├── DUIA.md                  consigna 4.b
    └── sql/
        ├── v_snapshot_movil.sql
        └── verificar_servidor.sql
```

## Requisitos

- SQLite 3.37 o superior (por las tablas `STRICT`)
- PostgreSQL 16 o superior
- DBeaver, DB Browser for SQLite, o las CLIs `psql` / `sqlite3`

> En esta PC `psql` no está en el PATH. Usar:
> `& "C:\Program Files\PostgreSQL\18\bin\psql.exe"`

## Orden para crear todo desde cero

### 1. Creo la vista de la instantánea

La base `food_store_test` ya tiene las tablas del servidor
(`categoria`, `producto`, `pedido`, `detalle_pedido`, `usuario`, `usuario_anon`).

```bash
psql -U postgres -d food_store_test -f docs/sql/v_snapshot_movil.sql
```

### 2. Exporto la instantánea a CSV

```bash
psql -U postgres -d food_store_test -c "\copy (SELECT * FROM v_snapshot_movil) TO 'movil/servidor_snapshot.csv' CSV HEADER"
```

### 3. Creo la base de la tablet

```bash
sqlite3 movil/foodstore_movil.db ".read movil/schema_sqlite.sql"
```

Quedan las 4 tablas: `producto_cache`, `pedido_borrador`, `item_borrador`, `cola_sync`.
`PRAGMA foreign_keys = ON` se aplica por conexión, no queda guardado en el archivo.

### 4. Importo el CSV y cargo el catálogo

`snapshot_servidor` es una tabla de paso: recibe el CSV tal cual (todo `TEXT`),
porque los booleanos llegan como `t` / `f` o `true` / `false`.

```bash
sqlite3 movil/foodstore_movil.db
```

```sql
CREATE TABLE IF NOT EXISTS snapshot_servidor (
    id              TEXT,
    nombre          TEXT,
    precio_centavos TEXT,
    stock_visto     TEXT,
    disponible      TEXT,
    eliminado       TEXT,
    fecha_copia     TEXT
);

.import --csv --skip 1 movil/servidor_snapshot.csv snapshot_servidor

DELETE FROM producto_cache;

INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
SELECT CAST(id AS INTEGER),
       nombre,
       CAST(precio_centavos AS INTEGER),
       CAST(stock_visto AS INTEGER),
       CASE WHEN disponible IN ('t', 'true', '1') THEN 1 ELSE 0 END,
       CASE WHEN eliminado  IN ('t', 'true', '1') THEN 1 ELSE 0 END,
       fecha_copia
FROM snapshot_servidor;

SELECT COUNT(*) AS productos_en_cache FROM producto_cache;
```

### 5. Pruebo la base (consigna 1.c)

`pruebas_sqlite.sql` borra `producto_cache` para cargar su propio catálogo de prueba,
así que se corre **sobre una copia** para no perder la instantánea:

```powershell
Copy-Item movil/foodstore_movil.db "$env:TEMP\prueba.db"
sqlite3 "$env:TEMP\prueba.db" ".read movil/pruebas_sqlite.sql"
```

Si querés correrlo sobre la base real, hacelo antes del paso 4.

Los dos `Error` de C7 (`CHECK constraint failed` y `FOREIGN KEY constraint failed`)
son el resultado esperado: la fila no se inserta y el conteo queda igual.

### 6. Corro el semáforo (consigna 2.b)

```bash
sqlite3 movil/foodstore_movil.db ".read movil/semaforo.sql"
```

Compara cada solicitud `PENDIENTE` contra `snapshot_servidor` y escribe en
`cola_sync`:

- `RECHAZADO` — no existe, no está disponible, dado de baja o no alcanza el stock
- `CONFLICTO` — no hay rojo, pero cambió algún precio
- `SIMULADO_APROBADO` — todo coincide

### 7. Verifico que el servidor no cambió (consigna 2.c)

```bash
psql -U postgres -d food_store_test -f docs/sql/verificar_servidor.sql
```

Correrlo antes y después de simular: los números deben ser idénticos.

## Estados de `cola_sync`

| Estado | Significado | ¿Es venta? |
|---|---|---|
| `PENDIENTE` | recién armada, sin evaluar | no |
| `RECHAZADO` | rojo: el servidor no la aceptaría | no |
| `CONFLICTO` | amarillo: cambió el precio | no |
| `SIMULADO_APROBADO` | verde: todo coincide | **no** |

> Kiro (consigna 4.a) no se entrega.
