-- vistas.sql — Food Store · Vistas, materializada y función de negocio
-- Spec: docs/kiro_roles_spec/design.md §4 (dueño funcional: admin_datos)
-- Se aplica DESPUÉS de schema.sql y ANTES de roles.sql (ver main.sql).
-- Todo re-ejecutable: CREATE OR REPLACE en vistas/función;
-- DROP IF EXISTS + CREATE en la materializada (no admite OR REPLACE).

-- ============================================================
-- 1. Vistas ya existentes en el respaldo (se recrean para que
--    food_store_test quede completa desde cero)
-- ============================================================
CREATE OR REPLACE VIEW v_productos_vigentes AS
SELECT p.id_producto,
       p.nombre AS producto_nombre,
       p.precio,
       p.disponible,
       c.id_categoria,
       c.nombre AS categoria_nombre
FROM producto p
JOIN categoria c ON c.id_categoria = p.id_categoria
WHERE p.eliminado = FALSE AND c.eliminado = FALSE;

CREATE OR REPLACE VIEW v_pedidos_usuario AS
SELECT pd.id_pedido,
       pd.fecha,
       pd.estado,
       pd.forma_pago,
       pd.total,
       u.id_usuario,
       u.nombre AS usuario_nombre,
       u.apellido AS usuario_apellido,
       u.mail AS mail_usuario,
       u.celular AS celular_usuario
FROM pedido pd
JOIN usuario u ON u.id_usuario = pd.id_usuario
WHERE pd.eliminado = FALSE AND u.eliminado = FALSE;

CREATE OR REPLACE VIEW v_detalle_pedido_producto AS
SELECT dp.id_pedido,
       dp.cantidad,
       p.id_producto,
       p.nombre AS producto_nombre
FROM detalle_pedido dp
JOIN producto p ON p.id_producto = dp.id_producto
WHERE dp.eliminado = FALSE AND p.eliminado = FALSE;

-- ============================================================
-- 2. Vistas nuevas (no existen en el respaldo ni en schema.sql)
-- ============================================================
CREATE OR REPLACE VIEW v_categorias_vigentes AS
SELECT id_categoria, nombre, descripcion
FROM categoria WHERE eliminado = FALSE;

-- Soporte sin claves: aísla contrasena y rol interno
CREATE OR REPLACE VIEW v_usuarios_publico AS
SELECT id_usuario, nombre, apellido, mail, celular
FROM usuario WHERE eliminado = FALSE;

CREATE OR REPLACE VIEW v_pedidos_resumen AS
SELECT p.id_pedido, p.fecha, p.estado, p.forma_pago, p.total,
       u.nombre AS usuario_nombre, u.apellido AS usuario_apellido, u.mail AS mail_usuario
FROM pedido p JOIN usuario u ON u.id_usuario = p.id_usuario
WHERE p.eliminado = FALSE AND u.eliminado = FALSE;

-- ============================================================
-- 3. Reporte mensual por categoría (rancking_dia es diaria/top-5:
--    no reutilizable para el panel gerencial)
-- ============================================================
DROP MATERIALIZED VIEW IF EXISTS mv_ventas_categoria_mes;
CREATE MATERIALIZED VIEW mv_ventas_categoria_mes AS
SELECT c.nombre AS categoria,
       date_trunc('month', p.fecha)::date AS mes,
       SUM(d.subtotal)::NUMERIC(10,2) AS total_vendido,
       COUNT(*) AS lineas
FROM detalle_pedido d
JOIN pedido p    ON p.id_pedido = d.id_pedido
JOIN producto pr ON pr.id_producto = d.id_producto
JOIN categoria c ON c.id_categoria = pr.id_categoria
WHERE d.eliminado = FALSE AND p.eliminado = FALSE AND p.estado <> 'CANCELADO'
GROUP BY 1, 2 WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_ventas_cat_mes
  ON mv_ventas_categoria_mes (categoria, mes); -- habilita REFRESH CONCURRENTLY

-- ============================================================
-- 4. Alta atómica de pedido (p_items: '[{"id_producto":1,"cantidad":2}, ...]')
--    SECURITY INVOKER: no escala privilegios, el que ejecuta ya tiene
--    INSERT en pedido/detalle_pedido vía rol_app_escritura.
-- ============================================================
CREATE OR REPLACE FUNCTION sp_crear_pedido(p_id_usuario INT, p_forma_pago forma_pago, p_items JSONB)
RETURNS INT LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE v_pedido INT; r RECORD; v_precio NUMERIC(10,2);
BEGIN
  IF jsonb_array_length(p_items) = 0 THEN RAISE EXCEPTION 'pedido sin items'; END IF;
  INSERT INTO pedido (estado, forma_pago, total, id_usuario)
  VALUES ('PENDIENTE', p_forma_pago, 0, p_id_usuario) RETURNING id_pedido INTO v_pedido;
  FOR r IN SELECT (x->>'id_producto')::INT AS id_prod, (x->>'cantidad')::INT AS cant
           FROM jsonb_array_elements(p_items) x LOOP
    IF r.cant <= 0 THEN RAISE EXCEPTION 'cantidad inválida'; END IF;
    SELECT precio INTO v_precio FROM producto
    WHERE id_producto = r.id_prod AND eliminado = FALSE AND disponible = TRUE;
    IF NOT FOUND THEN RAISE EXCEPTION 'producto % no vigente', r.id_prod; END IF;
    INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, id_pedido, id_producto)
    VALUES (r.cant, v_precio, (r.cant * v_precio)::NUMERIC(10,2), v_pedido, r.id_prod);
  END LOOP;
  UPDATE pedido SET total = (SELECT COALESCE(SUM(subtotal),0) FROM detalle_pedido
    WHERE id_pedido = v_pedido AND eliminado = FALSE) WHERE id_pedido = v_pedido;
  RETURN v_pedido;
END $$;
