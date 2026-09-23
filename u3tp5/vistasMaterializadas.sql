--query original (Planning Time: 0.472 ms     Execution Time: 0.144 ms    )

    --SELECT p.nombre  AS producto,
	--       c.nombre  AS categoria,
	--       p.precio,
	--       p.stock
	--FROM producto p
	--JOIN categoria c ON c.id_categoria = p.id_categoria
	--WHERE p.eliminado = FALSE
	--  AND p.disponible = TRUE
	--ORDER BY p.precio DESC
	--LIMIT 10;


--vista materializada ( Planning Time: 6.649 ms    Execution Time: 0.110 ms   )

create materialized view productos_caros_pcategoria as
	SELECT p.nombre  AS producto,
	       c.nombre  AS categoria,
	       p.precio,
	       p.stock
	FROM producto p
	JOIN categoria c ON c.id_categoria = p.id_categoria
	WHERE p.eliminado = FALSE
	  AND p.disponible = TRUE
	ORDER BY p.precio DESC
	LIMIT 10
with data;

--indice

CREATE UNIQUE INDEX pcpc_id ON productos_caros_pcategoria (producto,categoria);
    --el refresh deberia usarse cada vez que el catalogo de productos o sus precios es actualizado o con un periodo definido segun la actualizacion de productos del negocio, 
    --si bien no necesita ser constante, es importante que se haga cada vez que haya una modificacion ya que el cliente podria recibir datos desactualizados


