-- Comentarios : 
-- Teoria : 
    -- `TRIM()`: Elimina los espacios en blanco.
    -- `STRING_SPLIT(campo, 'caracter que lo separa')`: Se utiliza para dividir cadenas de texto que están separadas por comas.

------------------------------------------------------------------------------------------------------
-- Creacion de la bd
CREATE DATABASE netflix_bd2;
GO

USE netflix_bd2; 
GO

-- SELECT * FROM dbo.netflix_titles;
------------------------------------------------------------------------------------------------------
-----------------------------------
------  INSERT - categoria  -------
-----------------------------------

-- El SELECT DISTINCT se asegura de que solo se inserten categorías únicas.
-- Utilizamos la cláusula NOT IN para evitar la inserción de duplicados ya presentes en la tabla categoria.

-- Insertar categorías únicas desde la tabla netflix_titles
INSERT INTO categoria (descripcion)
SELECT DISTINCT TRIM(value) AS categoria
FROM dbo.netflix_titles
CROSS APPLY STRING_SPLIT(listed_in, ',')
WHERE TRIM(value) NOT IN (SELECT descripcion FROM categoria);
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM categoria
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------   INSERT - actor  ----------
-----------------------------------

-- Insertar actores únicos desde la tabla netflix_titles
INSERT INTO actor (nombre_apellido)
SELECT DISTINCT TRIM(value) AS actor
FROM dbo.netflix_titles
CROSS APPLY STRING_SPLIT(cast, ',')
WHERE TRIM(value) NOT IN (SELECT nombre_apellido FROM actor);

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM actor
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------   INSERT - tipo_show  ------
-----------------------------------

-- Insertar tipos de show únicos desde la tabla netflix_titles
INSERT INTO tipo_show (descripcion)
SELECT DISTINCT TRIM(type) AS tipo_show
FROM dbo.netflix_titles
WHERE type IS NOT NULL
AND TRIM(type) NOT IN (SELECT descripcion FROM tipo_show);
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM tipo_show
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------   INSERT - pais  -----------
-----------------------------------

-- Insertar países únicos desde la tabla netflix_titles
INSERT INTO pais (descripcion)
SELECT DISTINCT TRIM(value) AS pais
FROM dbo.netflix_titles
CROSS APPLY STRING_SPLIT(country, ',')
WHERE TRIM(value) NOT IN (SELECT descripcion FROM pais);
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM pais
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------   INSERT - director  -------
-----------------------------------

-- Insertar directores únicos desde la tabla netflix_titles
INSERT INTO director (nombre_apellido)
SELECT DISTINCT TRIM(value) AS director
FROM dbo.netflix_titles
CROSS APPLY STRING_SPLIT(director, ',')
WHERE TRIM(value) NOT IN (SELECT nombre_apellido FROM director)
AND value IS NOT NULL;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM director
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------   INSERT - rating  ---------
-----------------------------------

-- Insertar ratings válidos desde la tabla netflix_titles
INSERT INTO rating (descripcion)
SELECT DISTINCT TRIM(rating) AS rating
FROM dbo.netflix_titles
WHERE TRIM(rating) NOT IN (SELECT descripcion FROM rating)
AND TRIM(rating) IN ('G', 'PG', 'PG-13', 'R', 'NC-17',
                     'TV-Y', 'TV-Y7', 'TV-Y7-FV', 'TV-G', 'TV-PG',
                     'TV-14', 'TV-MA', 'NR', 'UR')
AND rating IS NOT NULL;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM rating
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------  INSERT - show  ------------
-----------------------------------

-- Insertar shows desde la tabla netflix_titles
INSERT INTO Show (id_show, titulo, fecha_salida, duracion, año_lanzamiento, descripcion, id_tipo, id_rating)
SELECT 
    show_id,
    title AS titulo,
    date_added AS fecha_salida,
    duration AS duracion,
    release_year AS año_lanzamiento,
    description AS descripcion,
    (SELECT id_tipo FROM tipo_show WHERE descripcion = type) AS id_tipo,
    (SELECT id_rating FROM rating WHERE descripcion = rating) AS id_rating
FROM dbo.netflix_titles;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM Show
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
---- INSERT - show-Director  ------
-----------------------------------

-- Insertar en la tabla show_director sin cursor
INSERT INTO show_director (id_director, id_show)
SELECT d.id_director, nt.show_id
FROM dbo.netflix_titles nt
JOIN director d ON d.nombre_apellido = nt.director
WHERE nt.director IS NOT NULL;
GO

-- Verificamos los datos insertados
SELECT * FROM show_director;
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
---- INSERT - show-Pais  ----------
-----------------------------------

-- Insertar en la tabla show_pais sin cursor
INSERT INTO show_pais (id_pais, id_show)
SELECT p.id_pais, nt.show_id
FROM dbo.netflix_titles nt
CROSS APPLY STRING_SPLIT(nt.country, ',') AS paises
JOIN pais p ON LTRIM(RTRIM(paises.value)) = p.descripcion
WHERE nt.country IS NOT NULL;
GO

-- Verificamos los datos insertados
SELECT * FROM show_pais;
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
---- INSERT - show-Categoria  -----
-----------------------------------

-- Insertar en la tabla show_categoria sin cursor
INSERT INTO show_categoria (id_show, id_categoria)
SELECT nt.show_id, c.id_categoria
FROM dbo.netflix_titles nt
CROSS APPLY STRING_SPLIT(nt.listed_in, ',') AS categorias
JOIN categoria c ON LTRIM(RTRIM(categorias.value)) = c.descripcion
WHERE nt.listed_in IS NOT NULL;
GO

-- Verificamos los datos insertados
SELECT * FROM show_categoria;
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
------- INSERT - elenco -----------
-----------------------------------

-- Insertar en la tabla elenco sin duplicar claves primarias
INSERT INTO elenco (id_actor, id_show)
SELECT DISTINCT a.id_actor, nt.show_id
FROM dbo.netflix_titles nt
CROSS APPLY STRING_SPLIT(nt.cast, ',') AS actors
JOIN actor a ON LTRIM(RTRIM(actors.value)) = a.nombre_apellido
WHERE nt.cast IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM elenco e
      WHERE e.id_actor = a.id_actor 
        AND e.id_show = nt.show_id
  );


-- Verificamos los datos insertados
SELECT * FROM elenco;
GO

------------------------------------------------------------------------------------------------------
-----------------------------------
--------   Query - Aux  -----------
-----------------------------------


-- Eliminar duplicados (sin usar CTE):

    -- DELETE FROM actor
    -- WHERE id_actor NOT IN (
    --     SELECT MIN(id_actor)
    --     FROM actor
    --     GROUP BY nombre_apellido
    -- );

-- Usamos una subconsulta que obtiene el MIN(id_actor) para cada nombre de actor (lo que garantiza que solo mantendremos una entrada por actor).
-- Luego eliminamos todas las filas cuyo id_actor no sea el mínimo, eliminando así los duplicados.