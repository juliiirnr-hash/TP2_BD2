# Bitácora de uso de IA

Registro de lo que le pedí a la IA, qué acepté, qué descarté y cómo lo comprobé.
Todo lo aceptado se ejecutó antes de darlo por bueno.

---

## Entrada 1 — Esquema de la tablet (1.b)

- **Qué le pedí:** el `schema_sqlite.sql` con las cuatro tablas del TP, con
  `PRAGMA foreign_keys = ON`, centavos enteros y `CHECK`.
- **Qué acepté:** tablas `STRICT`, claves primarias, las dos claves foráneas de
  `item_borrador`, los `CHECK` de forma de pago, estado, cantidad y precio, y
  `DROP TABLE IF EXISTS` para poder re-ejecutar el script.
- **Qué descarté:** el tipo `UUID` (SQLite no lo tiene, va `TEXT`) y el tipo
  `date` (va `TEXT` en ISO-8601, porque `STRICT` solo acepta `INTEGER`, `TEXT`,
  `REAL`, `BLOB` y `ANY`).
- **Cómo lo comprobé:** `PRAGMA table_list` mostró `strict = 1` en las cuatro
  tablas, y `PRAGMA foreign_key_list(item_borrador)` mostró las dos claves
  foráneas.

## Entrada 2 — Pruebas de la base (1.c)

- **Qué le pedí:** el `pruebas_sqlite.sql` con el borrador completo en
  `BEGIN … COMMIT`, una operación deshecha con `ROLLBACK`, el caso C1 y el C7.
- **Qué acepté:** envolver cada error de C7 en `SAVEPOINT … ROLLBACK TO …
  RELEASE`, para que el error no deje una transacción abierta ni filas a medias.
- **Qué descarté:** correrlo con `executescript` de Python. Corta en el primer
  error y nunca llega a C7; con la CLI de `sqlite3` el script sigue y se ven los
  dos errores esperados.
- **Cómo lo comprobé:** corrida real sobre una copia. En C7 el conteo de
  `item_borrador` quedó en 2 antes y 2 después, con los errores
  `CHECK constraint failed` y `FOREIGN KEY constraint failed`.

## Entrada 3 — El semáforo (2.b)

- **Qué le pedí:** la consulta que clasifica cada solicitud `PENDIENTE` en
  `RECHAZADO`, `CONFLICTO` o `SIMULADO_APROBADO`.
- **Qué acepté:** el `LEFT JOIN` contra `snapshot_servidor` (para que un producto
  que ya no está en la instantánea cuente como rojo) y `SUM(CASE …)` agrupado
  por solicitud, con `group_concat` para que el motivo diga qué producto falló.
- **Qué descarté:** comparar contra `producto_cache`. La caché puede estar
  vieja; la decisión se toma contra la instantánea nueva. También descarté que
  el semáforo actualice `producto_cache` o escriba en PostgreSQL.
- **Cómo lo comprobé:** siete solicitudes de prueba que cubren los cuatro
  motivos de rojo, el amarillo y el verde. Corrí el script tres veces seguidas y
  la tercera dio exactamente lo mismo: solo evalúa `PENDIENTE`.

## Entrada 4 — Code review de la cursada (3.c)

- **Qué le pedí:** revisar los scripts de las unidades anteriores y de este TP.
- **Qué acepté:** el hallazgo de que `pruebas_sqlite.sql` borra
  `producto_cache`, y el de que `semaforo.sql` depende de una tabla que el
  schema no crea. Los dos se corrigieron (aviso y README).
- **Qué descarté:** sacar el `DESC` del índice `idx_producto_stock`. El plan de
  ejecución es el mismo, porque PostgreSQL recorre el B-Tree al revés.
- **Cómo lo comprobé:** `EXPLAIN` mostró `Index Scan Backward` usando un índice
  creado en orden ascendente, y el conteo de `producto_cache` pasó de 50.001 a 6
  al correr las pruebas sobre una copia.
