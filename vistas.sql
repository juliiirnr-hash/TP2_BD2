-- vistas.sql
-- Vistas de reporte del sistema food_store (TP2 BD2).
-- Re-runnable: usa CREATE OR REPLACE VIEW.
-- Respeta borrado lógico (WHERE eliminado = FALSE) y oculta auditoría/datos sensibles.

-- Vista 1: productos vigentes con su categoría.
-- Abstrae el catálogo activo para reportes frecuentes (producto + categoría).
CREATE OR REPLACE VIEW v_productos_vigentes AS
SELECT
    p.id_producto,
    p.nombre AS producto_nombre,
    p.precio,
    p.disponible,
    c.id_categoria,
    c.nombre AS categoria_nombre
FROM public.producto AS p
INNER JOIN public.categoria AS c ON c.id_categoria = p.id_categoria
WHERE p.eliminado = FALSE AND c.eliminado = FALSE;

-- Vista 2: pedidos con datos del cliente.
-- Simplifica reportes comerciales ocultando contrasena, rol y auditoría.
CREATE OR REPLACE VIEW v_pedidos_usuario AS
SELECT
    pd.id_pedido,
    pd.fecha,
    pd.estado,
    pd.forma_pago,
    pd.total,
    u.id_usuario,
    u.nombre AS usuario_nombre,
    u.apellido AS usuario_apellido,
    u.mail AS mail_usuario,
    u.celular AS celular_usuario
FROM public.pedido AS pd
INNER JOIN public.usuario AS u ON u.id_usuario = pd.id_usuario
WHERE pd.eliminado = FALSE AND u.eliminado = FALSE;

-- Vista 3: detalle de pedido con nombre de producto.
-- Asocia cada línea de detalle con el producto comprado.
CREATE OR REPLACE VIEW v_detalle_pedido_producto AS
SELECT
    dp.id_pedido,
    dp.cantidad,
    p.id_producto,
    p.nombre AS producto_nombre
FROM public.detalle_pedido AS dp
INNER JOIN public.producto AS p ON p.id_producto = dp.id_producto
WHERE dp.eliminado = FALSE AND p.eliminado = FALSE;
