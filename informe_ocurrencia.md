escenario 1 "Lectura no repetible":



Ejecución sin Repeatable read:

&#x09;pestaña 1: BEING; SELECT precio FROM producto WHERE id\_producto = 1; | pestaña 2:UPDATE producto SET precio = 800 WHERE id\_producto = 1; commit;

&#x09;Salida: precio|------+800.00| (dato actualizado en pestaña 2)

Ejecución con Repeatable read:

&#x09;pestaña 1: BEGIN ISOLATION LEVEL REPEATABLE READ; SELECT precio FROM producto WHERE id\_producto = 1; | pestaña 2:UPDATE producto SET precio = 800 WHERE id\_producto = 1; commit;

&#x09;Salida: precio|------+500.00| (dato original, no cambio)



Explicación  de open code:



Eso es exactamente lo que se espera con el nivel de aislamiento REPEATABLE READ en PostgreSQL. Te explico por qué.

Sin REPEATABLE READ (nivel por defecto: READ COMMITTED)

pestaña 1: BEGIN;

pestaña 1: SELECT precio FROM producto WHERE id\_producto = 1;   → 500

pestaña 2: UPDATE producto SET precio = 800 WHERE id\_producto = 1;

pestaña 2: COMMIT;

pestaña 1: SELECT precio FROM producto WHERE id\_producto = 1;   → 800

En READ COMMITTED, cada sentencia ve lo último que fue commiteado. El segundo SELECT de la pestaña 1 se ejecuta después del COMMIT de la pestaña 2, así que ve el valor nuevo: 800.

Con REPEATABLE READ

pestaña 1: BEGIN ISOLATION LEVEL REPEATABLE READ;

pestaña 1: SELECT precio FROM producto WHERE id\_producto = 1;   → 500

pestaña 2: UPDATE producto SET precio = 800 WHERE id\_producto = 1;

pestaña 2: COMMIT;

pestaña 1: SELECT precio FROM producto WHERE id\_producto = 1;   → 500

En REPEATABLE READ, la transacción congela una foto (snapshot) de los datos al leer por primera vez y la mantiene hasta que termina. Aunque la pestaña 2 commitee el cambio a 800, la pestaña 1 sigue leyendo desde su snapshot congelado, que muestra 500.

Diferencia clave

\- Primer caso (800): el segundo SELECT ve el dato más reciente commiteado por otra sesión.

\- Segundo caso (500): el segundo SELECT ve la versión de cuando la transacción empezó a leer, ignorando el cambio ajeno.

En resumen: es el comportamiento normal de PostgreSQL — READ COMMITTED lee en cada consulta lo último, y REPEATABLE READ mantiene consistencia en toda la transacción.

\------------------------------------------------------------------------------------------

escenario 2 "Espera por bloqueo":



Ejecución:

&#x09;Pestaña 1: BEGIN READ WRITE; SELECT \* FROM producto WHERE id\_producto = 1 FOR update; | Pestaña 2: BEGIN; SELECT \* FROM producto WHERE id\_producto = 1 FOR UPDATE;

&#x09;Salida 1: Tabla completa de id\_producto

&#x09;Salida 2: Se queda colgado (excecute Query..)



Ejecución con commit:

&#x09;Pestaña 1: BEGIN READ WRITE; SELECT \* FROM producto WHERE id\_producto = 1 FOR update; commit; | Pestaña 2: BEGIN; SELECT \* FROM producto WHERE id\_producto = 1 FOR UPDATE;

&#x09;Salida 1: Name;Query Value;commit (confirmación de que se realizo el commit)

&#x09;Salida 2: Tabla completa de id\_producto



Explicación de open code:



FOR UPDATE bloquea la fila que devuelve el SELECT, con un lock exclusivo de fila. Ese lock se mantiene hasta que la transacción haga COMMIT o ROLLBACK. Mientras la fila esté bloqueada, ninguna otra transacción puede tomar un lock sobre ella.

Primer escenario (sin COMMIT)

pestaña 1: BEGIN READ WRITE;

pestaña 1: SELECT \* FROM producto WHERE id\_producto = 1 FOR UPDATE;   → fila bloqueada

pestaña 2: BEGIN;

pestaña 2: SELECT \* FROM producto WHERE id\_producto = 1 FOR UPDATE;   → ⏳ colgado

\- La pestaña 1 bloquea la fila 1 con su FOR UPDATE.

\- La pestaña 2 intenta FOR UPDATE sobre la misma fila, pero como la pestaña 1 no ha hecho COMMIT/ROLLBACK, el lock sigue activo.

\- PostgreSQL entonces bloquea (espera) la sentencia de la pestaña 2 hasta que la pestaña 1 suelte el lock.

\- Por eso la salida 2 se queda "colgada" en executing...: no es que esté mal, está esperando.

Segundo escenario (con COMMIT)

pestaña 1: BEGIN READ WRITE;

pestaña 1: SELECT \* FROM producto WHERE id\_producto = 1 FOR UPDATE;   → fila bloqueada

pestaña 1: COMMIT;                                                    → lock liberado ✅

pestaña 2: BEGIN;

pestaña 2: SELECT \* FROM producto WHERE id\_producto = 1 FOR UPDATE;   → ahora sí, devuelve la fila

\- La pestaña 1 hace COMMIT, lo que libera el lock sobre la fila 1.

\- En ese momento, la pestaña 2, que estaba esperando, puede continuar y ejecutar su FOR UPDATE con normalidad, devolviendo la fila.

En resumen

FOR UPDATE toma un lock exclusivo que se mantiene hasta que termina la transacción (COMMIT/ROLLBACK). Mientras la transacción original no cierre, otra transacción que intente bloquear la misma fila se queda esperando (no falla, se congela). Cuando la primera hace COMMIT, el lock se libera y la segunda puede continuar.

Así que no hay ningún error: es el control de concurrencia por bloqueo de PostgreSQL funcionando como debe.

\---------------------------------------------------------------------------------------

escenario 3 "Lectura fantasma":



Ejecucion:

&#x09;Pestaña 1:BEING; SELECT COUNT(\*) FROM pedido WHERE id\_usuario = 1;

&#x09;Salida 1:count|-----+1|

&#x09;Pestaña 2:BEING;INSERT INTO pedido(estado, forma\_pago, total, id\_usuario) VALUES('PENDIENTE', 'EFECTIVO', 100, 1);commit;

&#x09;Salida 1:count|-----+2| | Salida 2: Name;Query Value;commit (confirmación de que se realizo el commit)



Explicacion de open code:



La clave: READ COMMITTED toma un snapshot por sentencia

En READ COMMITTED, cada sentencia individual toma su propio snapshot al empezar. No congela una vista para toda la transacción.

\- El primer SELECT COUNT de la pestaña 1 toma un snapshot → ve 1.

\- La pestaña 2 inserta y hace COMMIT.

\- El segundo SELECT COUNT de la pestaña 1 es una sentencia nueva (ya terminó la anterior), así que toma otro snapshot fresco → ahora ve los datos que la pestaña 2 ya commiteó → 2.

Aunque haya un BEGIN abierto en la pestaña 1, READ COMMITTED no congela nada entre sentencias. Ese BEGIN solo sirve para agrupar escrituras; las lecturas siempre se re-ejecutan con el dato más reciente commiteado.

Esto es una lectura fantasma

Es exactamente el fenómeno de la lectura fantasma (phantom read): el conjunto de filas que cumple el filtro cambió entre dos consultas porque otra transacción insertó filas que cumplen la condición y commiteó en el medio.

Qué cambiaría el resultado a 1 (sin fantasma)

Si la pestaña 1 usara REPEATABLE READ, congelaría el snapshot toda la transacción:

pestaña 1: BEGIN ISOLATION LEVEL REPEATABLE READ;

pestaña 1: SELECT COUNT(\*) ...;    → 1

pestaña 2: BEGIN; INSERT ...; COMMIT;

pestaña 1: SELECT COUNT(\*) ...;    → 1  ← sigue viendo 1 (snapshot congelado)

pestaña 1: COMMIT;



En resumen

\- Ambas usan READ COMMITTED por defecto (no REPEATABLE READ).

\- En READ COMMITTED, cada SELECT ve lo último commiteado, aunque haya un BEGIN de por medio.

\- Por eso el segundo COUNT ve el pedido nuevo → 2 (lectura fantasma).

\- Con REPEATABLE READ abierto, el segundo COUNT seguiría viendo 1.

