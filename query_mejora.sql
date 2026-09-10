
-- MEJORA SELECCIONADA QUERY 2 (TP4)
-- ============================================================================
-- PROPUESTA 3: JOIN directo con índice covering (más simple, igual de rápida)
-- ============================================================================
-- Si el objetivo es solo eliminar el Memoize y los heap accesses,
-- el JOIN directo con el covering index es la opción más limpia.
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.nombre  AS producto,
       c.nombre  AS categoria,
       p.precio,
       p.stock
FROM (
    SELECT nombre, precio, stock, id_categoria
    FROM producto
    WHERE eliminado = FALSE AND disponible = TRUE
    ORDER BY precio DESC
    LIMIT 10
) p
JOIN categoria c ON c.id_categoria = p.id_categoria;

--MEJORA SELECCIONADA QUERY 5 (TP4)
-- ============================================================================
-- PROPUESTA 4: Reescritura con pre-agrupación (reducir filas del Hash Join)
-- ============================================================================
-- Objetivo: si hay pocas categorías (5), pre-agrupar en producto ANTES
-- del JOIN, pasando 5 filas al Hash Join en vez de 50000.
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, agg.total
FROM (
    SELECT id_categoria, COUNT(*) AS total
    FROM producto
    WHERE eliminado = FALSE
    GROUP BY id_categoria
) agg
JOIN categoria c ON c.id_categoria = agg.id_categoria
ORDER BY agg.total DESC;

--MEJORA SELECCIONADA QUERY 6 (TP4)
-- ============================================================================
-- PROPUESTA 3: Reescritura con subquery correlacionada (evitar ambos Hash)
-- ============================================================================
-- Objetivo: reemplazar los 2 Hash Joins con un EXISTS/IN que el planner
-- resuelva como Nested Loop o un solo Hash, reduciendo memoria y buffers.
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT pd.id_pedido,
       pd.fecha,
       pd.estado,
       pd.total,
       u.nombre  AS usuario,
       u.apellido,
       (SELECT COUNT(*) FROM detalle_pedido dp WHERE dp.id_pedido = pd.id_pedido) AS articulos
FROM pedido pd
JOIN usuario u ON u.id_usuario = pd.id_usuario
WHERE pd.eliminado = FALSE
ORDER BY pd.fecha DESC;
