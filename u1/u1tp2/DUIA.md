Spec 1: Subtotal en detalle\_pedido

Especificación: El campo subtotal debe ser igual a cantidad × precio\_unitario.



Generado por OpenCode: Se agregó un CHECK (subtotal = cantidad \* precio\_unitario) en la tabla detalle\_pedido.



Prueba realizada:



INSERT válido con subtotal correcto se ejecutó sin error.



INSERT inválido con subtotal incorrecto falló con error de restricción.

Diff aplicado

+--Un pedido confirmado no puede volver al estado PENDIENTE

+CREATE OR REPLACE FUNCTION verificar\_estado\_pedido() RETURNS TRIGGER AS $$

+BEGIN

\+    IF OLD.estado = 'CONFIRMADO' AND NEW.estado = 'PENDIENTE' THEN

\+        RAISE EXCEPTION 'Un pedido confirmado no puede volver al estado PENDIENTE';

\+    END IF;

\+    RETURN NEW;

+END;



Resultado: La regla funciona correctamente y evita inconsistencias en los subtotales.

Spec 2: Estado irreversible en pedido

Especificación: Un pedido no puede volver de CONFIRMADO a PENDIENTE.



Generado por OpenCode: Trigger que lanza excepción si se intenta revertir el estado.



Prueba realizada:



UPDATE pedido SET estado = 'PENDIENTE' falló con excepción del trigger.



UPDATE pedido SET estado = 'CONFIRMADO' se ejecutó correctamente.



Resultado: El trigger funciona correctamente y asegura la integridad del flujo de estados.

Diff aplicado:



\-    subtotal        NUMERIC(10,2)  NOT NULL CHECK (subtotal >= 0),

\+    subtotal        NUMERIC(10,2)  NOT NULL CHECK (subtotal >= 0) CHECK (subtotal = cantidad \* precio\_unitario),



Conclusión

Se verificaron los dos specs generados por OpenCode. Las pruebas en DBeaver confirmaron que las reglas funcionan según lo esperado, asegurando la integridad de los datos en la base.

