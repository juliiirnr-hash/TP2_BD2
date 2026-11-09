-- creo la vista de la instantanea (correr en food_store_test)
-- el precio esta en pesos: lo paso a centavos
CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT
    p.id_producto                 AS id,
    p.nombre                      AS nombre,
    ROUND(p.precio * 100)::bigint AS precio_centavos,
    p.stock                       AS stock_visto,
    p.disponible                  AS disponible,
    p.eliminado                   AS eliminado,
    now()                         AS fecha_copia
FROM producto p;

-- control
SELECT id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia
FROM v_snapshot_movil
ORDER BY id
LIMIT 10;
