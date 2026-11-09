-- pruebas de la consigna 1.c
-- requiere haber corrido schema_sqlite.sql
-- ojo: borra producto_cache, asi que conviene correrlo sobre una copia de la base

PRAGMA foreign_keys = ON;

-- limpio las tablas
DELETE FROM cola_sync;
DELETE FROM item_borrador;
DELETE FROM pedido_borrador;
DELETE FROM producto_cache;

-- cargo un catalogo inventado
INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia) VALUES
  (1, 'Empanada de carne',  35000, 20, 1, 0, '2026-11-08 10:00:00'),
  (2, 'Empanada de pollo',  35000, 15, 1, 0, '2026-11-08 10:00:00'),
  (3, 'Gaseosa 500 ml',     25000, 10, 1, 0, '2026-11-08 10:00:00'),
  (4, 'Flan casero',        20000,  0, 1, 0, '2026-11-08 10:00:00'),  -- sin stock
  (5, 'Pizza muzzarella',   90000,  8, 0, 0, '2026-11-08 10:00:00'),  -- no disponible
  (6, 'Tarta de verduras',  70000,  5, 1, 1, '2026-11-08 10:00:00');  -- dada de baja

SELECT 'Catalogo cargado: ' || COUNT(*) || ' filas' AS paso_0 FROM producto_cache;

-- 1.a: guardo un borrador completo con commit
SELECT '--- 1.a: borrador completo con COMMIT ---' AS paso;

BEGIN;
  INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
  VALUES ('11111111-1111-4111-8111-111111111111', 'cliente_demo', 'EFECTIVO', '2026-11-08 10:05:00');

  INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
  VALUES ('11111111-1111-4111-8111-111111111111', 1, 2, 35000);

  INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
  VALUES ('11111111-1111-4111-8111-111111111111', 3, 1, 25000);

  INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
  VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          '11111111-1111-4111-8111-111111111111', 'PENDIENTE', 'armado sin senal');
COMMIT;

SELECT 'Filas: pedidos=' || (SELECT COUNT(*) FROM pedido_borrador)
    || ' items='   || (SELECT COUNT(*) FROM item_borrador)
    || ' cola='    || (SELECT COUNT(*) FROM cola_sync) AS resultado_1a;

SELECT id_local, producto_id, cantidad, precio_centavos_visto,
       cantidad * precio_centavos_visto AS subtotal_centavos
FROM item_borrador
WHERE id_local = '11111111-1111-4111-8111-111111111111';

-- 1.b: hago una operacion y la deshago con rollback
SELECT '--- 1.b: operacion deshecha con ROLLBACK ---' AS paso;

BEGIN;
  INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
  VALUES ('22222222-2222-4222-8222-222222222222', 'cliente_demo', 'TARJETA', '2026-11-08 10:09:00');

  INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
  VALUES ('22222222-2222-4222-8222-222222222222', 2, 5, 35000);

  INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
  VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          '22222222-2222-4222-8222-222222222222', 'PENDIENTE', 'prueba de rollback');
ROLLBACK;

SELECT 'Filas: pedidos=' || (SELECT COUNT(*) FROM pedido_borrador)
    || ' items='   || (SELECT COUNT(*) FROM item_borrador)
    || ' cola='    || (SELECT COUNT(*) FROM cola_sync) AS resultado_1b;

SELECT 'Filas del borrador deshecho (debe dar 0): '
    || (SELECT COUNT(*) FROM pedido_borrador
        WHERE id_local = '22222222-2222-4222-8222-222222222222') AS chequeo_rollback;

-- C1: consulto el catalogo disponible sin conectarme al servidor
SELECT '--- C1: catalogo disponible sin servidor ---' AS paso;

SELECT id, nombre, precio_centavos, stock_visto
FROM producto_cache
WHERE disponible = 1
  AND eliminado  = 0
  AND stock_visto > 0
ORDER BY nombre;

-- C7.a: inserto cantidad 0 y tiene que fallar
SELECT '--- C7.a: cantidad 0 debe fallar ---' AS paso;

SELECT 'items antes = ' || COUNT(*) AS antes_c7a FROM item_borrador;

SAVEPOINT c7a;
  INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
  VALUES ('11111111-1111-4111-8111-111111111111', 2, 0, 35000);   -- error esperado
ROLLBACK TO c7a;
RELEASE c7a;

SELECT 'items despues = ' || COUNT(*) AS despues_c7a FROM item_borrador;

-- C7.b: inserto un producto que no existe y tiene que fallar
SELECT '--- C7.b: producto inexistente debe fallar ---' AS paso;

SELECT 'items antes = ' || COUNT(*) AS antes_c7b FROM item_borrador;

SAVEPOINT c7b;
  INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
  VALUES ('11111111-1111-4111-8111-111111111111', 999, 1, 10000); -- error esperado
ROLLBACK TO c7b;
RELEASE c7b;

SELECT 'items despues = ' || COUNT(*) AS despues_c7b FROM item_borrador;

-- estado final de la base
SELECT '--- Estado final ---' AS paso;
SELECT 'producto_cache' AS tabla, COUNT(*) AS filas FROM producto_cache
UNION ALL SELECT 'pedido_borrador', COUNT(*) FROM pedido_borrador
UNION ALL SELECT 'item_borrador',   COUNT(*) FROM item_borrador
UNION ALL SELECT 'cola_sync',       COUNT(*) FROM cola_sync;
