PRAGMA foreign_keys = ON;

-- schema de la tablet (SQLite 3.37+)
-- la tablet solo guarda copia del catalogo y borradores: no decide precio ni stock

-- borro las tablas si ya existian
DROP TABLE IF EXISTS cola_sync;
DROP TABLE IF EXISTS item_borrador;
DROP TABLE IF EXISTS pedido_borrador;
DROP TABLE IF EXISTS producto_cache;

-- creo la tabla producto_cache (copia del catalogo del servidor)
CREATE TABLE producto_cache (
    id               INTEGER PRIMARY KEY,
    nombre           TEXT    NOT NULL,
    precio_centavos  INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto      INTEGER NOT NULL DEFAULT 0 CHECK (stock_visto >= 0),
    disponible       INTEGER NOT NULL DEFAULT 1 CHECK (disponible IN (0, 1)),
    eliminado        INTEGER NOT NULL DEFAULT 0 CHECK (eliminado IN (0, 1)),
    fecha_copia      TEXT    NOT NULL
) STRICT;

-- creo la tabla pedido_borrador
CREATE TABLE pedido_borrador (
    id_local    TEXT PRIMARY KEY,
    usuario     TEXT NOT NULL,
    forma_pago  TEXT NOT NULL CHECK (forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    fecha       TEXT NOT NULL
) STRICT;

-- creo la tabla item_borrador
CREATE TABLE item_borrador (
    id_local                 TEXT    NOT NULL,
    producto_id              INTEGER NOT NULL,
    cantidad                 INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto    INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local)    REFERENCES pedido_borrador (id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache  (id)        ON DELETE RESTRICT
) STRICT;

-- creo la tabla cola_sync
CREATE TABLE cola_sync (
    solicitud_uuid  TEXT PRIMARY KEY,
    id_local        TEXT NOT NULL,
    estado          TEXT NOT NULL DEFAULT 'PENDIENTE'
                    CHECK (estado IN ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo          TEXT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador (id_local) ON DELETE CASCADE
) STRICT;
