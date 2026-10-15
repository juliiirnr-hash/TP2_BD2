# Informe corto de configuración — Auditoría básica en PostgreSQL
## Parte B · TP Unidad 5 · Base de Datos II · Food Store

### 1. Objetivo
Activar una auditoría mínima en `food_store_test` para registrar quién se conecta, cuándo se desconecta y qué sentencias modifican datos, sin registrar todo el tráfico `SELECT`.

### 2. Configuración aplicada
Parámetros activados en `postgresql.conf` (o vía `ALTER SYSTEM`):

```sql
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();
```

Verificación:

```sql
SHOW log_connections;
SHOW log_disconnections;
SHOW log_statement;
```

Resultado esperado: `on`, `on`, `mod`.

> Nota: `SELECT pg_reload_conf()` aplica los cambios sin reiniciar el servidor. Si se edita `postgresql.conf` a mano, también vale recargar el servicio.

### 3. Utilidad de cada parámetro
- **`log_connections = on`**: registra cada nueva conexión (usuario, base, IP/puerto, fecha/hora). Sirve para detectar accesos fuera de horario, conexiones inesperadas de `app_web` / `backoffice_catalogo` / `admin_datos` y posibles intentos de intrusión.
- **`log_disconnections = on`**: registra cada desconexión, incluyendo duración de la sesión. Combinado con el anterior, permite reconstruir ventanas de actividad por usuario y detectar sesiones anómalamente largas o cortas.
- **`log_statement = 'mod'`**: registra sentencias que modifican datos o estructura (`INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `CREATE`, `ALTER`, `DROP`, `GRANT`, `REVOKE`, etc.), pero no los `SELECT`. Es el punto medio para auditoría: se ve qué cambió sin llenar el log con el tráfico de lectura del catálogo (`rol_app_lectura`).

Ejemplo de evidencia esperada en el log:
- Conexión de `app_web`, ejecución de `sp_crear_pedido(...)`, desconexión con duración.
- `UPDATE producto SET precio = ...` por `backoffice_catalogo` (quién, cuándo, qué sentencia).

### 4. Sensibilidad de los archivos de log
Sí, los logs son sensibles y deben tratarse como tal:
- **Qué contienen**: usuarios, IPs, marcas de tiempo, sentencias SQL completas. Un `INSERT`/`UPDATE` puede incluir datos personales (nombre, mail, celular de `usuario`) y datos comerciales (precios, totales). Si alguna vez se logueara un `PASSWORD` o una sentencia con credenciales, también quedaría en texto plano.
- **Riesgos**: enumeración de usuarios, reconstrucción de hábitos de compra, exposición de datos personales ante accesos no autorizados al servidor.
- **Resguardo mínimo propuesto**:
  1. Archivo de log solo legible por el owner (`postgres`/`admin_datos`), sin acceso a roles de app/soporte/reportes.
  2. Ubicar logs fuera del directorio público y no versionarlos en git.
  3. Rotación y retención definida (ej. conservar N días/semanas y luego eliminar).
  4. No registrar datos innecesarios: se eligió `'mod'` y no `'all'` justamente para no volcar los `SELECT` masivos del catálogo.
  5. Toda revisión de logs se hace sobre la copia de pruebas (`food_store_test`), nunca sobre la base original con datos reales.

### 5. Conclusión
Con tres parámetros (`log_connections`, `log_disconnections`, `log_statement = 'mod'`) se obtiene trazabilidad de accesos y modificaciones con costo moderado de almacenamiento. Los logs resultantes son material sensible: se protegen con acceso restringido, rotación y uso exclusivo en entorno de pruebas.
