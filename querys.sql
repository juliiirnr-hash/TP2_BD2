-- 1) KPIs por categoría
SELECT c.nombre,
       COUNT(p.id_producto)             AS productos_categoria,
       ROUND(AVG(p.precio)::numeric, 2) AS precio_promedio,
       MIN(p.precio)                    AS precio_minimo,
       MAX(p.precio)                    AS precio_maximo,
       SUM(p.stock)                     AS stock_total
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY productos_categoria DESC;

-- 1b) EXPLAIN ANALYZE de la consulta 1
EXPLAIN ANALYZE
SELECT c.nombre,
       COUNT(p.id_producto)             AS productos_categoria,
       ROUND(AVG(p.precio)::numeric, 2) AS precio_promedio,
       MIN(p.precio)                    AS precio_minimo,
       MAX(p.precio)                    AS precio_maximo,
       SUM(p.stock)                     AS stock_total
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY productos_categoria DESC;

-- 2) Top 10 productos más caros con su categoría
SELECT p.nombre  AS producto,
       c.nombre  AS categoria,
       p.precio,
       p.stock
FROM producto p
JOIN categoria c ON c.id_categoria = p.id_categoria
WHERE p.eliminado = FALSE
  AND p.disponible = TRUE
ORDER BY p.precio DESC
LIMIT 10;

-- 2b) EXPLAIN ANALYZE de la consulta 2
EXPLAIN ANALYZE
SELECT p.nombre  AS producto,
       c.nombre  AS categoria,
       p.precio,
       p.stock
FROM producto p
JOIN categoria c ON c.id_categoria = p.id_categoria
WHERE p.eliminado = FALSE
  AND p.disponible = TRUE
ORDER BY p.precio DESC
LIMIT 10;

-- 3) Productos desabastecidos por categoría
SELECT c.nombre,
       COUNT(*)                             AS sin_stock,
       ROUND(AVG(p.precio)::numeric, 2)     AS precio_promedio
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
  AND p.stock = 0
GROUP BY c.id_categoria, c.nombre
HAVING COUNT(*) > 0
ORDER BY sin_stock DESC;

-- 3b) EXPLAIN ANALYZE de la consulta 3
EXPLAIN ANALYZE
SELECT c.nombre,
       COUNT(*)                             AS sin_stock,
       ROUND(AVG(p.precio)::numeric, 2)     AS precio_promedio
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
  AND p.stock = 0
GROUP BY c.id_categoria, c.nombre
HAVING COUNT(*) > 0
ORDER BY sin_stock DESC;

-- 4) Distribución de precios por categoría
SELECT c.nombre,
       CASE
           WHEN p.precio < 1000   THEN '1_<1000'
           WHEN p.precio <= 3000  THEN '2_1000-3000'
           ELSE                        '3_>3000'
       END                          AS rango_precio,
       COUNT(*)                     AS cantidad
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre, rango_precio
ORDER BY c.nombre, rango_precio;

-- 4b) EXPLAIN ANALYZE de la consulta 4
EXPLAIN ANALYZE
SELECT c.nombre,
       CASE
           WHEN p.precio < 1000   THEN '1_<1000'
           WHEN p.precio <= 3000  THEN '2_1000-3000'
           ELSE                        '3_>3000'
       END                          AS rango_precio,
       COUNT(*)                     AS cantidad
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre, rango_precio
ORDER BY c.nombre, rango_precio;

-- 5) Disponibilidad por categoría
SELECT c.nombre,
       COUNT(*)                                     AS total_productos,
       COUNT(*) FILTER (WHERE p.disponible = TRUE)  AS disponibles,
       COUNT(*) FILTER (WHERE p.disponible = FALSE) AS no_disponibles
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY total_productos DESC;

-- 5b) EXPLAIN ANALYZE de la consulta 5
EXPLAIN ANALYZE
SELECT c.nombre,
       COUNT(*)                                     AS total_productos,
       COUNT(*) FILTER (WHERE p.disponible = TRUE)  AS disponibles,
       COUNT(*) FILTER (WHERE p.disponible = FALSE) AS no_disponibles
FROM categoria c
JOIN producto p ON p.id_categoria = c.id_categoria
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY total_productos DESC;

-- 6) Pedidos con datos del usuario y total de artículos
SELECT pd.id_pedido,
       pd.fecha,
       pd.estado,
       pd.total,
       u.nombre  AS usuario,
       u.apellido,
       COUNT(dp.id_detalle) AS articulos
FROM pedido pd
JOIN usuario u ON u.id_usuario = pd.id_usuario
JOIN detalle_pedido dp ON dp.id_pedido = pd.id_pedido
WHERE pd.eliminado = FALSE
GROUP BY pd.id_pedido, pd.fecha, pd.estado, pd.total, u.nombre, u.apellido
ORDER BY pd.fecha DESC;

-- 6b) EXPLAIN ANALYZE de la consulta 6
EXPLAIN ANALYZE
SELECT pd.id_pedido,
       pd.fecha,
       pd.estado,
       pd.total,
       u.nombre  AS usuario,
       u.apellido,
       COUNT(dp.id_detalle) AS articulos
FROM pedido pd
JOIN usuario u ON u.id_usuario = pd.id_usuario
JOIN detalle_pedido dp ON dp.id_pedido = pd.id_pedido
WHERE pd.eliminado = FALSE
GROUP BY pd.id_pedido, pd.fecha, pd.estado, pd.total, u.nombre, u.apellido
ORDER BY pd.fecha DESC;

-- 7) Productos vendidos por categoría
SELECT c.nombre  AS categoria,
       p.nombre  AS producto,
       p.precio,
       COUNT(dp.id_detalle) AS veces_vendido,
       SUM(dp.cantidad)     AS unidades_vendidas
FROM producto p
JOIN categoria c ON c.id_categoria = p.id_categoria
JOIN detalle_pedido dp ON dp.id_producto = p.id_producto
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre, p.id_producto, p.nombre, p.precio
ORDER BY unidades_vendidas DESC;

-- 7b) EXPLAIN ANALYZE de la consulta 7
EXPLAIN ANALYZE
SELECT c.nombre  AS categoria,
       p.nombre  AS producto,
       p.precio,
       COUNT(dp.id_detalle) AS veces_vendido,
       SUM(dp.cantidad)     AS unidades_vendidas
FROM producto p
JOIN categoria c ON c.id_categoria = p.id_categoria
JOIN detalle_pedido dp ON dp.id_producto = p.id_producto
WHERE p.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre, p.id_producto, p.nombre, p.precio
ORDER BY unidades_vendidas DESC;

-- 8) Historial completo de compras: usuario → pedido → producto
SELECT u.nombre     AS usuario,
       u.apellido,
       pd.fecha,
       pd.estado,
       pr.nombre    AS producto,
       dp.cantidad,
       dp.precio_unitario,
       dp.subtotal
FROM detalle_pedido dp
JOIN pedido pd ON pd.id_pedido = dp.id_pedido
JOIN usuario u ON u.id_usuario = pd.id_usuario
JOIN producto pr ON pr.id_producto = dp.id_producto
WHERE dp.eliminado = FALSE
  AND pd.eliminado = FALSE
ORDER BY pd.fecha DESC;

-- 8b) EXPLAIN ANALYZE de la consulta 8
EXPLAIN ANALYZE
SELECT u.nombre     AS usuario,
       u.apellido,
       pd.fecha,
       pd.estado,
       pr.nombre    AS producto,
       dp.cantidad,
       dp.precio_unitario,
       dp.subtotal
FROM detalle_pedido dp
JOIN pedido pd ON pd.id_pedido = dp.id_pedido
JOIN usuario u ON u.id_usuario = pd.id_usuario
JOIN producto pr ON pr.id_producto = dp.id_producto
WHERE dp.eliminado = FALSE
  AND pd.eliminado = FALSE
ORDER BY pd.fecha DESC;