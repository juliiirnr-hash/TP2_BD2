\# Informe de Resolución — 4.2. Parte B Vistas para los Reportes del Sistema



\## 1. Especificaciones de Vistas (`specs`)



A partir de los requerimientos de la cátedra, se redactaron los archivos de especificación funcional en formato Markdown dentro de la carpeta `specs` para guiar la generación del código SQL.



\### `specsspec\_vista\_productos\_vigentes.md`

&#x20;Objetivo Abstraer el catálogo de productos activos junto a su categoría.

&#x20;Tablas e Integración `public.producto` (p) `INNER JOIN` `public.categoria` (c) ON `c.id\_categoria = p.id\_categoria`.

&#x20;Filtro de Vigencia `p.eliminado = FALSE AND c.eliminado = FALSE`.

&#x20;Columnas Expuestas `id\_producto`, `producto\_nombre`, `precio`, `disponible`, `id\_categoria`, `categoria\_nombre`.



\### `specsspec\_vista\_pedidos\_usuario.md`

&#x20;Objetivo Abstraer los pedidos del sistema asociando los datos del cliente comprador.

&#x20;Tablas e Integración `public.pedido` (pd) `INNER JOIN` `public.usuario` (u) ON `u.id\_usuario = pd.id\_usuario`.

&#x20;Filtro de Vigencia `pd.eliminado = FALSE AND u.eliminado = FALSE`.

&#x20;Columnas Expuestas `id\_pedido`, `fecha`, `estado`, `forma\_pago`, `total`, `id\_usuario`, `usuario\_nombre`, `usuario\_apellido`, `mail\_usuario`, `celular\_usuario`.

&#x20;Seguridad  Exclusiones Se omite strictly la columna `contrasena` de la tabla `usuario`.



\### `specsspec\_vista\_detalle\_pedido.md`

&#x20;Objetivo Relacionar las líneas de detalle de pedido con el catálogo general.

&#x20;Tablas e Integración `public.detalle\_pedido` (dp) `INNER JOIN` `public.producto` (p) ON `p.id\_producto = dp.id\_producto`.

&#x20;Filtro de Vigencia `dp.eliminado = FALSE AND p.eliminado = FALSE`.

&#x20;Columnas Expuestas `id\_pedido`, `cantidad`, `id\_producto`, `producto\_nombre`.



\---



\## 2. Generación del Script SQL (`views.sql`)



Con base en las especificaciones creadas, se construyó mediante OpenCode el script completo de definición de vistas



```sql

\-- Vista 1 Productos vigentes con su categoría

CREATE OR REPLACE VIEW v\_productos\_vigentes AS

SELECT

&#x20;   p.id\_producto,

&#x20;   p.nombre AS producto\_nombre,

&#x20;   p.precio,

&#x20;   p.disponible,

&#x20;   c.id\_categoria,

&#x20;   c.nombre AS categoria\_nombre

FROM public.producto AS p

INNER JOIN public.categoria AS c ON c.id\_categoria = p.id\_categoria

WHERE p.eliminado = FALSE AND c.eliminado = FALSE;



\-- Vista 2 Pedidos con datos de usuario

CREATE OR REPLACE VIEW v\_pedidos\_usuario AS

SELECT

&#x20;   pd.id\_pedido,

&#x20;   pd.fecha,

&#x20;   pd.estado,

&#x20;   pd.forma\_pago,

&#x20;   pd.total,

&#x20;   u.id\_usuario,

&#x20;   u.nombre AS usuario\_nombre,

&#x20;   u.apellido AS usuario\_apellido,

&#x20;   u.mail AS mail\_usuario,

&#x20;   u.celular AS celular\_usuario

FROM public.pedido AS pd

INNER JOIN public.usuario AS u ON u.id\_usuario = pd.id\_usuario

WHERE pd.eliminado = FALSE AND u.eliminado = FALSE;



\-- Vista 3 Detalle de pedido con nombre de producto

CREATE OR REPLACE VIEW v\_detalle\_pedido\_producto AS

SELECT

&#x20;   dp.id\_pedido,

&#x20;   dp.cantidad,

&#x20;   p.id\_producto,

&#x20;   p.nombre AS producto\_nombre

FROM public.detalle\_pedido AS dp

INNER JOIN public.producto AS p ON p.id\_producto = dp.id\_producto

WHERE dp.eliminado = FALSE AND p.eliminado = FALSE;

```



\---



\## 3. Verificación de Equivalencia de Resultados



Para cada una de las vistas se ejecutó la consulta sobre la vista frente a la consulta manual equivalente escrita directamente sobre las tablas base. En los tres casos se constató una coincidencia exacta de filas y valores.



\### Prueba 1 `v\_productos\_vigentes`



```sql

\-- Consulta A (Vista)

SELECT  FROM v\_productos\_vigentes ORDER BY id\_producto;



\-- Consulta B (Manual)

SELECT p.id\_producto,

&#x20;      p.nombre AS producto\_nombre,

&#x20;      p.precio,

&#x20;      p.disponible,

&#x20;      c.id\_categoria,

&#x20;      c.nombre AS categoria\_nombre

FROM producto p

JOIN categoria c ON c.id\_categoria = p.id\_categoria

WHERE p.eliminado = FALSE 

&#x20; AND c.eliminado = FALSE

ORDER BY p.id\_producto;

```



&#x20;Resultado Coincidencia total en el dataset devuelto (misma cantidad de registros y mismos datos en cada columna).



\### Prueba 2 `v\_pedidos\_usuario`



```sql

\-- Consulta A (Vista)

SELECT  FROM v\_pedidos\_usuario ORDER BY id\_pedido;



\-- Consulta B (Manual)

SELECT pd.id\_pedido,

&#x20;      pd.fecha,

&#x20;      pd.estado,

&#x20;      pd.forma\_pago,

&#x20;      pd.total,

&#x20;      u.id\_usuario,

&#x20;      u.nombre AS usuario\_nombre,

&#x20;      u.apellido AS usuario\_apellido,

&#x20;      u.mail AS mail\_usuario,

&#x20;      u.celular AS celular\_usuario

FROM pedido pd

JOIN usuario u ON u.id\_usuario = pd.id\_usuario

WHERE pd.eliminado = FALSE 

&#x20; AND u.eliminado = FALSE

ORDER BY pd.id\_pedido;

```



&#x20;Resultado Coincidencia exacta de 2 filas en ambas ejecuciones (`id\_pedido` 3 y 4).



\### Prueba 3 `v\_detalle\_pedido\_producto`



```sql

\-- Consulta A (Vista)

SELECT  FROM v\_detalle\_pedido\_producto ORDER BY id\_pedido, id\_producto;



\-- Consulta B (Manual)

SELECT dp.id\_pedido,

&#x20;      dp.cantidad,

&#x20;      p.id\_producto,

&#x20;      p.nombre AS producto\_nombre

FROM detalle\_pedido dp

JOIN producto p ON p.id\_producto = dp.id\_producto

WHERE dp.eliminado = FALSE 

&#x20; AND p.eliminado = FALSE

ORDER BY dp.id\_pedido, p.id\_producto;

```



&#x20;Resultado Coincidencia perfecta en los detalles de artículos asociados a las compras.



\---



\## 4. Aplicación del Criterio de Seguridad y Control de Acceso



En cumplimiento con la teoría de seguridad y el Principio de Mínimo Privilegio



1\. Ocultamiento de datos sensibles La vista `v\_pedidos\_usuario` excluye intencionalmente la columna `contrasena` de la tabla `usuario`.

2\. Abstracción de acceso Permite otorgar permisos de lectura exclusivamente sobre las vistas sin exponer el acceso directo a ninguna de las tablas base (`usuario`, `producto`, `categoria`, `pedido`, `detalle\_pedido`).



\### Implementación SQL del Control de Acceso para las Tres Vistas (RBAC)



```sql

\-- 1. Crear el rol restringido para reportes

CREATE ROLE rol\_reportes;



\-- 2. Revocar el acceso directo a todas las tablas base involucradas

REVOKE SELECT ON public.usuario FROM rol\_reportes;

REVOKE SELECT ON public.producto FROM rol\_reportes;

REVOKE SELECT ON public.categoria FROM rol\_reportes;

REVOKE SELECT ON public.pedido FROM rol\_reportes;

REVOKE SELECT ON public.detalle\_pedido FROM rol\_reportes;



\-- 3. Otorgar permisos de consulta únicamente sobre las tres vistas seguras

GRANT SELECT ON public.v\_productos\_vigentes TO rol\_reportes;

GRANT SELECT ON public.v\_pedidos\_usuario TO rol\_reportes;

GRANT SELECT ON public.v\_detalle\_pedido\_producto TO rol\_reportes;

```

