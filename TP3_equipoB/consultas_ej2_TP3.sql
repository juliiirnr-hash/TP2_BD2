select * from producto where precio >(select avg(precio) from producto);
select id_categoria , count(*) from producto group by id_categoria;
select  * from producto order by stock desc limit 100;

explain analyze select * from producto where precio >(select avg(precio) from producto);
explain analyze select id_categoria , count(*) from producto group by id_categoria;
explain analyze select  * from producto order by stock desc limit 100;

SELECT id_producto, nombre, precio, descripcion, stock,
       imagen, disponible, id_categoria, eliminado, created_at
FROM (
  SELECT *, AVG(precio) OVER () AS avg_precio
  FROM producto
) sub
WHERE precio > avg_precio;

ANALYZE producto;

EXPLAIN analyze SELECT id_producto, nombre, precio, descripcion, stock,
       imagen, disponible, id_categoria, eliminado, created_at
FROM (
  SELECT *, AVG(precio) OVER () AS avg_precio
  FROM producto
) sub
WHERE precio > avg_precio;

SELECT id_categoria, count(*)
FROM producto
WHERE eliminado = FALSE
GROUP BY id_categoria;

explain analyze SELECT id_categoria, count(*)
FROM producto
WHERE eliminado = FALSE
GROUP BY id_categoria;

SELECT * FROM producto
WHERE eliminado = FALSE
ORDER BY stock DESC
LIMIT 100;
CREATE INDEX idx_producto_stock ON producto(stock DESC) WHERE eliminado = FALSE;
 explain analyze SELECT * FROM producto
WHERE eliminado = FALSE
ORDER BY stock DESC
LIMIT 100;

