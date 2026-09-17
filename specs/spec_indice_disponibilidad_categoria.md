\# spec: idx\_categoria\_producto\_disponibilidad

Objetivo: Optimizar la consulta de disponibilidad de producto por categoria (Consulta 5).

Consulta afectada: 

SELECT c.nombre,

&#x20;      COUNT(\*)                                     AS total\_productos,

&#x20;      COUNT(\*) FILTER (WHERE p.disponible = TRUE)  AS disponibles,

&#x20;      COUNT(\*) FILTER (WHERE p.disponible = FALSE) AS no\_disponibles

FROM categoria c

JOIN producto p ON p.id\_categoria = c.id\_categoria

WHERE p.eliminado = FALSE

GROUP BY c.id\_categoria, c.nombre

ORDER BY total\_productos DESC;

Columnas candidatas: p.eliminado, p.disponible, p.id\_categoria (JOIN).

Criterio de aceptación: Reducir el tiempo de ejecución y evitar el Seq Scan sobre la tabla producto.

