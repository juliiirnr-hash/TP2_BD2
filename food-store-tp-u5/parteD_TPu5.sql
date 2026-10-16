--USUARIO ANON
-- Cantidad de usuarios por rol y por mes de alta (excluye borrados lógicos)
SELECT
  rol, -- rol_usuario: ADMIN / USUARIO
  DATE_TRUNC('month', created_at)::date AS mes_alta, -- mes de alta desde created_at
  COUNT(*) AS cantidad_usuarios -- total por grupo rol + mes
FROM usuario_anon
WHERE eliminado = FALSE
GROUP BY rol, DATE_TRUNC('month', created_at)
ORDER BY mes_alta ASC, rol ASC;

--USUARIO REAL
-- Cantidad de usuarios por rol y por mes de alta (excluye borrados lógicos)
SELECT
  rol,
  DATE_TRUNC('month', created_at)::date AS mes_alta,
  COUNT(*) AS cantidad_usuarios
FROM usuario
WHERE eliminado = FALSE
GROUP BY rol, DATE_TRUNC('month', created_at)
ORDER BY mes_alta ASC, rol ASC;

--RESULTADOS DE EJECUCION
--rol    |mes_alta  |cantidad_usuarios|   rol    |mes_alta  |cantidad_usuarios|   
---------+----------+-----------------+   -------+----------+-----------------+
--ADMIN  |2026-09-01|                1|   ADMIN  |2026-09-01|                1|
--USUARIO|2026-09-01|                4|   USUARIO|2026-09-01|                4|

--Respuesta punto : Nunca deberia salir hacia un agente de IA datos sensibles reales como DNI, nombre ,
-- apellido, fecha de nacimiento, usuarios-contraseñas,correos..etc. ya que todos los datos son 
--utilizados para re-entrenarse en un futuro y corren el riesgo de filtrarse. Al pasar por este proceso de 
--anonimizacion se enmascaran y al crear informes no corren riesgo.