-- crea usuario victima si no existe
INSERT INTO usuario (nombre, apellido, mail, celular, contrasena, rol)
SELECT 'Sintetico','Victima','victima.c001@test.local','2600000099','ClaveC001_123','USUARIO'
WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE mail = 'victima.c001@test.local');

-- 3 intentos fallidos de login
SELECT fn_autenticar('victima.c001@test.local', 'wrong1') AS login_ok;
SELECT fn_autenticar('victima.c001@test.local', 'wrong2') AS login_ok;
SELECT fn_autenticar('victima.c001@test.local', 'wrong3') AS login_ok;
--rta:  login_ok|
        --------+
--      false   |

-- 1 intento exitoso de login
SELECT fn_autenticar('victima.c001@test.local', 'ClaveC001_123') AS login_ok;
--rta.  login_ok|
        --------+
--      true    |

-- lectura masiva como rol bajo
SET ROLE app_web;
SELECT count(*) FROM usuario;
SELECT id_usuario, mail FROM usuario LIMIT 20;
RESET ROLE;
--rta:     id_usuario|mail          |
--         +-----------------------+
--         1|juan@mail.com          |
--         2|maria@mail.com         |
--         3|carlos@mail.com        |
--         4|ana@mail.com           |
--         5|pedro@mail.com         |
--         6|victima.c001@test.local|

-- control como owner
SELECT count(*) AS total_usuarios_owner FROM usuario WHERE eliminado = FALSE;
--rta: total_usuarios_owner|
--         ----------------+
--                       6|


-- intento de escalamiento a admin_datos
SET ROLE app_web;
GRANT admin_datos TO app_web;
TRUNCATE TABLE usuario;
RESET ROLE;
--rta:  SQL Error [0A000]: ERROR: no se puede truncar una 
--      tabla referida en una llave foránea