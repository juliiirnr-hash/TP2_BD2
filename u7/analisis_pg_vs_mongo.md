# Análisis arquitectónico: PostgreSQL vs MongoDB para pedidos en Food Store

## Prompt original

> Actuá como un arquitecto de bases de datos senior. Analizá el sistema de la tienda Food Store para comparar PostgreSQL y MongoDB en cuanto al almacenamiento y la consulta de pedidos. Tené en cuenta el modelo actual (donde los pedidos se dividen en cabecera pedido y renglones en detalle_pedido), la necesidad del negocio de realizar accesos frecuentes a pedidos completos (cabecera + detalle de productos) y el requerimiento crítico de conservar la coherencia de cantidades, precios unitarios y subtotales acumulados en cada transacción. Explicá las ventajas, desventajas y el impacto técnico de cada motor para este escenario.

---

## Respuesta

# Análisis arquitectónico: PostgreSQL vs MongoDB para pedidos en Food Store

## 1. Contexto y modelo actual

El sistema Food Store hoy persiste un pedido en **dos tablas relacionales**:

- `pedido` (cabecera): `id_pedido, fecha, estado, forma_pago, total, id_usuario, eliminado, created_at`
- `detalle_pedido` (renglones): `id_detalle, cantidad, precio_unitario, subtotal, id_pedido, id_producto, eliminado, created_at`

Con reglas de dominio ya codificadas en el esquema:
- `subtotal = cantidad * precio_unitario` (CHECK)
- `precio_unitario` es **snapshot** del precio al momento de la compra (no se referencia `producto.precio`)
- `total` es una suma **cacheada** en la cabecera
- `estado` no puede volver de `CONFIRMADO` a `PENDIENTE` (trigger)
- FKs: `detalle_pedido.id_pedido → pedido` (CASCADE), `id_producto → producto` (RESTRICT), `pedido.id_usuario → usuario` (RESTRICT)
- Índices: `idx_pedido_usuario`, `idx_detalle_pedido`, parciales por `eliminado = FALSE`

Requerimientos del negocio:
1. **Accesos frecuentes a pedidos completos** (cabecera + detalle + datos de usuario/producto).
2. **Coherencia crítica** de cantidades, precios unitarios y subtotales acumulados en cada transacción.

---

## 2. PostgreSQL

### Ventajas

| Aspecto | Detalle |
|---|---|
| **ACID nativo y maduro** | Transacciones multi-sentencia por defecto; MVCC; aislamiento configurable (READ COMMITTED/REPEATABLE READ/SERIALIZABLE). |
| **Integridad declarativa** | FKs, `CHECK (subtotal = cantidad * precio_unitario)`, `UNIQUE(id_pedido, id_producto)`, `NOT NULL`, ENUMs (`estado_pedido`, `forma_pago`). La coherencia se **garantiza en el motor**, no en la app. |
| **Transacción atómica de creación** | `sp_crear_pedido(p_id_usuario, p_forma_pago, p_items JSONB)` inserta cabecera + N renglones + recalcula `total` en una sola transacción; si falla un renglón, se revierte todo. |
| **Snapshot histórico** | `precio_unitario`/`subtotal` como copia; el catálogo puede cambiar sin corromper pedidos pasados. |
| **Consultas analíticas** | SQL estándar, vistas (`v_pedidos_usuario`, `v_detalle_pedido_producto`, `v_pedidos_resumen`), vistas materializadas (`mv_ventas_categoria_mes`), agregaciones, window functions. |
| **Control de acceso fino** | Roles (`rol_app_escritura`, `rol_soporte`, `rol_reportes`) con GRANT por tabla/columna; RLS posible. |
| **Tipos exactos** | `NUMERIC(10,2)` evita errores de punto flotante en dinero (vs `float`/`double`). |
| **Escalabilidad vertical + particionamiento** | Particionamiento declarativo por fecha/usuario; índices B-tree/GIN/BRIN; `VACUUM`/`ANALYZE`. |

### Desventajas

| Aspecto | Detalle |
|---|---|
| **Acceso a pedido completo requiere JOIN** | Cabecera + detalle + usuario + producto implica `JOIN` entre 4 tablas. Con índices bien diseñados es rápido, pero no es una sola lectura de documento. |
| **Esquema rígido** | Cambios de estructura requieren migraciones DDL; coordinación en equipos. |
| **Escalamiento horizontal limitado** | Sharding no nativo (requiere Citus/extensiones o particionamiento manual). |
| **Overhead de mantenimiento** | VACUUM, bloat, tuning de `work_mem`/`shared_buffers`, gestión de conexiones (pgbouncer). |
| **Costo de escritura** | Insertar un pedido toca 2 tablas + índices + FK checks; más I/O que un doc embebido. |

### Impacto técnico

- **Modelo**: se mantiene el relacional actual; no hay migración de datos.
- **Performance de lectura**: `Index Scan` sobre `pedido` + `Index Only Scan` sobre `detalle_pedido` (índice cubriente) + `Incremental Sort`. Para 10.5k pedidos / 52.5k detalles es trivial.
- **Performance de escritura**: transacción corta; locks a nivel de fila; sin contención notable.
- **Coherencia**: máxima. El CHECK `subtotal = cantidad * precio_unitario` y la FK impiden inconsistencias incluso ante bugs de la app.
- **Operación**: backups con `pg_dump`/PITR, monitoreo con `pg_stat_statements`, slow log.

---

## 3. MongoDB

### Ventajas

| Aspecto | Detalle |
|---|---|
| **Documento embebido = pedido completo en una lectura** | Cabecera + array `detalle_pedido` en un solo documento. Acceso frecuente a pedido completo es **O(1) por `_id`**, sin JOIN, con localidad de datos en disco. |
| **Atomicidad a nivel de documento** | Una escritura de un documento embebido es atómica por defecto (sin transacción multi-doc). Si el pedido se modela como un solo doc, la coherencia interna (cabecera + renglones) se garantiza sin transacciones. |
| **Flexibilidad de esquema** | Evolución de campos sin migraciones DDL; útil si el catálogo cambia frecuentemente. |
| **Escalamiento horizontal nativo** | Sharding por `id_usuario` o `fecha`; réplicas para HA/lectura. |
| **Tipos para dinero** | `Decimal128` (BSON) para evitar float; mejor que `double`. |
| **Modelo natural para "pedido completo"** | El array embebido mapea directamente a la necesidad de negocio. |

### Desventajas

| Aspecto | Detalle |
|---|---|
| **Sin integridad referencial declarativa** | No hay FKs. Un `detalle_pedido.producto.id_producto` puede apuntar a un producto inexistente; la validación queda en la app o en validadores JSON Schema (menos expresivos que CHECK/FK). |
| **Coherencia cross-colección requiere transacciones** | Decrementar stock en `productos`, crear pedido, actualizar usuario: multi-doc transaction (MongoDB 4.0+) con overhead de locks, mayor latencia y restricciones (requiere replica set). |
| **Validación de aritmética limitada** | JSON Schema no expresa fácilmente `subtotal = cantidad * precio_unitario` ni `total = SUM(subtotal)`. Se puede usar `$expr` en validadores, pero es frágil y no estándar en tooling. |
| **Duplicación / desnormalización** | Si se embebe `usuario` o `producto` para evitar `$lookup`, se duplica data; cambios de catálogo no propagan a históricos (snapshot deseado, pero hay que gestionarlo). Si se referencia, hay que hacer `$lookup` (equivalente a JOIN, más costoso). |
| **Límite de 16 MB por documento** | Pedidos con miles de renglones o datos binarios (imágenes) pueden superar el límite; hay que paginar o referenciar. |
| **Consultas analíticas menos ergonómicas** | Aggregation pipeline vs SQL; menos maduro para reporting complejo. |
| **Operación** | Tuning de índices, sharding keys, balancer, write concern/read concern; backups con `mongodump`/oplog. |

### Impacto técnico

- **Modelo**: migración de relacional a documento embebido; hay que reescribir creación/consulta de pedidos.
- **Performance de lectura**: excelente para pedido completo por `_id`; peor para consultas cross-pedido (ej. "todos los pedidos que contienen producto X") → requiere índice multikey sobre `detalle_pedido.producto.id_producto` y retorna docs completos.
- **Performance de escritura**: un solo `insertOne` si se embebe (sin transaction); pero si se actualiza stock en otra colección, transaction multi-doc con latencia extra.
- **Coherencia**: interna (dentro del doc) fuerte; externa (stock, usuario) depende de la app y de transacciones. Riesgo de inconsistencia si no se implementa validación estricta.
- **Escalabilidad**: mejor horizontal, pero a costa de complejidad operativa.

---

## 4. Comparación directa

| Criterio | PostgreSQL | MongoDB |
|---|---|---|
| Acceso a pedido completo | JOIN (con índices, rápido) | Lectura única de documento (más rápido) |
| Coherencia cantidades/precios/subtotales | CHECK + FK + transaction (garantizado por motor) | Validación app + transaction multi-doc (garantizado por app) |
| Atomicidad creación de pedido | Transacción multi-tabla nativa | Documento único atómico (si se embebe) |
| Integridad referencial | Declarativa (FK) | No nativa |
| Tipos para dinero | `NUMERIC` exacto | `Decimal128` |
| Reporting/analítica | SQL maduro | Aggregation pipeline |
| Escalamiento horizontal | Limitado (particionamiento) | Nativo (sharding) |
| Esquema | Rígido (migraciones) | Flexible |
| Complejidad operativa | Media (VACUUM, tuning) | Alta (sharding, replica sets, write/read concern) |

---

## 5. Recomendación

Para Food Store, con el **requerimiento crítico de coherencia** (cantidades, precios unitarios, subtotales acumulados) y un modelo ya relacional con FKs/CHECKs/triggers:

> **PostgreSQL es la opción recomendada.**

Razones decisivas:
1. La coherencia no depende de que la aplicación "se acuerde" de validar; el motor la **impone** (`CHECK subtotal = cantidad * precio_unitario`, FKs, transacción en `sp_crear_pedido`).
2. `NUMERIC(10,2)` evita errores de redondeo en dinero.
3. El volumen actual (10.5k pedidos / 52.5k detalles) no justifica la complejidad de sharding; la performance de JOIN con índices es excelente.
4. Roles/RLS y vistas ya existen y son parte del entregable.

**MongoDB sería preferible solo si**:
- El acceso a pedidos completos fuera el cuello de botella dominante y no se pudiera resolver con índices/vistas materializadas.
- Se aceptara migrar la validación de coherencia a la aplicación con tests estrictos.
- Se necesitara escalamiento horizontal real y se dispusiera de equipo para operar replica sets/sharding.

**Opción híbrida (no recomendada por ahora)**: PostgreSQL como fuente de verdad + MongoDB como caché de documentos de pedido completo (materialized view). Agrega complejidad de sincronización (CDC/ETL) que no se justifica con el volumen actual.

---

## 6. Nota sobre el modelo embebido en Mongo (para referencia)

Si se migrara a Mongo, el documento natural sería:

```json
{
  "_id": 10108,
  "fecha": ISODate("..."),
  "estado": "CONFIRMADO",
  "forma_pago": "EFECTIVO",
  "total": 8930.28,
  "usuario": { "id_usuario": 11 },
  "detalle_pedido": [
    { "id_detalle": 249451, "cantidad": 7, "precio_unitario": 517.80, "subtotal": 3624.60, "producto": { "id_producto": 36 } }
  ]
}
```

Esto replica exactamente el esquema de `esquema_parte1.json` del repo. La coherencia interna del documento es atómica, pero **la coherencia con `stock` de productos y `total` cacheado** requeriría transacción multi-doc o validación en la app — que es precisamente el punto débil frente a PostgreSQL para este escenario.
