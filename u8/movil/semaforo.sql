-- semaforo de la cola de sincronizacion (consigna 2.b)
-- compara cada solicitud PENDIENTE contra la instantanea del servidor
-- y guarda el estado y el motivo en cola_sync. no toca PostgreSQL.
--
-- rojo    RECHAZADO          no existe, no esta disponible, dado de baja o sin stock
-- amarillo CONFLICTO         no hay rojo, pero cambio algun precio
-- verde   SIMULADO_APROBADO  todo coincide (no es una venta)

WITH evaluacion AS (
    SELECT
        c.solicitud_uuid,
        SUM(CASE WHEN s.id IS NULL THEN 1 ELSE 0 END) AS faltantes,
        SUM(CASE WHEN s.id IS NOT NULL
                  AND LOWER(s.disponible) NOT IN ('t', 'true', '1') THEN 1 ELSE 0 END) AS no_disponibles,
        SUM(CASE WHEN s.id IS NOT NULL
                  AND LOWER(s.eliminado) IN ('t', 'true', '1') THEN 1 ELSE 0 END) AS dados_de_baja,
        SUM(CASE WHEN s.id IS NOT NULL
                  AND i.cantidad > CAST(s.stock_visto AS INTEGER) THEN 1 ELSE 0 END) AS sin_stock,
        SUM(CASE WHEN s.id IS NOT NULL
                  AND i.precio_centavos_visto <> CAST(s.precio_centavos AS INTEGER) THEN 1 ELSE 0 END) AS precios_distintos,
        group_concat(CASE WHEN s.id IS NULL THEN i.producto_id END) AS ids_faltantes,
        group_concat(CASE WHEN s.id IS NOT NULL
                           AND LOWER(s.disponible) NOT IN ('t', 'true', '1') THEN i.producto_id END) AS ids_no_disponibles,
        group_concat(CASE WHEN s.id IS NOT NULL
                           AND LOWER(s.eliminado) IN ('t', 'true', '1') THEN i.producto_id END) AS ids_dados_de_baja,
        group_concat(CASE WHEN s.id IS NOT NULL
                           AND i.cantidad > CAST(s.stock_visto AS INTEGER) THEN i.producto_id END) AS ids_sin_stock,
        group_concat(CASE WHEN s.id IS NOT NULL
                           AND i.precio_centavos_visto <> CAST(s.precio_centavos AS INTEGER) THEN i.producto_id END) AS ids_con_precio_distinto
    FROM cola_sync c
    JOIN item_borrador i ON i.id_local = c.id_local
    LEFT JOIN snapshot_servidor s ON CAST(s.id AS INTEGER) = i.producto_id
    WHERE c.estado = 'PENDIENTE'
    GROUP BY c.solicitud_uuid
)
UPDATE cola_sync
SET estado = CASE
        WHEN e.faltantes > 0 OR e.no_disponibles > 0
          OR e.dados_de_baja > 0 OR e.sin_stock > 0 THEN 'RECHAZADO'
        WHEN e.precios_distintos > 0 THEN 'CONFLICTO'
        ELSE 'SIMULADO_APROBADO'
    END,
    motivo = CASE
        WHEN e.faltantes > 0          THEN 'no existe en el servidor: ' || e.ids_faltantes
        WHEN e.no_disponibles > 0     THEN 'no disponible: ' || e.ids_no_disponibles
        WHEN e.dados_de_baja > 0      THEN 'dado de baja: ' || e.ids_dados_de_baja
        WHEN e.sin_stock > 0          THEN 'stock insuficiente: ' || e.ids_sin_stock
        WHEN e.precios_distintos > 0  THEN 'cambio el precio: ' || e.ids_con_precio_distinto
        ELSE 'todo coincide'
    END
FROM evaluacion e
WHERE cola_sync.solicitud_uuid = e.solicitud_uuid;

-- resultado
SELECT solicitud_uuid, id_local, estado, motivo
FROM cola_sync
ORDER BY solicitud_uuid;
