# Parte B · Ejercicio 3 — Lectura del fragmento de log con fines de auditoría
## Food Store · `food_store_test` · 2026-10-15

Fragmento analizado (`data/log/postgresql-2026-10-15_163519.log`):
`INSERT`/`UPDATE` sobre `categoria` (16:48:00, 16:48:19), `FATAL` por clave de `app_web` (16:48:46) y líneas de `conexión recibida / autenticada / autorizada`.

### Qué información del fragmento sirve a la auditoría
- **Quién**: el usuario de motor (`postgres` en las operaciones, `app_web` en el intento fallido) y el método de autenticación (`scram-sha-256`, con referencia a la regla de `pg_hba.conf` aplicada).
- **Qué**: la sentencia completa (`INSERT`/`UPDATE` con sus literales) y el resultado (`1 fila` implícita en éxito; `FATAL: ... password falló` en el fracaso).
- **Cuándo**: marca temporal con zona horaria (`-03`, `America/Buenos_Aires`), que permite ordenar los hechos y medir ventanas de actividad.
- **Desde dónde**: `host=127.0.0.1 port=...` y `base_de_datos=food_store_test` en las líneas de conexión, que identifican origen y destino de cada sesión.

### Qué queda fuera del alcance del mecanismo nativo (a nivel de nociones)
- **Detalle fila por fila**: el log muestra la sentencia, no qué filas cambiaron ni sus valores antes/después (sin imagen `OLD`/`NEW`); tampoco informa cuántas filas afectó cada sentencia.
- **Usuario final real**: todo el tráfico del backend figura como `app_web`; no se distingue qué persona operaba detrás del rol.
- **Lecturas**: con `log_statement = 'mod'` los `SELECT` no se registran; pasar a `'all'` los incluiría pero a costa de un volumen inmanejable.
- **Estructura y centralización**: es texto plano local, sin esquema consultable, sin firmas anti-manipulación y sin retención gestionada.
- La extensión **pgaudit** cubriría parte de esa brecha (nociones): clases de auditoría (`READ`, `WRITE`, `FUNCTION`, `ROLE`, `DDL`, `MISC`), auditoría por objeto vía rol `AUDIT`, y registro de sesión detallado incluyendo valores de parámetros — con granularidad configurable por objeto en lugar del todo o nada de `log_statement`.
