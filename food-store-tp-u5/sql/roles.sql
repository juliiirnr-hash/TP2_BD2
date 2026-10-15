-- roles.sql — Food Store · Roles y permisos (Unidad 5 - Clase 1 + rol de catálogo)
-- Spec: docs/kiro_roles_spec/requirements.md y design.md
-- Aplica DESPUÉS de schema.sql + vistas.sql (ver main.sql para el orden
-- completo en food_store_test), como owner (postgres) o admin_datos tras
-- transferir ownership, solo en la copia de pruebas con datos ficticios
-- (nunca la base original).
-- Re-ejecutable: la creación usa DO ... EXCEPTION (no falla si el rol existe),
-- los GRANT duplicados son idempotentes y cada bloque parte de REVOKE ALL.
-- Probar siempre primero con: BEGIN; \i roles.sql; <verificación §8>; ROLLBACK;

-- ============================================================
-- 1. ROLES DE GRUPO (NOLOGIN): 4 de clase + 1 adicional
-- ============================================================
DO $$ BEGIN CREATE ROLE rol_app_lectura    WITH NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_app_escritura  WITH NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_soporte        WITH NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_reportes       WITH NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_catalogo_admin WITH NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 2. ROLES DE LOGIN: 2 de clase + 1 adicional (passwords de ejemplo: rotar)
-- ============================================================
DO $$ BEGIN CREATE ROLE app_web WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 100 PASSWORD 'cambiar_app_web'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE backoffice_catalogo WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 10 PASSWORD 'cambiar_backoffice'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE admin_datos WITH LOGIN INHERIT NOSUPERUSER CREATEDB CREATEROLE CONNECTION LIMIT 5 PASSWORD 'cambiar_admin'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Fijar atributos aunque el rol ya existiera (el DO anterior no los actualiza)
ALTER ROLE rol_app_lectura    WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE rol_app_escritura  WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE rol_soporte        WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE rol_reportes       WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE rol_catalogo_admin WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE app_web             WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 100;
ALTER ROLE backoffice_catalogo WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE CONNECTION LIMIT 10;
ALTER ROLE admin_datos         WITH LOGIN INHERIT NOSUPERUSER CREATEDB CREATEROLE CONNECTION LIMIT 5;

-- ============================================================
-- 3. ESQUEMA: uso para todos, creación solo del owner
-- ============================================================
GRANT USAGE ON SCHEMA public TO rol_app_lectura, rol_app_escritura, rol_soporte, rol_reportes, rol_catalogo_admin;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- ============================================================
-- 4. CATÁLOGO PÚBLICO — rol_app_lectura (solo vistas, nunca tabla base)
-- ============================================================
REVOKE ALL ON TABLE v_productos_vigentes, v_categorias_vigentes FROM PUBLIC;
REVOKE ALL ON TABLE producto, categoria FROM rol_app_lectura;
GRANT SELECT ON TABLE v_productos_vigentes, v_categorias_vigentes TO rol_app_lectura;

-- ============================================================
-- 5. COMPRAS — rol_app_escritura (sin DELETE ni TRUNCATE: la baja es lógica
--    y la cancelación es cambio de estado; revocado vía REVOKE ALL previo)
-- ============================================================
REVOKE ALL ON TABLE pedido, detalle_pedido FROM PUBLIC;
REVOKE ALL ON TABLE pedido, detalle_pedido FROM rol_app_escritura;
GRANT SELECT, INSERT ON TABLE pedido, detalle_pedido TO rol_app_escritura;
-- CASO COLUMNA-1: UPDATE restringido a una columna. En pedido solo se puede
-- tocar estado (PENDIENTE→CONFIRMADO/TERMINADO/CANCELADO); total, id_usuario,
-- fecha y eliminado los mueve sp_crear_pedido o el owner, no el backend.
GRANT UPDATE (estado) ON TABLE pedido TO rol_app_escritura;
-- En el detalle solo cantidad (corrección) y eliminado (baja lógica); el
-- snapshot precio_unitario/subtotal lo fija el INSERT vía sp_crear_pedido.
GRANT UPDATE (cantidad, eliminado) ON TABLE detalle_pedido TO rol_app_escritura;
GRANT USAGE, SELECT ON SEQUENCE pedido_id_pedido_seq, detalle_pedido_id_detalle_seq TO rol_app_escritura;
GRANT USAGE ON TYPE forma_pago, estado_pedido TO rol_app_escritura;
REVOKE ALL ON FUNCTION sp_crear_pedido(INT, forma_pago, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION sp_crear_pedido(INT, forma_pago, JSONB) TO rol_app_escritura;

-- ============================================================
-- 6. SOPORTE — rol_soporte (sin claves ni escritura)
-- ============================================================
REVOKE ALL ON TABLE v_usuarios_publico, v_pedidos_resumen FROM PUBLIC;
REVOKE ALL ON TABLE usuario, pedido, detalle_pedido FROM rol_soporte;
GRANT SELECT ON TABLE v_usuarios_publico, v_pedidos_resumen TO rol_soporte;
-- CASO COLUMNA-2: lectura directa a tabla base limitada a columnas no
-- sensibles (respaldo ante consultas fuera de la vista). Excluye a propósito
-- contrasena, rol, created_at y eliminado: ni la clave ni el rol interno
-- pueden ser visibles para atención al cliente.
GRANT SELECT (id_usuario, nombre, apellido, mail, celular) ON TABLE usuario TO rol_soporte;

-- ============================================================
-- 7. REPORTES — rol_reportes (lectura analítica; el REFRESH lo hace el owner)
-- ============================================================
REVOKE ALL ON TABLE v_productos_vigentes, v_pedidos_usuario, v_detalle_pedido_producto FROM rol_reportes;
GRANT SELECT ON TABLE v_productos_vigentes, v_pedidos_usuario, v_detalle_pedido_producto TO rol_reportes;
REVOKE ALL ON TABLE mv_ventas_categoria_mes FROM PUBLIC;
REVOKE ALL ON TABLE mv_ventas_categoria_mes FROM rol_reportes;
GRANT SELECT ON TABLE mv_ventas_categoria_mes TO rol_reportes;

-- ============================================================
-- 8. CATÁLOGO BACKOFFICE — rol_catalogo_admin (adicional; separa ventas de
--    catálogo; baja lógica vía UPDATE eliminado, sin DELETE físico)
-- ============================================================
REVOKE ALL ON TABLE producto, categoria FROM PUBLIC;
REVOKE ALL ON TABLE producto, categoria FROM rol_catalogo_admin;
REVOKE ALL ON TABLE pedido, detalle_pedido FROM rol_catalogo_admin;
GRANT SELECT, INSERT ON TABLE producto, categoria TO rol_catalogo_admin;
-- CASO COLUMNA-3: el UPDATE excluye id_categoria PK-ajena salvo corrección y,
-- sobre todo, created_at (auditoría solo del owner). La baja es UPDATE eliminado.
GRANT UPDATE (nombre, descripcion, precio, stock, imagen, disponible, eliminado) ON TABLE producto TO rol_catalogo_admin;
GRANT UPDATE (nombre, descripcion, eliminado) ON TABLE categoria TO rol_catalogo_admin;
GRANT USAGE, SELECT ON SEQUENCE producto_id_producto_seq, categoria_id_categoria_seq TO rol_catalogo_admin;

-- ============================================================
-- 9. MEMBRESÍAS EXACTAS (herencia vía INHERIT; admin_datos no es miembro:
--    es OWNER y delega con CREATEROLE)
-- ============================================================
REVOKE rol_soporte, rol_reportes, rol_catalogo_admin FROM app_web;
REVOKE rol_app_escritura, rol_soporte, rol_reportes, rol_catalogo_admin FROM backoffice_catalogo;
GRANT rol_app_lectura, rol_app_escritura TO app_web;
GRANT rol_app_lectura, rol_catalogo_admin TO backoffice_catalogo;

-- ============================================================
-- 10. OBJETOS FUTUROS — misma política por defecto para lo que cree
--     admin_datos (dueño funcional del esquema)
-- ============================================================
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public REVOKE ALL ON SEQUENCES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM PUBLIC;
-- Toda tabla/vista futura (nuevas dimensiones o hechos de venta) nace legible
-- para el panel gerencial, igual que las 3 vistas + matview actuales.
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public GRANT SELECT ON TABLES TO rol_reportes;
-- Sus identities siguen usables por los dos roles que insertan (pedidos y
-- catálogo); el resto de permisos sobre objetos futuros se otorga explícito
-- objeto por objeto (§4-§8), nunca por defecto.
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura, rol_catalogo_admin;

-- ============================================================
-- 11. VERIFICACIÓN (correr tras aplicar; §8 del design)
-- ============================================================
-- SELECT rolname, rolcanlogin, rolsuper FROM pg_roles
-- WHERE rolname IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes',
--   'rol_catalogo_admin','app_web','backoffice_catalogo','admin_datos') ORDER BY 1;
-- SET ROLE app_web; SELECT count(*) FROM v_productos_vigentes; RESET ROLE;
-- SET ROLE rol_soporte; SELECT * FROM v_usuarios_publico LIMIT 1; RESET ROLE; -- sin contrasena
-- SET ROLE backoffice_catalogo; INSERT INTO pedido(total,id_usuario) VALUES (0,1); RESET ROLE; -- debe fallar
-- SET ROLE app_web; INSERT INTO producto(nombre,precio,id_categoria) VALUES ('x',1,1); RESET ROLE; -- debe fallar
