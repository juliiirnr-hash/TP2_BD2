# DUIA — Declaración de Uso de IA

**Materia:** Base de Datos II · **TP:** N.º 8 — Food Store en la feria
**Integrantes:** Herrera, Julieta · Zalazar, María de los Ángeles

## Herramientas usadas

- OpenCode (agente de código) para generar y revisar scripts SQL.

## Para qué se usó

- Redactar el esquema SQLite y el script de pruebas.
- Escribir la vista `v_snapshot_movil` y el semáforo.
- Revisar los scripts de las unidades anteriores (consigna 3.c).

## Qué se verificó a mano

- Cada script se ejecutó antes de aceptarlo: el schema con `PRAGMA table_list` y
  `PRAGMA foreign_key_list`, las pruebas con una corrida real, y el semáforo con
  siete solicitudes que cubren todos los estados.
- Los hallazgos del code review se comprobaron con consultas a la base
  (`EXPLAIN`, conteos antes y después), no leyendo el código.
- Se comprobó que el servidor no cambió: pedidos y stock total idénticos antes y
  después de simular.

## Qué se descartó

- El tipo `UUID` en SQLite y el tipo `date` (no existen; se usó `TEXT`).
- Correr las pruebas con `executescript` de Python (corta en el primer error).
- Quitar el `DESC` del índice de la unidad 2 (el plan no cambia).
- La consigna 4.a (spec en Kiro), que no se entrega.

## Declaración

Los datos usados son inventados. No se cargaron contraseñas, mails ni datos
personales reales en SQLite ni se enviaron a la IA. Ningún resultado generado
por IA se dio por válido sin ejecutarlo y comprobarlo.
