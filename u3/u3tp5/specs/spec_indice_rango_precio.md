\# spec: idx\_producto\_precio\_rango

Objetivo: Optimizar la consulta de distribución de precios por categoría (Consulta 4).

Consulta afectada: 

&#x20; SELECT c.nombre, CASE ... END AS rango\_precio, COUNT(\*) 

&#x20; FROM categoria c 

&#x20; JOIN producto p ON p.id\_categoria = c.id\_categoria 

&#x20; WHERE p.eliminado = FALSE 

&#x20; GROUP BY c.id\_categoria, c.nombre, rango\_precio;



Columnas candidatas: p.eliminado (filtro), p.precio (evaluación del CASE), p.id\_categoria (JOIN).

Criterio de aceptación: Reducir el tiempo de ejecución (hoy en \~125 ms) y evitar el Seq Scan sobre la tabla producto.

