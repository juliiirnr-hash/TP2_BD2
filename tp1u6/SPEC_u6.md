ESPECIFICACIÓN DEL TRABAJO PRÁCTICO - UNIDAD 6

Proyecto: Food Store
Base de datos: PostgreSQL 16+
Objetivo: Automatizar el mantenimiento, respaldo y recuperación de la base de datos foodstore.


1. ¿QUÉ HAY QUE HACER?

- RESPALDO (Diario)
  Crear una copia de seguridad de foodstore con pg_dump en formato custom (-Fc). Guardar en backups/.
  OK si: existe el archivo .dump con fecha/hora, tamaño > 0, log dice "OK" y no hay errores.

- CHEQUEO DE SALUD (Diario)
  Ejecutar health_check.sql para revisar tamaño, conexiones, tablas y consultas activas.
  OK si: las 4 consultas corren sin errores. Sin consultas muy largas ni muchas tuplas muertas en aumento.

- REVISIÓN DE MANTENIMIENTO (Semanal)
  Ejecutar maintenance.sql para revisar autovacuum, ANALYZE y tuplas muertas.
  OK si: se revisan last_autovacuum/last_autoanalyze, cualquier VACUUM manual está justificado. NUNCA usar VACUUM FULL.

- SIMULACRO DE RESTAURACIÓN (Semanal)
  Restaurar el respaldo sobre foodstore_restore_test con pg_restore y validar.
  OK si: pg_restore sin errores, conteo de filas coincide, productos_invalidos = 0 y detalles_invalidos = 0. 
       Además hay que anotar RTO (tiempo de restauración) y RPO (antigüedad del respaldo).


2. REGLAS IMPORTANTES

- NO tocar foodstore. Solo restaurar sobre foodstore_restore_test.
- SIN contraseñas en scripts. Usar .pgpass, autenticación local o variables de entorno.
- USAR formato custom (-Fc) para poder restaurar con pg_restore.
- PROBAR TODO primero en ambiente de prueba con bases descartables.
- REVISAR MANUALMENTE todo lo que genere OpenCode. La IA no reemplaza la revisión humana.


3. CUÁNDO SE CONSIDERA TERMINADO

Una tarea está bien hecha si:
- Sin errores (comando finaliza correctamente)
- Con evidencia (archivo .dump, salida SQL, logs, validaciones, etc.)
- Con registros (RPO, RTO y métricas de salud para el informe)
