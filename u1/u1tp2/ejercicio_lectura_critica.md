Script 1

\- Generado para: dar de baja las funciones de películas retiradas de cartel 

UPDATE funcion 

SET activa = FALSE; 



Explicación

\-UPDATE: sirve para modificar datos ya existentes en una tabla.

\-SET: indica qué columna queremos cambiar y qué valor le asignamos.

\-En este caso, el script pone la columna activa en FALSE para todas las filas de la tabla función.

Análisis:  

Este script desactiva todas las funciones de la tabla, sin distinguir cuáles están retiradas de cartel. Afectaría todas las filas, incluso las funciones activas.

Corrección

UPDATE funcion

SET activa = FALSE

WHERE fecha\_fin < CURDATE();



\-WHERE: agrega una condición para que solo se modifiquen las filas que cumplen un criterio.

\-El CURDATE() es una función que devuelve la fecha actual del sistema, sin incluir la hora.

Aquí, se desactivan únicamente las funciones cuya fecha de fin ya pasó (fecha\_fin < CURDATE()).

Script 2

\- Generado para: limpiar las categorías sin productos asociados 

DELETE FROM categoria 

WHERE id NOT IN (SELECT categoria\_id FROM producto); 

Explicación

\-DELETE: elimina filas de una tabla.

\-NOT IN: excluye valores que aparecen en una lista o subconsulta.

\-En este caso, borra las categorías cuyo id no aparece en la tabla producto

Analisis

Si la subconsulta devuelve un valor NULL, el NOT IN puede comportarse de forma inesperada y borrar categorías que sí tienen productos asociados.

Esto ocurre porque la comparación con NULL no es verdadera ni falsa, sino indeterminada, y puede invalidar toda la condición.

Solucion

DELETE FROM categoria c

WHERE NOT EXISTS (

&#x20; SELECT 1 FROM producto p WHERE p.categoria\_id = c.id

);



\-NOT EXISTS: evalúa fila por fila si existe relación en la subconsulta.



\-Ignora los NULL, porque no compara listas de valores, sino que responde “¿existe o no existe?”.



\-Solo elimina categorías que realmente no tienen productos vinculados.



