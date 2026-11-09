-- control: el servidor no cambio (correr antes y despues del semaforo)
SELECT
    (SELECT COUNT(*) FROM pedido)                   AS cantidad_pedidos,
    (SELECT COUNT(*) FROM detalle_pedido)           AS cantidad_detalles,
    (SELECT COALESCE(SUM(stock), 0) FROM producto)  AS stock_total,
    (SELECT COUNT(*) FROM producto WHERE eliminado) AS productos_dados_de_baja;
