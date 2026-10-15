-- Script de carga de datos de prueba para food_store_test
-- Solo INSERTs, no modifica estructura

BEGIN;

-- 1. Cargar usuarios (se crean 20 usuarios para los pedidos)
INSERT INTO usuario (id_usuario, nombre, apellido, mail, celular, contrasena, rol, eliminado) OVERRIDING SYSTEM VALUE
SELECT 
    i,
    'Usuario' || i,
    'Apellido' || i,
    'usuario' || i || '@test.com',
    '261' || LPAD(i::text, 7, '0'),
    'hash_password_' || i,
    CASE WHEN i <= 2 THEN 'ADMIN'::rol_usuario ELSE 'USUARIO'::rol_usuario END,
    CASE WHEN random() < 0.05 THEN true ELSE false END
FROM generate_series(1, 20) AS i;

-- 2. Cargar 8 categorías con IDs explícitos
INSERT INTO categoria (id_categoria, nombre, descripcion, eliminado) OVERRIDING SYSTEM VALUE
SELECT 
    i,
    'Categoría ' || i,
    'Descripción de la categoría ' || i,
    CASE WHEN random() < 0.05 THEN true ELSE false END
FROM generate_series(1, 8) AS i;

-- 3. Cargar 50 productos distribuidos en las 8 categorías (IDs 1-8)
INSERT INTO producto (id_producto, nombre, precio, descripcion, stock, imagen, disponible, id_categoria, eliminado) OVERRIDING SYSTEM VALUE
SELECT 
    i,
    'Producto ' || i,
    (random() * 1000 + 50)::numeric(10,2),
    'Descripción del producto ' || i,
    (random() * 100)::integer,
    'imagen_' || i || '.jpg',
    CASE WHEN random() < 0.1 THEN false ELSE true END,
    ((i - 1) % 8) + 1,  -- Distribuir en las 8 categorías (1-8)
    CASE WHEN random() < 0.05 THEN true ELSE false END
FROM generate_series(1, 50) AS i;

-- 4. Cargar 10.000 pedidos con fechas de los últimos 30 días
-- Aprox 300 de hoy (30 días = 10.000 pedidos => ~333 por día)
-- Total se calculará más adelante tras insertar detalles
INSERT INTO pedido (id_pedido, fecha, estado, forma_pago, total, id_usuario, eliminado) OVERRIDING SYSTEM VALUE
SELECT 
    i,
    now() - (random() * 30 * interval '1 day'),
    CASE 
        WHEN random() < 0.4 THEN 'PENDIENTE'::estado_pedido
        WHEN random() < 0.7 THEN 'CONFIRMADO'::estado_pedido
        WHEN random() < 0.9 THEN 'TERMINADO'::estado_pedido
        ELSE 'CANCELADO'::estado_pedido
    END,
    CASE 
        WHEN random() < 0.33 THEN 'EFECTIVO'::forma_pago
        WHEN random() < 0.66 THEN 'TARJETA'::forma_pago
        ELSE 'TRANSFERENCIA'::forma_pago
    END,
    0,  -- Se actualizará después
    (random() * 19 + 1)::integer,  -- ID usuario entre 1 y 20
    CASE WHEN random() < 0.05 THEN true ELSE false END
FROM generate_series(1, 10000) AS i;

-- 4b. Cargar 500 pedidos adicionales de hoy
INSERT INTO pedido (id_pedido, fecha, estado, forma_pago, total, id_usuario, eliminado) OVERRIDING SYSTEM VALUE
SELECT 
    i + 10000,
    now(),
    CASE 
        WHEN random() < 0.4 THEN 'PENDIENTE'::estado_pedido
        WHEN random() < 0.7 THEN 'CONFIRMADO'::estado_pedido
        WHEN random() < 0.9 THEN 'TERMINADO'::estado_pedido
        ELSE 'CANCELADO'::estado_pedido
    END,
    CASE 
        WHEN random() < 0.33 THEN 'EFECTIVO'::forma_pago
        WHEN random() < 0.66 THEN 'TARJETA'::forma_pago
        ELSE 'TRANSFERENCIA'::forma_pago
    END,
    0,  -- Se actualizará después
    (random() * 19 + 1)::integer,
    CASE WHEN random() < 0.05 THEN true ELSE false END
FROM generate_series(1, 500) AS i;

-- 5. Insertar 50.000 detalles de pedido
-- Distribución: ~5 detalles por pedido en promedio (50.000 / 10.000)
-- Cada detalle: cantidad aleatoria (1-10), precio_unitario snapshot del producto
-- subtotal = cantidad * precio_unitario (CHECK obligatorio)
-- Estrategia: usar combinación cíclica determinista para evitar duplicados

WITH datos_detalle AS (
    SELECT 
        i,
        (random() * 9 + 1)::integer AS cantidad,
        ((i - 1) / 5) + 1 AS id_pedido,  -- Cada 5 detalles cambia de pedido
        ((i - 1) % 50) + 1 AS id_producto,  -- Ciclo por productos 1-50
        CASE WHEN random() < 0.05 THEN true ELSE false END AS eliminado
    FROM generate_series(1, 50000) AS i
)
INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, id_pedido, id_producto, eliminado)
SELECT 
    dd.cantidad,
    prod.precio AS precio_unitario,
    (dd.cantidad * prod.precio)::numeric(10,2) AS subtotal,
    dd.id_pedido,
    dd.id_producto,
    dd.eliminado
FROM datos_detalle dd
JOIN producto prod ON dd.id_producto = prod.id_producto;

-- 5b. Insertar 2.500 detalles adicionales para los 500 pedidos de hoy
WITH datos_detalle_hoy AS (
    SELECT 
        i,
        (random() * 9 + 1)::integer AS cantidad,
        10000 + ((i - 1) / 5) + 1 AS id_pedido,  -- Pedidos 10001-10500
        ((i - 1) % 50) + 1 AS id_producto,
        CASE WHEN random() < 0.05 THEN true ELSE false END AS eliminado
    FROM generate_series(1, 2500) AS i
)
INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, id_pedido, id_producto, eliminado)
SELECT 
    dd.cantidad,
    prod.precio AS precio_unitario,
    (dd.cantidad * prod.precio)::numeric(10,2) AS subtotal,
    dd.id_pedido,
    dd.id_producto,
    dd.eliminado
FROM datos_detalle_hoy dd
JOIN producto prod ON dd.id_producto = prod.id_producto;

-- 6. Actualizar los totales de los pedidos sumando sus detalles
UPDATE pedido p
SET total = (
    SELECT COALESCE(SUM(d.subtotal), 0)
    FROM detalle_pedido d
    WHERE d.id_pedido = p.id_pedido AND d.eliminado = false
);

COMMIT;

-- 7. ANALYZE de las tablas
ANALYZE categoria;
ANALYZE producto;
ANALYZE usuario;
ANALYZE pedido;
ANALYZE detalle_pedido;
