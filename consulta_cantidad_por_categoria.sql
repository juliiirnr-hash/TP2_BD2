WITH productos_existentes AS (
    SELECT id_producto, id_categoria
    FROM producto
    WHERE eliminado = FALSE
)
SELECT c.id_categoria AS id,
       COUNT(pe.id_producto) AS cantidad
FROM categoria c
LEFT JOIN productos_existentes pe
    ON pe.id_categoria = c.id_categoria
GROUP BY c.id_categoria
ORDER BY cantidad DESC;