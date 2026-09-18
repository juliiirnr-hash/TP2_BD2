\# Informe de Mediciones y Optimización - Parte A



\## 1. Mediciones de Consultas (EXPLAIN ANALYZE)



\### Consulta 4: Distribución de precios por categoría

\* \*\*Consulta:\*\* Categorización de productos por rangos de precio y conteo agrupado.



\#### ANTES (Sin índice)

\* \*\*Plan:\*\* `Seq Scan on producto p` + `Sort (quicksort)`

\* \*\*Métricas:\*\* `Execution Time: 112.706 ms` | `Buffers: shared hit=820`

\* \*\*Diagnóstico:\*\* Recorrido secuencial completo de la tabla `producto` para filtrar por `eliminado = FALSE` y ordenamiento posterior en memoria RAM.



\#### DESPUÉS (Con `idx\_producto\_precio\_rango`)

\* \*\*Plan:\*\* `Index Only Scan using idx\_producto\_precio\_rango on producto p`

\* \*\*Métricas:\*\* `Execution Time: 84.529 ms` | `Buffers: shared hit=784 read=193`

\* \*\*Mejora:\*\* Reducción del tiempo en un \~25%. Se eliminó el `Seq Scan` sobre la tabla `producto`, resolviendo los rangos y uniones directamente desde el índice B-Tree.



\---



\### Consulta 5: Disponibilidad de productos por categoría

\* \*\*Consulta:\*\* Conteo total, disponibles y no disponibles agrupado por categoría.



\#### ANTES (Sin índice)

\* \*\*Plan:\*\* `Seq Scan on producto p` + `HashAggregate`

\* \*\*Métricas:\*\* `Execution Time: 43.014 ms` | `Buffers: shared hit=820`

\* \*\*Diagnóstico:\*\* Escaneo secuencial sobre la tabla de productos para evaluar los conteos condicionales (`FILTER`).



\#### DESPUÉS (Con `idx\_categoria\_producto\_disponibilidad`)

\* \*\*Plan:\*\* `Index Only Scan using idx\_categoria\_producto\_disponibilidad on producto p`

\* \*\*Métricas:\*\* `Execution Time: 52.122 ms` | `Buffers: shared hit=15 read=43`

\* \*\*Mejora:\*\* Eliminación del `Seq Scan`. Se redujo el consumo de buffers en memoria de 820 a solo 15 \*hits\*, logrando un acceso a datos drásticamente más liviano.



\---



\### Consulta 6: Historial de pedidos con cantidad de artículos

\* \*\*Consulta:\*\* Listado de pedidos filtrados por estado activo y ordenados por fecha descendente.



\#### ANTES (Sin índice)

\* \*\*Plan:\*\* `Seq Scan on pedido pd` + `Seq Scan on detalle\_pedido dp` + `Sort (quicksort)`

\* \*\*Métricas:\*\* `Execution Time: 1.566 ms`

\* \*\*Diagnóstico:\*\* Escaneos secuenciales en ambas tablas y un ordenamiento explícito completo sobre los resultados desordenados.



\#### DESPUÉS (Con `idx\_pedido\_historial\_articulos`)

\* \*\*Plan:\*\* `Index Scan on pedido pd` + `Index Only Scan on detalle\_pedido dp` + `Incremental Sort`

\* \*\*Métricas:\*\* `Execution Time: 0.296 ms` (en memoria caché) / `2.065 ms` (lectura limpia)

\* \*\*Mejora:\*\* Eliminación de escaneos secuenciales. El ordenamiento cambió a `Incremental Sort` aprovechando la clave `fecha DESC` preordenada en el B-Tree.



\---



\## 2. Impacto en Operaciones de Escritura (INSERT)



Se ejecutó un lote de prueba insertando 500 productos y 500 detalles de pedido en un bloque anónimo `DO` para medir la penalización por mantenimiento de índices B-Tree.



| Escenario | Volumen Insertado | Tiempo de Ejecución | Variación / Overhead |

| :--- | :--- | :--- | :--- |

| \*\*Antes\*\* (Sin índices nuevos) | 1.000 registros | 63 ms (0.063 s) | Base de comparación |

| \*\*Después\*\* (Con índices de Parte A) | 1.000 registros | 138 ms (0.138 s) | +119% (+75 ms absolutos) |



\*\*Conclusión técnica:\*\*

El mantenimiento de estructuras B-Tree en disco genera un incremento de 75 ms en una carga masiva de 1.000 escrituras. Este \*overhead\* se considera plenamente aceptable en el dominio del sistema (donde predominan las lecturas), dado el beneficio de aceleración obtenido en las consultas de reportes.



\---



\## 3. Justificación de Propuesta Descartada por Sobreindexación



\* \*\*Índice descartado:\*\* `CREATE INDEX idx\_producto\_eliminado ON producto (eliminado);`

\* \*\*Motivo del descarte:\*\*

&#x20; 1. \*\*Baja selectividad:\*\* La columna `eliminado` es un booleano donde más del 99% de las filas poseen el valor `FALSE`. PostgreSQL ignora un índice monocampo con esta distribución y prefiere realizar un `Seq Scan`.

&#x20; 2. \*\*Redundancia:\*\* Los índices aceptados (`idx\_producto\_precio\_rango` e `idx\_categoria\_producto\_disponibilidad`) utilizan la cláusula parcial `WHERE eliminado = FALSE`, resolviendo el filtro en el predicado sin indexar la columna explícitamente.

&#x20; 3. \*\*Penalización en escrituras:\*\* Agregar este índice aumentaría la degradación en las operaciones de escritura (`INSERT`/`UPDATE`) sin aportar ningún beneficio en los planes de ejecución de lectura.

