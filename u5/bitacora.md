# Bitácora — Food Store

## Registro: Evaluación de privilegios propuestos por la IA

**Fecha / Contexto:** 2026-10-15. Fase de diseño e implementación de permisos (Parte A, puntos 2 y 4).

**Propuesta inicial de la IA:** durante la generación automatizada de los scripts de control de acceso, una de las sugerencias iniciales fue otorgar un permiso amplio del tipo
```sql
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_app_escritura;
```
extendiendo el acceso a las secuencias de todas las tablas del esquema.

**Análisis del equipo:** se detectó que este enfoque contravenía el principio de mínimo privilegio. El rol `rol_app_escritura` solo inserta en `pedido` y `detalle_pedido`, por lo que únicamente necesita las secuencias asociadas a esas tablas. Aunque las secuencias solo exponen contadores (no datos sensibles de las tablas), abrir el acceso a las de todo el esquema representaba una amplitud injustificada.

**Decisión adoptada:** se descartó la propuesta genérica y se restringió el privilegio a las secuencias requeridas para su operatoria:
```sql
GRANT USAGE, SELECT ON SEQUENCE pedido_id_pedido_seq, detalle_pedido_id_detalle_seq TO rol_app_escritura;
```
El mismo criterio se aplicó a `rol_catalogo_admin` (solo `producto_id_producto_seq` y `categoria_id_categoria_seq`). De esta forma se aseguró el aislamiento y control estricto que exige el diseño del proyecto.

**Estado:** aplicado en `roles.sql` (§5 y §8). Verificado por re-ejecución en `food_store_test` sin errores.
