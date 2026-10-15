\# spec: idx\_pedido\_historial\_articulos



Contexto del proyecto:

\- Archivo de consultas base: `queries.sql` (Consulta 6: Pedidos con datos del usuario y total de artículos)



Objetivo:

Optimizar la consulta de cantidad de artículos por pedido definida en `queries.sql`.



Consulta afectada:

SELECT pd.id\_pedido,

&#x20;      pd.fecha,

&#x20;      pd.estado,

&#x20;      pd.total,

&#x20;      u.nombre  AS usuario,

&#x20;      u.apellido,

&#x20;      COUNT(dp.id\_detalle) AS articulos

FROM pedido pd

JOIN usuario u ON u.id\_usuario = pd.id\_usuario

JOIN detalle\_pedido dp ON dp.id\_pedido = pd.id\_pedido

WHERE pd.eliminado = FALSE

GROUP BY pd.id\_pedido, pd.fecha, pd.estado, pd.total, u.nombre, u.apellido

ORDER BY pd.fecha DESC;



Columnas candidatas: pd.eliminado (filtro), pd.fecha (ordenamiento), dp.id\_pedido (JOIN).

Criterio de aceptación: Reducir el tiempo de ejecución, evitar el operador de Sort explícito y el Seq Scan sobre la tabla detalle\_pedido.

