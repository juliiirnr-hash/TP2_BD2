-- =====================================================================
-- Schema del sistema de pedidos con catálogo de productos (BD2 - TP2)
-- Motor: PostgreSQL
-- Re-ejecutable: usa DROP ... IF EXISTS para poder volver a correrlo.
-- ---------------------------------------------------------------------
-- Objetivo: entregable de la materia Bases de Datos 2. No existe capa
-- de aplicación; la base de datos (DDL) es el entregable.
--
-- Entidades: usuario, categoria, producto, pedido, detalle_pedido.
-- Convenciones: snake_case en español, tablas en singular, PK id_<tabla>,
-- FK con el nombre de la PK referenciada. Borrado lógico con `eliminado`.
-- Desnormalización intencional: pedido.total (suma cacheada) y
-- detalle_pedido.precio_unitario (snapshot al momento de la compra).
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------
DROP TYPE IF EXISTS rol_usuario CASCADE;
CREATE TYPE rol_usuario AS ENUM ('ADMIN', 'USUARIO');

DROP TYPE IF EXISTS estado_pedido CASCADE;
CREATE TYPE estado_pedido AS ENUM ('PENDIENTE', 'CONFIRMADO', 'TERMINADO', 'CANCELADO');

DROP TYPE IF EXISTS forma_pago CASCADE;
CREATE TYPE forma_pago AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');

-- ---------------------------------------------------------------------
-- Tabla usuario
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS detalle_pedido CASCADE;
DROP TABLE IF EXISTS pedido CASCADE;
DROP TABLE IF EXISTS producto CASCADE;
DROP TABLE IF EXISTS categoria CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

CREATE TABLE usuario (
    id_usuario   INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(100)  NOT NULL,
    mail         VARCHAR(150)  NOT NULL,
    telefono     VARCHAR(30),
    direccion    VARCHAR(255),
    rol_usuario  rol_usuario   NOT NULL DEFAULT 'USUARIO',
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    eliminado    BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT usuario_mail_unico UNIQUE (mail),
    CONSTRAINT usuario_mail_no_vacio CHECK (mail <> '')
);

-- Índice parcial para búsquedas sobre usuarios activos
CREATE INDEX idx_usuario_rol ON usuario(rol_usuario) WHERE eliminado = FALSE;

-- ---------------------------------------------------------------------
-- Tabla categoria
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria  INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(100)  NOT NULL,
    descripcion   TEXT,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    eliminado     BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT categoria_nombre_unico UNIQUE (nombre),
    CONSTRAINT categoria_nombre_no_vacio CHECK (nombre <> '')
);

-- ---------------------------------------------------------------------
-- Tabla producto
-- ---------------------------------------------------------------------
CREATE TABLE producto (
    id_producto   INTEGER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_categoria  INTEGER        NOT NULL,
    nombre        VARCHAR(150)   NOT NULL,
    descripcion   TEXT,
    precio        NUMERIC(10,2)  NOT NULL,
    stock         INTEGER        NOT NULL DEFAULT 0,
    imagen        VARCHAR(255),
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT now(),
    eliminado     BOOLEAN        NOT NULL DEFAULT FALSE,
    CONSTRAINT producto_precio_no_negativo CHECK (precio >= 0),
    CONSTRAINT producto_stock_no_negativo CHECK (stock >= 0),
    CONSTRAINT producto_nombre_no_vacio CHECK (nombre <> ''),
    -- RESTRICT por defecto: no se puede borrar una categoría con productos
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria (id_categoria) ON DELETE RESTRICT
);

-- Índice parcial sobre el catálogo activo por categoría
CREATE INDEX idx_producto_categoria ON producto(id_categoria) WHERE eliminado = FALSE;

-- ---------------------------------------------------------------------
-- Tabla pedido
-- ---------------------------------------------------------------------
CREATE TABLE pedido (
    id_pedido    INTEGER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario   INTEGER         NOT NULL,
    estado       estado_pedido   NOT NULL DEFAULT 'PENDIENTE',
    forma_pago   forma_pago      NOT NULL DEFAULT 'EFECTIVO',
    -- total es una suma cacheada de detalle_pedido (desnormalización intencional)
    total        NUMERIC(10,2)   NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT now(),
    eliminado    BOOLEAN         NOT NULL DEFAULT FALSE,
    CONSTRAINT pedido_total_no_negativo CHECK (total >= 0),
    -- RESTRICT por defecto: no se puede borrar un usuario con pedidos
    CONSTRAINT fk_pedido_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT
);

-- Índice parcial para listar pedidos activos de un usuario
CREATE INDEX idx_pedido_usuario ON pedido(id_usuario) WHERE eliminado = FALSE;
CREATE INDEX idx_pedido_estado ON pedido(estado) WHERE eliminado = FALSE;

-- ---------------------------------------------------------------------
-- Tabla detalle_pedido
-- ---------------------------------------------------------------------
CREATE TABLE detalle_pedido (
    id_detalle       INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido        INTEGER       NOT NULL,
    id_producto      INTEGER       NOT NULL,
    cantidad         INTEGER       NOT NULL,
    -- precio_unitario es un snapshot al momento de la compra.
    -- No referenciar producto.precio en consultas históricas.
    precio_unitario  NUMERIC(10,2) NOT NULL,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    eliminado        BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT detalle_cantidad_positiva CHECK (cantidad > 0),
    CONSTRAINT detalle_precio_no_negativo CHECK (precio_unitario >= 0),
    -- CASCADE: una línea no tiene sentido sin su pedido padre
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_pedido)
        REFERENCES pedido (id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto) ON DELETE RESTRICT,
    -- No se permite repetir el mismo producto dentro de un pedido
    CONSTRAINT detalle_pedido_producto_unico UNIQUE (id_pedido, id_producto)
);

COMMIT;
