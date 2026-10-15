copia: Trabajamos en una copia especifica para desarrolladores (food\_store\_dev), que contiene únicamente datos ficticios y no se afecta directamente a la base de datos original. 



transacción: Antes de hacer commit a cualquier script, los probamos dentro de un Begin-Rollback, para comprobar que todo se ejecute como se espera y sin errores.



respaldo: Cuando vamos a realizar un cambio importante realizamos un respaldo ,en una carpeta dentro del proyecto, con la herramienta dumps en DBeaver. 

