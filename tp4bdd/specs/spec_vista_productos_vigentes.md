\# Especificación: Vista de Productos Vigentes con Categoría



\## 1. Objetivo

Crear una vista llamada `v\_productos\_vigentes` que abstraiga la consulta de productos activos en el sistema junto con la información básica de su categoría asignada, simplificando los reportes frecuentes de catálogo.



\## 2. Tablas Involucradas

\* `public.producto` (Alias: `p`)

\* `public.categoria` (Alias: `c`)



\## 3. Criterios y Filtros de Vigencia

\* \*\*Borrado Lógico:\*\* Filtrar únicamente las filas donde `p.eliminado = FALSE` y `c.eliminado = FALSE`.

\* \*\*Relación:\*\* `JOIN` interno entre `producto.id\_categoria` y `categoria.id\_categoria`.



\## 4. Columnas a Exponer

\* `p.id\_producto` (Identificador del producto)

\* `p.nombre` AS `producto\_nombre`

\* `p.precio`

\* `p.disponible`

\* `c.id\_categoria`

\* `c.nombre` AS `categoria\_nombre`



\## 5. Exclusiones y Seguridad

\* No incluir campos de auditoría internos como `created\_at` o banderas de borrado lógico (`eliminado`).



\## 6. Salida Esperada

Un script SQL con la sentencia `CREATE OR REPLACE VIEW v\_productos\_vigentes AS ...`

