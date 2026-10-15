# Especificación: Vista de Pedidos con Datos de Usuario

## 1. Objetivo
Crear una vista llamada `v_pedidos_usuario` que abstraiga la consulta de pedidos realizados en el sistema junto con la información del cliente asignado, protegiendo datos sensibles y simplificando los reportes comerciales.

## 2. Tablas Involucradas
* `public.pedido` (Alias: `pd`)
* `public.usuario` (Alias: `u`)

## 3. Criterios y Filtros de Vigencia
* **Borrado Lógico:** Filtrar únicamente las filas donde `pd.eliminado = FALSE` y `u.eliminado = FALSE`.
* **Relación:** `INNER JOIN` entre `pedido.id_usuario` y `usuario.id_usuario`.

## 4. Columnas a Exponer
* `pd.id_pedido` (Identificador del pedido)
* `pd.fecha` (Fecha de la transacción)
* `pd.estado` (Estado del pedido)
* `pd.forma_pago` (Medio de pago)
* `pd.total` (Monto total)
* `u.id_usuario` (Identificador del usuario)
* `u.nombre` AS `usuario_nombre`
* `u.apellido` AS `usuario_apellido`
* `u.mail` AS `mail_usuario`
* `u.celular` AS `celular_usuario`

## 5. Exclusiones y Seguridad
* **Protección de Datos:** Ocultar estrictamente el campo sensible `contrasena` y el `rol` de la tabla `usuario`.
* **Auditoría:** Omitir campos de control interno como `created_at` y banderas de borrado lógico (`eliminado`).

## 6. Salida Esperada
Un script SQL con la sentencia `CREATE OR REPLACE VIEW v_pedidos_usuario AS ...`



