INSERT INTO producto (nombre, precio, descripcion, stock, imagen, disponible, id_categoria, eliminado)
SELECT
    'Producto ' || s,
    ROUND((500 + random() * 3500)::NUMERIC, 2),
    'Descripcion del producto ' || s,
    (random() * 200)::INTEGER,
    'img/producto_' || s || '.png',
    TRUE,
    (SELECT id_categoria
     FROM categoria
     WHERE eliminado = FALSE
     ORDER BY id_categoria
     LIMIT 1 OFFSET ((s - 1) % (SELECT COUNT(*) FROM categoria WHERE eliminado = FALSE))),
    FALSE
FROM generate_series(1, 50000) AS s;
