CREATE TYPE rol_usuario AS ENUM ('ADMIN', 'USUARIO');
CREATE TYPE estado_pedido AS ENUM ('PENDIENTE', 'CONFIRMADO', 'TERMINADO', 'CANCELADO');
CREATE TYPE forma_pago AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');

CREATE TABLE categoria (
    id_categoria    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(80)  NOT NULL UNIQUE,
    descripcion     VARCHAR(255),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    --implementamos borrado logico para no romper futuras referencias
    eliminado       BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE usuario (
    id_usuario      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(80)   NOT NULL,
    apellido        VARCHAR(80)   NOT NULL,
    mail            VARCHAR(120)  NOT NULL UNIQUE,
    celular         VARCHAR(30),
    contrasena      VARCHAR(255)  NOT NULL,
    rol             rol_usuario   NOT NULL DEFAULT 'USUARIO',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    eliminado       BOOLEAN       NOT NULL DEFAULT FALSE
);

CREATE TABLE producto (
    id_producto     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(120)   NOT NULL,
    precio          NUMERIC(10,2)  NOT NULL CHECK (precio >= 0),
    descripcion     VARCHAR(255),
    stock           INTEGER        NOT NULL DEFAULT 0 CHECK (stock >= 0),
    imagen          VARCHAR(255),
    --se omiten productos no disponibles sin utilizar el borrado logico general
    disponible      BOOLEAN        NOT NULL DEFAULT TRUE,
    id_categoria    INTEGER        NOT NULL REFERENCES categoria(id_categoria) ON DELETE RESTRICT,
    eliminado       BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE pedido (
    id_pedido       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha           TIMESTAMPTZ    NOT NULL DEFAULT now(),
    estado          estado_pedido  NOT NULL DEFAULT 'PENDIENTE',
    forma_pago      forma_pago     NOT NULL,
    --Total desnormalizado ,para no tener problemas con futuros cambios ni saturar con consultas redundantes
    total           NUMERIC(10,2)  NOT NULL DEFAULT 0 CHECK (total >= 0),
    id_usuario      INTEGER        NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    eliminado       BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE detalle_pedido (
    id_detalle      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cantidad        INTEGER        NOT NULL CHECK (cantidad > 0),
    -- Se usa una copia de precio para que futuros cambios no afecten a pedidos anteriores
    precio_unitario NUMERIC(10,2)  NOT NULL CHECK (precio_unitario >= 0),
    subtotal        NUMERIC(10,2)  NOT NULL CHECK (subtotal >= 0) CHECK (subtotal = cantidad * precio_unitario),
    --La existencia del detalle depende de pedido (si se elimina, se borra con el)
    id_pedido       INTEGER        NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,

    id_producto     INTEGER        NOT NULL REFERENCES producto(id_producto) ON DELETE RESTRICT,
    eliminado       BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now(),
    --Permitimos sumamar la cantidad de articulos sin crear mas lineas
    UNIQUE (id_pedido, id_producto)
);


CREATE INDEX idx_pedido_usuario ON pedido(id_usuario);
CREATE INDEX idx_producto_categoria ON producto(id_categoria) WHERE eliminado = FALSE; --solo incluimos los productos que no estan borrados o "inactivos"
CREATE INDEX idx_detalle_pedido ON detalle_pedido(id_pedido);

--Un pedido confirmado no puede volver al estado PENDIENTE
CREATE OR REPLACE FUNCTION verificar_estado_pedido() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado = 'CONFIRMADO' AND NEW.estado = 'PENDIENTE' THEN
        RAISE EXCEPTION 'Un pedido confirmado no puede volver al estado PENDIENTE';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pedido_estado_irreversible ON pedido;


CREATE TRIGGER trg_pedido_estado_irreversible
    BEFORE UPDATE OF estado ON pedido
    FOR EACH ROW
    EXECUTE FUNCTION verificar_estado_pedido();


BEGIN;
-- Caso inválido: debería fallar
UPDATE pedido SET estado = 'PENDIENTE' WHERE id_pedido = 1;
-- Caso válido: debería funcionar
UPDATE pedido SET estado = 'CONFIRMADO' WHERE id_pedido = 1;
ROLLBACK;
-- crear usuario de prueba
INSERT INTO usuario (nombre, apellido, mail, celular, contrasena)
VALUES ('Usuario de prueba', 'Prueba', 'prueba@correo.com', '2610000000', '1234');
SELECT * FROM usuario;

-- Crear categoria de prueba
INSERT INTO categoria (nombre, descripcion, eliminado, created_at)
VALUES ('Calzado', 'Categoría de prueba', FALSE, NOW());
-- crear producto de prueba
INSERT INTO producto (nombre, precio, descripcion, stock, imagen, disponible, id_categoria, eliminado, created_at)
VALUES ('Zapatillas de prueba', 100, 'Producto de prueba', 10, 'img.png', TRUE, 1, FALSE, NOW());
SELECT * FROM producto;
--crear pedido prueba
INSERT INTO pedido (fecha, estado, forma_pago, total, id_usuario, eliminado, created_at)
VALUES (NOW(), 'PENDIENTE', 'EFECTIVO', 0, 1, FALSE, NOW());
SELECT * FROM pedido;
-- Caso válido: debe funcionar
INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, id_pedido, id_producto, eliminado, created_at)
VALUES (2, 100, 200, 3, 2, FALSE, NOW());

-- Caso inválido: debe fallar por el CHECK
INSERT INTO detalle_pedido (cantidad, precio_unitario, subtotal, id_pedido, id_producto, eliminado, created_at)
VALUES (2, 100, 300, 3, 2, FALSE, NOW());
