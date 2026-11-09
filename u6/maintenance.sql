-- maintenance.sql — Revisión de autovacuum/ANALYZE para foodstore (PostgreSQL 16+)
-- Ejecutar tras health_check.sql. NO usar VACUUM FULL (bloqueo exclusivo).

-- Diagnóstico previo: tuplas muertas por tabla
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- Acción justificada: ANALYZE sobre tablas con alta actividad DML
ANALYZE VERBOSE detalle_pedido;
ANALYZE VERBOSE pedido;
ANALYZE VERBOSE producto;

-- Se confía en el autovacuum configurado en PostgreSQL 16.
-- VACUUM FULL no se usa como mantenimiento periódico.
