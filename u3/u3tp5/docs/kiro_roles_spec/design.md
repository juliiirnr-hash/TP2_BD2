# Spec Roles — Food Store · Design

## 1. Punto de partida: lo que trae la copia de desarrollo (`respaldo_food_store.sql`)

Relevamiento sobre la copia de desarrollo/prueba con datos ficticios —nunca la
base original con datos reales (`protocolo_seguridad.md:1`)— (dump UTF-16,
Postgres 18.6 + bloque de carga `BEGIN; ... COMMIT;` al final):

- **Datos:** 20 `usuario`, 8 `categoria`, 50 `producto`, 10.500 `pedido`, 52.500
  `detalle_pedido`. Totales recalculados con `SUM(subtotal)` y `ANALYZE` final.
- **Ya existe y se reutiliza:** `v_productos_vigentes`, `v_pedidos_usuario`,
  `v_detalle_pedido_producto`, `rancking_dia` (matview diaria top-5, no sirve
  como mensual), función `verificar_estado_pedido()` y sus `CHECK`s
  (`subtotal = cantidad * precio_unitario`, irreversibilidad CONFIRMADO→PENDIENTE).
- **Ya otorgado:** solo `GRANT SELECT` sobre las 3 vistas a `rol_reportes`.
  No hay `CREATE ROLE` en el dump: los 5 grupos + 3 logins se crean desde cero.
- **A crear:** `v_categorias_vigentes`, `v_usuarios_publico`,
  `v_pedidos_resumen`, `mv_ventas_categoria_mes` y `sp_crear_pedido`.
  Sin esto, el modelo de clase no cubre catálogo de categorías, soporte sin
  claves, reporte mensual ni alta atómica de pedidos; y nadie puede mantener
  `producto`/`categoria` (motiva `rol_catalogo_admin`).

## 2. Principios

1. Grupos `NOLOGIN`, logins con `LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE`
   (salvo `admin_datos`: `CREATEDB CREATEROLE`, sin `SUPERUSER`).
2. Mínimo privilegio + denegación por defecto: `REVOKE ALL` antes de cada `GRANT`.
3. Lectura pública solo vía vistas con `eliminado = FALSE`; jamás tabla base.
4. Sin `DELETE`/`TRUNCATE`/`DDL` fuera de `admin_datos`; baja = `UPDATE eliminado`.
5. `sp_crear_pedido` en `SECURITY INVOKER` (no DEFINER) para no escalar: el que
   ejecuta ya tiene `INSERT` en `pedido`/`detalle_pedido` y nada más.
6. Scripts re-ejecutables: `CREATE ROLE` solo si no existe (`DO ... EXCEPTION`),
   `CREATE OR REPLACE` en vistas/función, `DROP ... IF EXISTS` + `CREATE` en matview.

## 3. Roles (DDL canónico)

```sql
-- Grupos (NOLOGIN)
DO $$ BEGIN CREATE ROLE rol_app_lectura     NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_app_escritura   NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_soporte         NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_reportes        NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_catalogo_admin  NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Logins (passwords de ejemplo: rotar en producción)
DO $$ BEGIN CREATE ROLE app_web             LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 100 PASSWORD 'cambiar_app_web'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE backoffice_catalogo LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 10  PASSWORD 'cambiar_backoffice'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE admin_datos         LOGIN INHERIT NOSUPERUSER CREATEDB CREATEROLE CONNECTION LIMIT 5 PASSWORD 'cambiar_admin'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Membresías (únicas; nada de pertenencias cruzadas)
GRANT rol_app_lectura, rol_app_escritura TO app_web;
GRANT rol_app_lectura, rol_catalogo_admin TO backoffice_catalogo;
-- admin_datos no es miembro de nadie: es OWNER (ver §6).
```

## 4. Objetos a crear (dueño: `admin_datos`)

```sql
-- 4.1 Catálogo de categorías (no existe en el respaldo)
CREATE OR REPLACE VIEW v_categorias_vigentes AS
SELECT id_categoria, nombre, descripcion
FROM categoria WHERE eliminado = FALSE;

-- 4.2 Soporte sin claves (no existe; aísla contrasena/rol)
CREATE OR REPLACE VIEW v_usuarios_publico AS
SELECT id_usuario, nombre, apellido, mail, celular
FROM usuario WHERE eliminado = FALSE;

CREATE OR REPLACE VIEW v_pedidos_resumen AS
SELECT p.id_pedido, p.fecha, p.estado, p.forma_pago, p.total,
       u.nombre AS usuario_nombre, u.apellido AS usuario_apellido, u.mail AS mail_usuario
FROM pedido p JOIN usuario u ON u.id_usuario = p.id_usuario
WHERE p.eliminado = FALSE AND u.eliminado = FALSE;

-- 4.3 Mensual por categoría (rancking_dia es diaria/top-5: no reutilizable)
DROP MATERIALIZED VIEW IF EXISTS mv_ventas_categoria_mes;
CREATE MATERIALIZED VIEW mv_ventas_categoria_mes AS
SELECT c.nombre AS categoria,
       date_trunc('month', p.fecha)::date AS mes,
       SUM(d.subtotal)::NUMERIC(10,2) AS total_vendido,
       COUNT(*) AS lineas
FROM detalle_pedido d
JOIN pedido p    ON p.id_pedido = d.id_pedido
JOIN producto pr ON pr.id_producto = d.id_producto
JOIN categoria c ON c.id_categoria = pr.id_categoria
WHERE d.eliminado = FALSE AND p.eliminado = FALSE AND p.estado <> 'CANCELADO'
GROUP BY 1, 2 WITH DATA;
CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_ventas_cat_mes
  ON mv_ventas_categoria_mes (categoria, mes); -- habilita REFRESH CONCURRENTLY con 52k filas

-- 4.4 Alta atómica de pedido (no existe en el respaldo)
-- p_items: '[{"id_producto":1,"cantidad":2}, ...]'
CREATE OR REPLACE FUNCTION sp_crear_pedido(p_id_usuario INT, p_forma_pago forma_pago, p_items JSONB)
RETURNS INT LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE v_pedido INT; r RECORD; v_precio NUMERIC(10,2);
BEGIN
  IF jsonb_array_length(p_items) = 0 THEN RAISE EXCEPTION 'pedido sin items'; END IF;
  INSERT INTO pedido (estado, forma_pago, total, id_usuario)
  VALUES ('PENDIENTE', p_forma_pago, 0, p_id_usuario) RETURNING id_pedido INTO v_pedido;
  FOR r IN SELECT (x->>'id_producto')::INT AS id_prod, (x->>'cantidad')::INT AS cant
           FROM jsonb_array_elements(p_items) x LOOP
    IF r.cant <= 0 THEN RAISE EXCEPTION 'cantidad inválida'; END IF;
    SELECT precio INTO v_precio FROM producto
    WHERE id_producto = r.id_prod AND eliminado = FALSE AND disponible = TRUE;
    IF NOT FOUND THEN RAISE EXCEPTION 'producto % no vigente', r.id_prod; END IF;
    INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, id_pedido, id_producto)
    VALUES (r.cant, v_precio, (r.cant * v_precio)::NUMERIC(10,2), v_pedido, r.id_prod);
  END LOOP;
  UPDATE pedido SET total = (SELECT COALESCE(SUM(subtotal),0) FROM detalle_pedido
    WHERE id_pedido = v_pedido AND eliminado = FALSE) WHERE id_pedido = v_pedido;
  RETURN v_pedido;
END $$;
```

## 5. Matriz de permisos (mínimo privilegio)

```sql
GRANT USAGE ON SCHEMA public TO rol_app_lectura, rol_app_escritura, rol_soporte, rol_reportes, rol_catalogo_admin;

-- Lectura catálogo (solo vistas; nunca tabla base)
REVOKE ALL ON TABLE v_productos_vigentes, v_categorias_vigentes FROM PUBLIC;
GRANT SELECT ON TABLE v_productos_vigentes, v_categorias_vigentes TO rol_app_lectura;

-- Compras (sin DELETE/TRUNCATE; el UPDATE es a nivel de columna)
REVOKE ALL ON TABLE pedido, detalle_pedido FROM rol_app_escritura;
GRANT SELECT, INSERT ON TABLE pedido, detalle_pedido TO rol_app_escritura;
GRANT UPDATE (estado) ON TABLE pedido TO rol_app_escritura; -- solo cambio de estado
GRANT UPDATE (cantidad, eliminado) ON TABLE detalle_pedido TO rol_app_escritura;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_app_escritura; -- identity de INSERT
GRANT USAGE ON TYPE forma_pago, estado_pedido TO rol_app_escritura;
REVOKE ALL ON FUNCTION sp_crear_pedido(INT, forma_pago, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION sp_crear_pedido(INT, forma_pago, JSONB) TO rol_app_escritura;

-- Soporte (solo vistas sin contrasena + lectura por columnas sin clave)
REVOKE ALL ON TABLE v_usuarios_publico, v_pedidos_resumen FROM PUBLIC;
GRANT SELECT ON TABLE v_usuarios_publico, v_pedidos_resumen TO rol_soporte;
GRANT SELECT (id_usuario, nombre, apellido, mail, celular) ON TABLE usuario TO rol_soporte; -- sin contrasena

-- Reportes (conserva los 3 GRANTs ya existentes en el respaldo + matview nueva)
GRANT SELECT ON TABLE v_productos_vigentes, v_pedidos_usuario, v_detalle_pedido_producto TO rol_reportes;
REVOKE ALL ON TABLE mv_ventas_categoria_mes FROM PUBLIC;
GRANT SELECT ON TABLE mv_ventas_categoria_mes TO rol_reportes;

-- Catálogo backoffice (baja lógica vía UPDATE; sin DELETE físico; UPDATE por columnas sin created_at)
REVOKE ALL ON TABLE producto, categoria FROM rol_catalogo_admin;
GRANT SELECT, INSERT ON TABLE producto, categoria TO rol_catalogo_admin;
GRANT UPDATE (nombre, descripcion, precio, stock, imagen, disponible, eliminado) ON TABLE producto TO rol_catalogo_admin;
GRANT UPDATE (nombre, descripcion, eliminado) ON TABLE categoria TO rol_catalogo_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_catalogo_admin;
```

Lo que cada rol **no** recibe (y por qué): `rol_app_lectura` nada en tablas
base (evita ver eliminados/`contrasena`); `rol_app_escritura` nada en
`producto`/`usuario` (el precio se congela vía snapshot en `sp_crear_pedido`);
`rol_soporte` nada en tablas base ni `EXECUTE` (evita modificar o ver claves);
`rol_reportes` nada de escritura ni `REFRESH` (el refresh lo hace el owner);
`rol_catalogo_admin` nada en `pedido`/`detalle_pedido` (separa catálogo de ventas).

## 6. Propiedad y objetos futuros

```sql
-- Migrar ownership del dump (hoy postgres) al DBA funcional:
-- ALTER VIEW/FUNCTION/MATERIALIZED VIEW ... OWNER TO admin_datos; (una por objeto)
-- Misma política para objetos futuros creados por admin_datos (ver roles.sql §10):
-- reportes lee toda tabla/vista futura; el resto se otorga explícito por objeto.
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public GRANT SELECT ON TABLES TO rol_reportes;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura, rol_catalogo_admin;
```

`REFRESH MATERIALIZED VIEW [CONCURRENTLY] mv_ventas_categoria_mes;` lo ejecuta
`admin_datos` (o job owner), nunca `rol_reportes`, por el volumen (52k detalles).

## 7. Orden de aplicación (re-ejecutable, en `food_store_dev`)

1. `BEGIN;` 2. Crear roles (§3). 3. Crear vistas/función/matview (§4, `OR REPLACE`).
4. Transferir ownership a `admin_datos`. 5. `REVOKE ALL` + `GRANT`s (§5).
6. Membresías (§3). 7. Verificación (§8). 8. `ROLLBACK` primero y, verificado,
   re-correr con `COMMIT`.

## 8. Verificación contra los datos del respaldo

```sql
-- Roles: 5 grupos NOLOGIN + 3 logins sin SUPERUSER
SELECT rolname, rolcanlogin, rolsuper FROM pg_roles
WHERE rolname IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes',
  'rol_catalogo_admin','app_web','backoffice_catalogo','admin_datos') ORDER BY 1;
-- Membresías exactas (app_web=2, backoffice=2, admin=0)
SELECT r.rolname AS login, m.rolname AS miembro FROM pg_auth_members a
JOIN pg_roles r ON r.oid=a.member JOIN pg_roles m ON m.oid=a.roleid
WHERE r.rolname IN ('app_web','backoffice_catalogo') ORDER BY 1,2;
-- Positivo con volumen real: ~47 productos vigentes (50 − 5% eliminados), 8 categorías
SET ROLE app_web; SELECT count(*) FROM v_productos_vigentes; SELECT count(*) FROM v_categorias_vigentes; RESET ROLE;
-- Soporte no ve claves: esta columna no debe existir
SET ROLE rol_soporte; SELECT * FROM v_usuarios_publico LIMIT 1; RESET ROLE; -- sin columna contrasena
-- Negativo: escritura compra denegada a backoffice, catálogo denegado a app_web
SET ROLE backoffice_catalogo; INSERT INTO pedido(total,id_usuario) VALUES (0,1); -- debe fallar
SET ROLE app_web; INSERT INTO producto(nombre,precio,id_categoria) VALUES ('x',1,1); -- debe fallar
RESET ROLE;
-- Reportes: matview poblada y legible
SET ROLE rol_reportes; SELECT count(*) FROM mv_ventas_categoria_mes; RESET ROLE;
```

Re-correr todo el script dos veces debe terminar sin error (idempotencia).

## 9. Decisiones y riesgos

- Se conserva `rancking_dia` intacta: es diaria/top-5 y lo pedido en clase es
  mensual por categoría; duplicarla como `mv_ventas_categoria_mes` evita romper
  lo que ya consumen reportes.
- `v_pedidos_usuario` del respaldo ya existe y contiene `mail/celular`; se
  reutiliza para reportes, mientras soporte usa la más estrecha
  `v_pedidos_resumen` (mismo join, menos columnas sensibles).
- Riesgo: los `GRANT ... TO rol_reportes` del dump conviven con los nuevos;
  el `REVOKE ALL` previo del §5 los normaliza sin duplicar permisos.
- Riesgo: `OVERRIDING SYSTEM VALUE` en la carga usa identities explícitos; los
  `GRANT USAGE, SELECT ON SEQUENCES` del §5 evitan `permission denied on sequence`
  al insertar desde `app_web`/`backoffice_catalogo`.
