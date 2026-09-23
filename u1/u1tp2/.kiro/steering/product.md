# Product

TP2 — Bases de Datos 2 (BD2). Sistema de pedidos con catálogo de productos, usuarios con roles y detalle de compras. El entregable es únicamente el esquema PostgreSQL (`schema.sql`); no existe capa de aplicación.

## Entidades principales

| Tabla | Propósito |
|---|---|
| `usuario` | Clientes y administradores (`ADMIN` \| `USUARIO`) |
| `categoria` | Agrupación de productos |
| `producto` | Ítems del catálogo con precio, stock e imagen |
| `pedido` | Orden de compra ligada a un usuario |
| `detalle_pedido` | Líneas de un pedido (producto + cantidad + precio snapshot) |

## ENUMs

| Tipo | Valores |
|---|---|
| `rol_usuario` | `ADMIN`, `USUARIO` |
| `estado_pedido` | `PENDIENTE`, `CONFIRMADO`, `TERMINADO`, `CANCELADO` |
| `forma_pago` | `EFECTIVO`, `TARJETA`, `TRANSFERENCIA` |
