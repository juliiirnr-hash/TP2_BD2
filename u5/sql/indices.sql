-- =============================================================================
-- TRABAJO PRÁCTICO 2: OPTIMIZACIÓN Y PLAN DE INDEXADO (PARTE A)
-- Archivo: indices.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Consulta 4: Distribución de precios por categoría
-- Se crea un índice B-Tree compuesto sobre (id_categoria, precio) con filtro 
-- parcial (WHERE eliminado = FALSE).
-- Razón: id_categoria resuelve el JOIN y el GROUP BY, mientras que precio 
-- optimiza la evaluación por rangos del CASE WHEN sin acceder al heap.
-- -----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_producto_precio_rango;

CREATE INDEX idx_producto_precio_rango
  ON producto USING BTREE (id_categoria, precio)
  WHERE eliminado = FALSE;


-- -----------------------------------------------------------------------------
-- Consulta 5: Disponibilidad de productos por categoría
-- Se crea un índice B-Tree compuesto sobre (id_categoria, disponible) con filtro 
-- parcial (WHERE eliminado = FALSE).
-- Razón: id_categoria resuelve el JOIN y GROUP BY; disponible resuelve los 
-- conteos filtrados (COUNT FILTER) permitiendo un Index Only Scan.
-- -----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_categoria_producto_disponibilidad;

CREATE INDEX idx_categoria_producto_disponibilidad
  ON producto USING BTREE (id_categoria, disponible)
  WHERE eliminado = FALSE;


-- -----------------------------------------------------------------------------
-- Consulta 6: Historial de pedidos con cantidad de artículos
-- Se crea un índice B-Tree parcial sobre la tabla pedido por (fecha DESC).
-- Razón: Evita el nodo de ordenamiento explícito (Sort/Quicksort) al entregar 
-- los registros ordenados desde la estructura del índice B-Tree.
-- -----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_pedido_historial_articulos;

CREATE INDEX idx_pedido_historial_articulos
  ON pedido USING BTREE (fecha DESC)
  WHERE eliminado = FALSE;