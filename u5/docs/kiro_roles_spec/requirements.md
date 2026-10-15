# Spec Roles — Food Store · Requirements

## 1. Objetivo

Relevar los roles reales que necesita Food Store sobre PostgreSQL, tomando como base
mínima los 4 roles de grupo (NOLOGIN) y los 2 roles de login vistos en clase
(ver foto adjunta del resumen Unidad 5 - Clase 1), más 1 rol de grupo y 1 rol de
login adicionales para cubrir el mantenimiento del catálogo, que en el modelo de
clase queda sin dueño.

Fuente de verdad del modelo: `schema.sql:5-66` (tablas `categoria`, `usuario`,
`producto`, `pedido`, `detalle_pedido`) contrastado con `respaldo_food_store.sql`
como copia de trabajo de desarrollo/prueba con datos ficticios (nunca la base
original con datos reales, según `protocolo_seguridad.md:1`).

### 1.1 Evidencia de la copia de desarrollo/prueba (datos ficticios)

- Tablas: `categoria` (8 filas), `usuario` (20 filas, 2 `ADMIN`), `producto`
  (50 filas), `pedido` (10.500 filas: 10.000 últimos 30 días + 500 de hoy),
  `detalle_pedido` (52.500 filas, ~5 por pedido, `subtotal = cantidad * precio`).
- Objetos que ya existen: `v_productos_vigentes`, `v_pedidos_usuario`,
  `v_detalle_pedido_producto`, materializada `rancking_dia` (top-5 categorías
  del día, `WITH NO DATA`) y función `verificar_estado_pedido()` + trigger
  `trg_pedido_estado_irreversible`.
- Permisos que ya existen: solo 3 `GRANT SELECT ... TO rol_reportes` sobre las
  3 vistas; no hay `CREATE ROLE` en el dump (los roles son globales y no se
  exportan con `pg_dump` estándar), por lo que todos los roles hay que
  crearlos.
- Brechas: no existen `v_categorias_vigentes`, `v_usuarios_publico`,
  `v_pedidos_resumen`, `mv_ventas_categoria_mes` (la `rancking_dia` es diaria y
  top-5, no mensual por categoría) ni `sp_crear_pedido`; el mantenimiento de
  `producto`/`categoria` no tiene rol asignado.

## 2. Glosario / objetos

| Objeto | Estado en el repo | Uso previsto por roles |
|---|---|---|
| `v_productos_vigentes` | Existe (ver `specs/spec_vista_productos_vigentes.md`) | Catálogo público |
| `v_categorias_vigentes` | A crear (`id_categoria, nombre, descripcion` con `eliminado = FALSE`) | Catálogo público |
| `pedido`, `detalle_pedido` | Existen en `schema.sql:40-66` | Flujo de compras |
| `sp_crear_pedido` | A crear (crea `pedido` + detalles en una transacción, recalcula `total`, valida stock) | Flujo de compras atómico |
| `v_usuarios_publico` | A crear (`id_usuario, nombre, apellido, mail, celular` sin `contrasena`, con `eliminado = FALSE`) | Soporte |
| `v_pedidos_resumen` | A crear (`id_pedido, fecha, estado, forma_pago, total, usuario_nombre, usuario_apellido, mail_usuario`) sin `contrasena` | Soporte |
| `mv_ventas_categoria_mes` | A crear (materializada: `categoria, mes, total_vendido, cantidad`) + `REFRESH` programado | Reportes |
| `producto`, `categoria` (tablas base) | Existen en `schema.sql:5-38` | Mantenimiento catálogo (rol adicional) |

## 3. Roles requeridos y justificación (una oración por rol)

> Cada fila justifica qué operación habilita y por qué esa operación, y no otra.

### 3.1 Grupos (NOLOGIN) — vistos en clase

| Rol | Justificación en una oración |
|---|---|
| `rol_app_lectura` | Habilita solo `SELECT` en `v_productos_vigentes` y `v_categorias_vigentes` porque el catálogo público solo necesita lectura ya filtrada por `eliminado = FALSE`, y no `SELECT` directo a `producto`/`categoria` para no exponer filas eliminadas ni columnas internas ni permitir escritura. |
| `rol_app_escritura` | Habilita `SELECT, INSERT, UPDATE` en `pedido`/`detalle_pedido` más `EXECUTE` en `sp_crear_pedido` porque el flujo de compra necesita crear y confirmar pedidos línea por línea, y no `DELETE`/`TRUNCATE`/`DDL` porque la cancelación es cambio de `estado` y la baja es lógica (`eliminado`). |
| `rol_soporte` | Habilita solo `SELECT` en `v_usuarios_publico` y `v_pedidos_resumen` porque atención al cliente necesita identificar usuario y estado del pedido, y no acceso a `usuario.contrasena` ni a tablas base para no exponer claves ni permitir modificación. |
| `rol_reportes` | Habilita solo `SELECT` en `mv_ventas_categoria_mes` y vistas analíticas (`v_detalle_pedido_producto`, `v_pedidos_usuario`) porque el panel gerencial solo agrega ventas históricas con snapshot (`precio_unitario`, `total`), y no `INSERT/UPDATE/DELETE` para no alterar hechos de venta. |

### 3.2 Logins — vistos en clase

| Rol | Justificación en una oración |
|---|---|
| `app_web` | Es `LOGIN` miembro de `rol_app_lectura + rol_app_escritura` porque el backend necesita servir catálogo y ejecutar compras con una sola credencial heredada, y no `SUPERUSER`/`OWNER` para no poder hacer DDL ni bypassear RLS/GRANTs. |
| `admin_datos` | Es `LOGIN` dueño del esquema con `CREATEDB + CREATEROLE` (sin `SUPERUSER`) porque el DBA necesita crear bases/objetos y delegar membresías, y no `SUPERUSER` para no poder deshabilitar auditoría ni leer fuera de `food_store_dev`. |

### 3.3 Adicionales — necesarios para esta versión del proyecto

| Rol | Justificación en una oración |
|---|---|
| `rol_catalogo_admin` (grupo, NOLOGIN) | Habilita `SELECT, INSERT, UPDATE` (baja por `UPDATE eliminado = TRUE`) en `producto`/`categoria` porque el backoffice necesita alta y corrección de catálogo con `CHECK (precio/stock >= 0)`, y no `DELETE` físico/`TRUNCATE`/`DDL` ni acceso a `pedido` para no romper historial ni mezclar ventas con catálogo. |
| `backoffice_catalogo` (login) | Es `LOGIN` miembro de `rol_app_lectura + rol_catalogo_admin` porque el operador de catálogo necesita ver el catálogo publicado y mantenerlo, y no de `rol_app_escritura`/`rol_soporte`/`rol_reportes` para no crear pedidos ni ver reportes gerenciales. |

## 4. Requisitos funcionales

- **REQ-01.** Los roles de grupo se crean con `NOLOGIN`; solo los logins conectan.
- **REQ-02.** Ningún rol salvo `admin_datos` (owner) tiene `SUPERUSER`, `CREATEDB` o `CREATEROLE`.
- **REQ-03.** `rol_app_lectura` obtiene `SELECT` únicamente sobre las dos vistas de catálogo, no sobre tablas base.
- **REQ-04.** `rol_app_escritura` obtiene `SELECT, INSERT, UPDATE` sobre `pedido` y `detalle_pedido` y `EXECUTE` sobre `sp_crear_pedido`; explícitamente sin `DELETE` ni `TRUNCATE`.
- **REQ-05.** `rol_soporte` obtiene `SELECT` únicamente sobre `v_usuarios_publico` y `v_pedidos_resumen`; la columna `usuario.contrasena` no debe ser visible por ningún objeto otorgado a este rol.
- **REQ-06.** `rol_reportes` obtiene `SELECT` únicamente sobre `mv_ventas_categoria_mes` y vistas analíticas de lectura; el refresh de la matview lo ejecuta `admin_datos` o un job owner, no el rol.
- **REQ-07.** `rol_catalogo_admin` obtiene `SELECT, INSERT, UPDATE` sobre `producto` y `categoria`, sin `DELETE` físico; la baja es `UPDATE ... SET eliminado = TRUE`.
- **REQ-08.** `app_web` es miembro de `rol_app_lectura` y `rol_app_escritura` y de ningún otro grupo.
- **REQ-09.** `backoffice_catalogo` es miembro de `rol_app_lectura` y `rol_catalogo_admin` y de ningún otro grupo.
- **REQ-10.** `admin_datos` es `OWNER` de esquema, vistas, matview y función; otorga con `GRANT` explícitos y `ALTER DEFAULT PRIVILEGES` para objetos futuros.
- **REQ-11.** Todo script de roles es re-ejecutable (`DROP ROLE IF EXISTS` / `CREATE ROLE`, `REVOKE ALL` previo a `GRANT`, `CREATE OR REPLACE VIEW/FUNCTION`).

## 5. Requisitos no funcionales / seguridad

- **NFR-01.** Mínimo privilegio: denegar por defecto, otorgar solo lo listado en la matriz (ver `design.md`).
- **NFR-02.** Separación de credenciales: `app_web`, `backoffice_catalogo` y `admin_datos` con passwords distintos, nunca compartidos con grupos.
- **NFR-03.** Trabajo solo en `food_store_dev`; cada cambio en transacción `BEGIN → verificar → ROLLBACK/COMMIT` según `AGENTS.md`.
- **NFR-04.** Sin `DELETE` físico desde roles de app/soporte/reportes/catálogo; rige borrado lógico (`eliminado`) e índices parciales `WHERE eliminado = FALSE`.

## 6. Criterios de aceptación

1. `SELECT * FROM information_schema` (o `pg_roles`) muestra los 5 grupos con `rolcanlogin = false` y los 3 logins con `rolcanlogin = true`, `rolsuper = false`.
2. `SET ROLE app_web; SELECT * FROM v_productos_vigentes` ok; `DELETE FROM pedido` falla por permiso denegado.
3. `SET ROLE backoffice_catalogo; UPDATE producto SET precio = ...` ok; `INSERT INTO pedido ...` falla.
4. `SET ROLE` a cualquier rol no-owner sobre `usuario` directo falla; `SELECT * FROM v_usuarios_publico` no contiene columna `contrasena`.
5. Re-correr el script dos veces no devuelve error.

## 7. Fuera de alcance

DDL de tablas del dominio, datos de prueba, RLS por fila, auditoría por trigger y scheduling del `REFRESH MATERIALIZED VIEW` (se referencian pero no se implementan en esta spec).
