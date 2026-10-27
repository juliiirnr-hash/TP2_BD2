# Informe incidente — TP U5 Parte C

## 2. Verificación del escalamiento (C.2)
Ejecutado `sql/simulacro_incidente.sql` contra la base de desarrollo.
Resultado esperado y obtenido: **el escalamiento FALLA**.
- `SET ROLE app_web; GRANT admin_datos TO app_web;` → `ERROR: permiso denegado para el rol admin_datos` (solo un rol con CREATEROLE/superuser puede otorgar membresía; `app_web` es NOSUPERUSER NOCREATEROLE según `sql/roles.sql` §2).
- `TRUNCATE TABLE usuario;` como `app_web` → `ERROR: permiso denegado` (sin DDL fuera de `admin_datos`).
- Lectura masiva `SELECT count(*) FROM usuario;` como `app_web` → `ERROR: permiso denegado` (correcto: `app_web` solo lee vistas de catálogo).
Conclusión: **no hay hallazgo**; el esquema de la Parte A resiste. Si algún ERROR no apareciera, se registraría como defecto de `roles.sql` a corregir antes de seguir.

## 4. Respuesta completa de la IA con solo el log (C.4)
> Prompt entregado (sin contexto adicional): "Reconstruí qué ocurrió en este log y proponé una hipótesis de contención." + contenido de `docs/log_simulacro_anonimizado.txt`.
> Respuesta recibida (completa):
> "Se observan 3 llamadas a fn_autenticar con resultado negativo seguidas de una positiva desde 192.0.2.10 entre las 21:40:02 y 21:40:03, patrón compatible con fuerza bruta seguida de compromiso de la credencial 'victima.c001@test.local'. Luego el usuario app_web intenta dos lecturas masivas sobre usuario y un GRANT hacia admin_datos más un TRUNCATE, todos denegados a las 21:40:03-04. Hipótesis: atacante externo que obtuvo la clave y escaló a la app para exfiltrar y persistir como admin. Contención sugerida: bloquear de inmediato la IP 192.0.2.10 en el firewall, revocar la contraseña comprometida y auditar pg_auth_members."

## 5. Contraste IA vs realmente ejecutado (C.5)
- **Acertó:** secuencia 3 fallidos + 1 éxito, orden temporal, denegación de las 2 lecturas y del GRANT/TRUNCATE, identificación de `app_web` vs `admin_datos`.
- **Omitió:** que con `log_statement='mod'` los SELECT no quedan como STATEMENT (solo constan por el ERROR); no distinguió sesión `postgres` (dueño del simulacro) de sesión `app_web`; no mencionó que el TRUNCATE también es operación reservada, no solo el GRANT.
- **Afirmación no sustentada por el log:** "atacante externo" y "bloquear IP en firewall" — el log solo muestra `host=192.0.2.10` (IP anonimizada de laboratorio) sin geolocalización ni reincidencia; tampoco prueba exfiltración (las lecturas fueron denegadas, `count(*)` nunca devolvió filas). La IP 192.0.2.10 es del propio entorno de prueba, no un origen hostil confirmado.

## 6. Decisión final de contención del equipo (C.6)
En un caso real con esta evidencia (fuerza bruta contenida, sin lectura ni escalamiento exitosos): **forzar el cambio de la contraseña de `victima.c001@test.local` vía `fn_resetear_password`, rotar la clave del login `app_web`, revisar `pg_auth_members` para confirmar que no hubo membresía nueva, y reforzar monitoreo sobre `fn_autenticar`** (alerta a partir de N fallidos). No se bloquea firewall ni se revierte ningún rol porque no hubo compromiso efectivo. **Esta decisión es del equipo a partir de la evidencia; no se ejecutó automáticamente lo sugerido por la IA.**
