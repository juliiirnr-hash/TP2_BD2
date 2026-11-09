-- health_check.sql — Monitoreo de salud de foodstore (PostgreSQL 16+)
-- Ejecutar: psql -U postgres -d foodstore -f health_check.sql

-- 1. Tamaño total de la base
SELECT pg_size_pretty(pg_database_size('foodstore')) AS tamano_base;

-- 2. Actividad de conexiones y transacciones
SELECT numbackends,
       xact_commit,
       xact_rollback,
       (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_conexiones
FROM pg_stat_database
WHERE datname = 'foodstore';

-- 3. Estado de tablas y tuplas muertas (esquema public)
SELECT schemaname, relname, n_live_tup, n_dead_tup,
       CASE WHEN n_live_tup > 0
            THEN round(100.0 * n_dead_tup / n_live_tup, 2)
            ELSE 0 END AS pct_dead,
       last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- 4. Consultas activas con duración anómala (> 5 min)
SELECT pid, state, now() - query_start AS duracion, query
FROM pg_stat_activity
WHERE datname = 'foodstore'
  AND state <> 'idle'
  AND (now() - query_start) > interval '5 minutes';

-- 5. Tamaño por tabla e índices
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC;
