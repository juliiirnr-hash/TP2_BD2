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

## Tabla consolidada — Partes A a D (formato TP: Prompt | Respuesta | Validación)

| Parte | Prompt enviado a la IA | Respuesta relevante recibida (resumen) | Validación o corrección humana aplicada |
|---|---|---|---|
| A | "Generá/auditá roles.sql con mínimo privilegio" | Propuso `GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_app_escritura` | Rechazado por amplio: se restringió a las 2 secuencias de `pedido`/`detalle_pedido` (y lo mismo para catálogo). Verificado con re-ejecución. |
| B | (Realizada por compañera; prompt no registrado en esta sesión) | Config `log_connections/on, log_disconnections/on, log_statement='mod'` + lectura del fragmento (quién/qué/cuándo/dónde, brecha pgaudit) | Pendiente: completar prompt exacto antes de entregar. Contenido verificado en `docs/informe_auditoria.md` y `parte_b_ejercicio_3/4.md`. |
| C | "Diseñá el script del simulacro: fallidos vs fn_autenticar, éxito, lectura masiva, escalada a admin_datos" | Entregó `simulacro_incidente.sql` con `\set/\echo` (comandos psql) | Corrección: DBeaver dio `ERROR cerca de «\»`; se quitaron los meta-comandos y se ejecuta sentencia por sentencia. |
| C | "No me funciona: no existe fn_autenticar ni app_web / TRUNCATE da error de FK" | Diagnóstico con 4 consultas: función y rol faltantes; el TRUNCATE como owner choca con la FK de `pedido` | Se creó `fn_autenticar` y el rol `app_web`; se documentó que como `app_web` da `permiso denegado` (evidencia C.2) y como owner lo frena la FK (doble defensa). |
| D | "Generá agregación sobre usuario_anon: cantidad por rol y mes de alta" | IA asumió la estructura de `usuario_anon` (= `usuario`) sin evidencia | Corrección humana: "¿por qué asumes?" — se pidió el esquema real (`information_schema.columns`) y se rehízo la consulta con `created_at` confirmado. |

## E.2 Caso más significativo de error de la IA
El de la Parte D: la IA afirmó una estructura de `usuario_anon` sin haberla visto en el repo (búsqueda de `anon` daba 0 resultados). Se detectó porque el equipo preguntó la fuente del supuesto y exigió el esquema real; la consulta final se validó contra las columnas confirmadas (`rol`, `created_at`, `eliminado`). Enseña la regla del TP: evidencia antes que síntesis.

## E.3 Historial Git
Avance por partes con commits legibles (ver `git log`). Quedaron archivos de la Parte C sin commitear al cierre de esta bitácora (`simulacro_incidente.sql`, `log_simulacro_anonimizado.txt`, `informe_incidente.md`, `parteD_TPu5.sql`): commitearlos uno por parte antes de entregar. Próxima vez: commitear cada parte el mismo día que se termina.
