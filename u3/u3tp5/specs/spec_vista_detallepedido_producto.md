\# Especificación: Vista de Detalle de Pedido con Nombre de Producto



\## 1. Objetivo

Crear la vista `v\_detalle\_pedido\_producto` para asociar las líneas de detalle de un pedido con el nombre del producto comprado.



\## 2. Tablas Involucradas

\* `public.detalle\_pedido` (Alias: `dp`)

\* `public.producto` (Alias: `p`)



\## 3. Criterios y Filtros de Vigencia

\* \*\*Borrado Lógico:\*\* `WHERE dp.eliminado = FALSE AND p.eliminado = FALSE`.

\* \*\*Relación:\*\* `INNER JOIN` entre `detalle\_pedido.id\_producto` y `producto.id\_producto`.



\## 4. Columnas a Exponer

\* `dp.id\_pedido`

\* `dp.cantidad`

\* `p.id\_producto`

\* `p.nombre` AS `producto\_nombre`



\## 5. Exclusiones y Seguridad

\* Omitir columnas de auditoría (`created\_at`, `eliminado`) y precios secundarios no requeridos.



\## 6. Salida Esperada

Un script SQL con la sentencia `CREATE OR REPLACE VIEW v\_detalle\_pedido\_producto AS ...`





