-- main.sql — Food Store · Script principal para food_store_test
-- Orden correcto de ejecución (los GRANTs de roles.sql exigen que las
-- relaciones ya existan; por eso roles.sql va ÚLTIMO):
--   1. schema.sql      → tipos, tablas, índices, trigger
--   2. vistas.sql      → vistas, materializada y sp_crear_pedido
--   3. carga_datos.sql → datos ficticios de prueba (solo INSERTs)
--   4. roles.sql       → CREATE ROLE + REVOKE/GRANT + DEFAULT PRIVILEGES
--
-- Uso (base de pruebas con datos ficticios; nunca la base original):
--   createdb -U postgres food_store_test
--   psql -U postgres -d food_store_test -f main.sql
-- Si un paso falla, nada de lo posterior se ejecuta (\set ON_ERROR_STOP).

\set ON_ERROR_STOP on
\echo '=== [1/4] schema.sql: tipos, tablas, índices, trigger ==='
\ir schema.sql
\echo '=== [2/4] vistas.sql: vistas, matview, sp_crear_pedido ==='
\ir vistas.sql
\echo '=== [3/4] carga_datos.sql: datos ficticios ==='
\ir carga_datos.sql
\echo '=== [4/4] roles.sql: roles y permisos ==='
\ir roles.sql
\echo '=== OK: food_store_test lista (esquema + vistas + datos + roles) ==='

-- Verificación rápida opcional (descomentar para probar tras la carga):
-- SELECT count(*) AS productos_vigentes FROM v_productos_vigentes;
-- SELECT count(*) AS categorias_vigentes FROM v_categorias_vigentes;
-- SELECT count(*) AS filas_matview FROM mv_ventas_categoria_mes;
-- SELECT rolname, rolcanlogin, rolsuper FROM pg_roles
-- WHERE rolname LIKE 'rol\_%' OR rolname IN ('app_web','backoffice_catalogo','admin_datos') ORDER BY 1;
