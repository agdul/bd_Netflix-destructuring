-- Comentarios : 
    -- `Tratamientos de null sobre las tablas intermediarias`: 
        -- Para que los datos tengan consintencia, a pesesar de como estan dados entregados en la table madre, decidi ignorar todos aquellos registros que contengan NULL, en aquellos campos que sean PK necesarias al momento de la desestructuracion y la normalizacion

------------------------------------------------------------------------------------------------------

-----------------------------------
------  INSERT - categoria  -------
-----------------------------------

-- Si existe el procedimiento lo elimina para instanciarlo nuevamente 
DROP PROCEDURE IF EXISTS InsertarCategoriasUnicas;
GO
-- Procedimiento para insertar categorías únicas
CREATE PROCEDURE InsertarCategoriasUnicas
AS
BEGIN
    -- Variable para almacenar temporalmente las categorías
    DECLARE @categorias NVARCHAR(MAX);
    DECLARE @categoria NVARCHAR(100);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE categorias_cursor CURSOR FOR
    SELECT show_id, listed_in
    FROM dbo.netflix_titles
    WHERE listed_in IS NOT NULL;
    -- Abre el cursor para comenzar a recorrer
    OPEN categorias_cursor;

    --Recupera la primera fila de resultados del cursor y almacena los valores de las columnas show_id y listed_in en las variables @show_id y @categorias, respectivamente.
    FETCH NEXT FROM categorias_cursor INTO @show_id, @categorias;

    -- Loop sobre cada registro de netflix_titles
    -- Inicia un bucle que se repetirá mientras el cursor siga obteniendo filas (@@FETCH_STATUS = 0 significa que aún hay filas disponibles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Dividir las categorías (separadas por comas)
        -- Inicia un bucle interno que se ejecuta mientras en la variable @categorias haya comas, lo que significa que contiene más de una categoría 
        WHILE CHARINDEX(',', @categorias) > 0
        BEGIN
            -- Extraer una categoría (la que está antes de la primera coma)
            SET @categoria = LTRIM(RTRIM(LEFT(@categorias, CHARINDEX(',', @categorias) - 1)));
            -- Extrae la primera categoría de la lista (la que está antes de la primera coma) y la guarda en la variable @categoria. Usa LEFT para obtener la parte de la cadena antes de la primera coma y luego LTRIM y RTRIM para eliminar espacios en blanco a los lados.

            -- Insertar categoría si no existe
            IF NOT EXISTS (SELECT 1 FROM categoria WHERE descripcion = @categoria)
            BEGIN
                INSERT INTO categoria (descripcion) VALUES (@categoria);
            END
            -- Actualizar @categorias para remover la categoría ya procesada
            SET @categorias = LTRIM(RTRIM(SUBSTRING(@categorias, CHARINDEX(',', @categorias) + 1, LEN(@categorias))));
        END
        -- Fin del bucle interno, mientras en la variable @categorias haya comas.

        -- Procesar la última categoría (después de la última coma o si no hay comas)
        SET @categoria = LTRIM(RTRIM(@categorias));
        IF NOT EXISTS (SELECT 1 FROM categoria WHERE descripcion = @categoria)
        BEGIN
            INSERT INTO categoria (descripcion) VALUES (@categoria);
        END
        -- Después de salir del bucle interno, procesa la última categoría que quedó en @categorias (ya que no tenía una coma al final). También la inserta en la tabla categoria si no existe.
        FETCH NEXT FROM categorias_cursor INTO @show_id, @categorias;
        -- Obtiene la siguiente fila de resultados del cursor y repite el proceso. Si no hay más filas, el cursor se cierra.
    END
    CLOSE categorias_cursor;
    DEALLOCATE categorias_cursor;
    --Cierra el cursor y libera los recursos asociados a él.
END; -- Fin de procedimiento almacenado
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarCategoriasUnicas;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM categoria
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
------   INSERT - actor  ----------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarActoresUnicos;
GO

--Inicio del procedimiento
CREATE PROCEDURE InsertarActoresUnicos
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los actores
    DECLARE @actores NVARCHAR(MAX);
    DECLARE @actor NVARCHAR(100);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE actores_cursor CURSOR FOR
    SELECT show_id, cast
    FROM dbo.netflix_titles
    WHERE cast IS NOT NULL;

    -- Abre el cursor para comenzar a recorrer
    OPEN actores_cursor;

    -- Recuperar la primera fila de resultados del cursor y almacenar los valores de show_id y cast en las variables @show_id y @actores
    FETCH NEXT FROM actores_cursor INTO @show_id, @actores;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Bucle interno para separar los actores (separados por comas)
        WHILE CHARINDEX(',', @actores) > 0
        BEGIN
            -- Extraer un actor (el que está antes de la primera coma)
            SET @actor = LTRIM(RTRIM(LEFT(@actores, CHARINDEX(',', @actores) - 1)));

            -- Insertar actor si no existe
            IF NOT EXISTS (SELECT 1 FROM actor WHERE nombre_apellido = @actor)
            BEGIN
                INSERT INTO actor (nombre_apellido) VALUES (@actor);
            END

            -- Actualizar @actores para remover el actor ya procesado
            SET @actores = LTRIM(RTRIM(SUBSTRING(@actores, CHARINDEX(',', @actores) + 1, LEN(@actores))));
        END

        -- Procesar el último actor (después de la última coma)
        SET @actor = LTRIM(RTRIM(@actores));
        IF NOT EXISTS (SELECT 1 FROM actor WHERE nombre_apellido = @actor)
        BEGIN
            INSERT INTO actor (nombre_apellido) VALUES (@actor);
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM actores_cursor INTO @show_id, @actores;
    END

    -- Cerrar y liberar el cursor
    CLOSE actores_cursor;
    DEALLOCATE actores_cursor;
END; --Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarActoresUnicos;
GO

-- Inicio - Eliminar Duplicados 
WITH CTE AS (
    SELECT 
        id_actor, 
        nombre_apellido,
        ROW_NUMBER() OVER (PARTITION BY nombre_apellido ORDER BY id_actor) AS row_num
    FROM actor
)
DELETE FROM CTE WHERE row_num > 1;
-- Fin - Eliminar Duplicados 
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM actor;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
------   INSERT - tipo_show  ------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarTiposDeShow;
GO

--Inicio del procedimiento
CREATE PROCEDURE InsertarTiposDeShow
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los tipos de show
    DECLARE @tipo_show NVARCHAR(100);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE tipos_cursor CURSOR FOR
    SELECT show_id, type
    FROM dbo.netflix_titles
    WHERE type IS NOT NULL;

    -- Abrir el cursor para comenzar a recorrer
    OPEN tipos_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM tipos_cursor INTO @show_id, @tipo_show;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insertar tipo de show si no existe
        IF NOT EXISTS (SELECT 1 FROM tipo_show WHERE descripcion = @tipo_show)
        BEGIN
            INSERT INTO tipo_show (descripcion) VALUES (@tipo_show);
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM tipos_cursor INTO @show_id, @tipo_show;
    END

    -- Cerrar y liberar el cursor
    CLOSE tipos_cursor;
    DEALLOCATE tipos_cursor;
END;--Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarTiposDeShow;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM tipo_show;

------------------------------------------------------------------------------------------------------

-----------------------------------
------   INSERT - pais  -----------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarPaises;
GO

--Inicio del procedimiento
CREATE PROCEDURE InsertarPaises
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los países
    DECLARE @paises NVARCHAR(MAX);
    DECLARE @pais NVARCHAR(100);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE paises_cursor CURSOR FOR
    SELECT show_id, country
    FROM dbo.netflix_titles
    WHERE country IS NOT NULL;

    -- Abrir el cursor para comenzar a recorrer
    OPEN paises_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM paises_cursor INTO @show_id, @paises;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Bucle interno para separar los países (separados por comas)
        WHILE CHARINDEX(',', @paises) > 0
        BEGIN
            -- Extraer un país (el que está antes de la primera coma)
            SET @pais = LTRIM(RTRIM(LEFT(@paises, CHARINDEX(',', @paises) - 1)));

            -- Insertar país si no existe
            IF NOT EXISTS (SELECT 1 FROM pais WHERE descripcion = @pais)
            BEGIN
                INSERT INTO pais (descripcion) VALUES (@pais);
            END

            -- Actualizar @paises para remover el país ya procesado
            SET @paises = LTRIM(RTRIM(SUBSTRING(@paises, CHARINDEX(',', @paises) + 1, LEN(@paises))));
        END

        -- Procesar el último país (después de la última coma o si no hay comas)
        SET @pais = LTRIM(RTRIM(@paises));
        IF NOT EXISTS (SELECT 1 FROM pais WHERE descripcion = @pais)
        BEGIN
            INSERT INTO pais (descripcion) VALUES (@pais);
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM paises_cursor INTO @show_id, @paises;
    END

    -- Cerrar y liberar el cursor
    CLOSE paises_cursor;
    DEALLOCATE paises_cursor;
END;--Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarPaises;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM pais;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
------   INSERT - director  -------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarDirectores;
GO

--Inicio del procedimiento
CREATE PROCEDURE InsertarDirectores
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los directores
    DECLARE @directores NVARCHAR(MAX);
    DECLARE @director NVARCHAR(100);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE directores_cursor CURSOR FOR
    SELECT show_id, director
    FROM dbo.netflix_titles
    WHERE director IS NOT NULL;

    -- Abrir el cursor para comenzar a recorrer
    OPEN directores_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM directores_cursor INTO @show_id, @directores;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Bucle interno para separar los directores (separados por comas)
        WHILE CHARINDEX(',', @directores) > 0
        BEGIN
            -- Extraer un director (el que está antes de la primera coma)
            SET @director = LTRIM(RTRIM(LEFT(@directores, CHARINDEX(',', @directores) - 1)));

            -- Verificar si el director ya existe antes de insertarlo
            IF NOT EXISTS (SELECT 1 FROM director WHERE nombre_apellido = @director)
            BEGIN
                INSERT INTO director (nombre_apellido) VALUES (@director);
            END

            -- Actualizar @directores para remover el director ya procesado
            SET @directores = LTRIM(RTRIM(SUBSTRING(@directores, CHARINDEX(',', @directores) + 1, LEN(@directores))));
        END

        -- Procesar el último director (después de la última coma o si no hay comas)
        SET @director = LTRIM(RTRIM(@directores));
        IF NOT EXISTS (SELECT 1 FROM director WHERE nombre_apellido = @director)
        BEGIN
            INSERT INTO director (nombre_apellido) VALUES (@director);
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM directores_cursor INTO @show_id, @directores;
    END

    -- Cerrar y liberar el cursor
    CLOSE directores_cursor;
    DEALLOCATE directores_cursor;
END;
GO
--Fin del procedimiento

-- Ejecutamos el procedimento almacenado 
EXEC InsertarDirectores;
GO

-- Eliminar datos duplicados 
WITH CTE AS (
    SELECT 
        id_director, 
        nombre_apellido,
        ROW_NUMBER() OVER (PARTITION BY nombre_apellido ORDER BY id_director) AS row_num
    FROM director
)
DELETE FROM CTE WHERE row_num > 1;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM director;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
------   INSERT - rating  ---------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarRatings;
GO

-- Inicio del procedimiento
CREATE PROCEDURE InsertarRatings
AS
BEGIN
    -- Declarar variables para almacenar temporalmente las calificaciones
    DECLARE @ratings NVARCHAR(MAX);
    DECLARE @rating NVARCHAR(100);
    DECLARE @show_id NVARCHAR(50);

    -- Lista de calificaciones válidas
    DECLARE @validRatings TABLE (rating NVARCHAR(100));
    
    -- Insertar calificaciones válidas en la tabla temporal
    INSERT INTO @validRatings (rating)
    VALUES ('G'), ('PG'), ('PG-13'), ('R'), ('NC-17'),
           ('TV-Y'), ('TV-Y7'), ('TV-Y7-FV'), ('TV-G'), ('TV-PG'),
           ('TV-14'), ('TV-MA'), ('NR'), ('UR');
    
    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE ratings_cursor CURSOR FOR
    SELECT show_id, rating
    FROM dbo.netflix_titles
    WHERE rating IS NOT NULL;

    -- Abrir el cursor para comenzar a recorrer
    OPEN ratings_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM ratings_cursor INTO @show_id, @ratings;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Extraer una calificación y eliminar espacios en blanco
        SET @rating = LTRIM(RTRIM(@ratings));

        -- Verificar si la calificación es válida y si no existe en la tabla rating
        IF EXISTS (SELECT 1 FROM @validRatings WHERE rating = @rating)
           AND NOT EXISTS (SELECT 1 FROM rating WHERE descripcion = @rating)
        BEGIN
            -- Insertar la calificación en la tabla si es válida y no existe
            INSERT INTO rating (descripcion) VALUES (@rating);
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM ratings_cursor INTO @show_id, @ratings;
    END

    -- Cerrar y liberar el cursor
    CLOSE ratings_cursor;
    DEALLOCATE ratings_cursor;
END;-- Fin del procedimiento
GO


-- Ejecutamos el procedimento almacenado 
EXEC InsertarRatings;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM rating;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
------  INSERT - show  ------------
-----------------------------------

-- Cambiar la columna titulo a NVARCHAR hacemos esto para que nos acepte el unicode que te permite amacenar caracteres de otro alfabeto
ALTER TABLE Show
ALTER COLUMN titulo NVARCHAR(255);
-- Cambiar la columna descripcion a NVARCHAR hacemos esto para que nos acepte el unicode que te permite amacenar caracteres de otro alfabeto
ALTER TABLE Show
ALTER COLUMN descripcion NVARCHAR(MAX);


-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarShows;
GO

-- Inicio del procedimiento
CREATE PROCEDURE InsertarShows
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los datos
    DECLARE @show_id NVARCHAR(50);
    DECLARE @titulo NVARCHAR(255);
    DECLARE @fecha_salida DATE;
    DECLARE @duracion NVARCHAR(50);
    DECLARE @año_lanzamiento INT;
    DECLARE @descripcion NVARCHAR(MAX);
    DECLARE @tipo NVARCHAR(100);
    DECLARE @rating NVARCHAR(100);
    DECLARE @id_tipo INT;
    DECLARE @id_rating INT;

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE shows_cursor CURSOR FOR
    SELECT show_id, title, date_added, duration, release_year, description, type, rating
    FROM dbo.netflix_titles;

    -- Abrir el cursor para comenzar a recorrer
    OPEN shows_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM shows_cursor INTO 
        @show_id, @titulo, @fecha_salida, @duracion, @año_lanzamiento, @descripcion, @tipo, @rating;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Buscar el id_tipo desde la tabla tipo_show
        SELECT @id_tipo = id_tipo FROM tipo_show WHERE descripcion = @tipo;

        -- Si el tipo no existe, se pone NULL
        IF @id_tipo IS NULL
            SET @id_tipo = NULL;

        -- Buscar el id_rating desde la tabla rating
        SELECT @id_rating = id_rating FROM rating WHERE descripcion = @rating;

        -- Si el rating no existe, se pone NULL
        IF @id_rating IS NULL
            SET @id_rating = NULL;

        -- Insertar el show en la tabla Show
        INSERT INTO Show (id_show, titulo, fecha_salida, duracion, año_lanzamiento, descripcion, id_tipo, id_rating)
        VALUES (@show_id, @titulo, @fecha_salida, @duracion, @año_lanzamiento, @descripcion, @id_tipo, @id_rating);

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM shows_cursor INTO 
            @show_id, @titulo, @fecha_salida, @duracion, @año_lanzamiento, @descripcion, @tipo, @rating;
    END

    -- Cerrar y liberar el cursor
    CLOSE shows_cursor;
    DEALLOCATE shows_cursor;
END;
-- Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarShows;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM Show;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
---- INSERT - show-Director  ------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarShowDirector;
GO

-- Inicio del procedimiento
CREATE PROCEDURE InsertarShowDirector
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los valores
    DECLARE @director NVARCHAR(255);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles que tienen director
    DECLARE director_cursor CURSOR FOR
    SELECT show_id, director
    FROM dbo.netflix_titles
    WHERE director IS NOT NULL;

    -- Abrir el cursor para comenzar a recorrer
    OPEN director_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM director_cursor INTO @show_id, @director;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insertar en la tabla show_director si el director existe
        IF EXISTS (SELECT 1 FROM director WHERE nombre_apellido = @director)
        BEGIN
            INSERT INTO show_director (id_director, id_show)
            SELECT id_director, @show_id
            FROM director
            WHERE nombre_apellido = @director;
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM director_cursor INTO @show_id, @director;
    END

    -- Cerrar y liberar el cursor
    CLOSE director_cursor;
    DEALLOCATE director_cursor;
END;
-- Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarShowDirector;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM show_director;
GO
------------------------------------------------------------------------------------------------------

-----------------------------------
---- INSERT - show-Pais  ----------
-----------------------------------

-- Si existe el procedimiento lo elimina
DROP PROCEDURE IF EXISTS InsertarShowDirector;
GO


-- Inicio del procedimiento
CREATE PROCEDURE InsertarShowPais
AS
BEGIN
    -- Declarar variables para almacenar temporalmente los valores
    DECLARE @paises NVARCHAR(MAX);
    DECLARE @pais NVARCHAR(255);
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles que tienen país
    DECLARE pais_cursor CURSOR FOR
    SELECT show_id, country
    FROM dbo.netflix_titles
    WHERE country IS NOT NULL;

    -- Abrir el cursor para comenzar a recorrer
    OPEN pais_cursor;

    -- Recuperar la primera fila del cursor
    FETCH NEXT FROM pais_cursor INTO @show_id, @paises;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Bucle interno para separar los países (separados por comas)
        WHILE CHARINDEX(',', @paises) > 0
        BEGIN
            -- Extraer un país (el que está antes de la primera coma)
            SET @pais = LTRIM(RTRIM(LEFT(@paises, CHARINDEX(',', @paises) - 1)));

            -- Insertar país en la tabla show_pais si existe en la tabla pais
            IF EXISTS (SELECT 1 FROM pais WHERE descripcion = @pais)
            BEGIN
                INSERT INTO show_pais (id_pais, id_show)
                SELECT id_pais, @show_id
                FROM pais
                WHERE descripcion = @pais;
            END

            -- Actualizar @paises para remover el país ya procesado
            SET @paises = LTRIM(RTRIM(SUBSTRING(@paises, CHARINDEX(',', @paises) + 1, LEN(@paises))));
        END

        -- Procesar el último país (después de la última coma o si no hay comas)
        SET @pais = LTRIM(RTRIM(@paises));
        IF EXISTS (SELECT 1 FROM pais WHERE descripcion = @pais)
        BEGIN
            INSERT INTO show_pais (id_pais, id_show)
            SELECT id_pais, @show_id
            FROM pais
            WHERE descripcion = @pais;
        END

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM pais_cursor INTO @show_id, @paises;
    END

    -- Cerrar y liberar el cursor
    CLOSE pais_cursor;
    DEALLOCATE pais_cursor;
END;
-- Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC InsertarShowPais;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM show_pais;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
---- INSERT - show-Categoria  -----
-----------------------------------

-- Si existe el procedimiento lo elimina para instanciarlo nuevamente 
DROP PROCEDURE IF EXISTS PoblarShowCategoria;
GO

-- Procedimiento para cargar tabla intermedia ShowCategoria
CREATE PROCEDURE PoblarShowCategoria
AS
BEGIN
    -- Variables para recorrer las categorías y show_id
    DECLARE @categorias NVARCHAR(MAX);
    DECLARE @categoria NVARCHAR(100);
    DECLARE @id_categoria INT;
    DECLARE @show_id NVARCHAR(50);

    -- Cursor para recorrer todas las filas de dbo.netflix_titles
    DECLARE show_categoria_cursor CURSOR FOR
    SELECT show_id, listed_in
    FROM dbo.netflix_titles
    WHERE listed_in IS NOT NULL;  -- Ignorar si listed_in es NULL

    OPEN show_categoria_cursor;

    FETCH NEXT FROM show_categoria_cursor INTO @show_id, @categorias;

    -- Loop sobre cada registro de netflix_titles
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Dividir las categorías (separadas por comas)
        WHILE CHARINDEX(',', @categorias) > 0
        BEGIN
            -- Extraer una categoría
            SET @categoria = LTRIM(RTRIM(LEFT(@categorias, CHARINDEX(',', @categorias) - 1)));

            -- Buscar id_categoria correspondiente
            SELECT @id_categoria = id_categoria
            FROM categoria
            WHERE descripcion = @categoria;

            -- Insertar en show_categoria solo si id_categoria NO es NULL
            IF @id_categoria IS NOT NULL
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM show_categoria WHERE id_show = @show_id AND id_categoria = @id_categoria)
                BEGIN
                    INSERT INTO show_categoria (id_show, id_categoria) VALUES (@show_id, @id_categoria);
                END
            END

            -- Remover la categoría procesada
            SET @categorias = LTRIM(RTRIM(SUBSTRING(@categorias, CHARINDEX(',', @categorias) + 1, LEN(@categorias))));
        END

        -- Procesar la última categoría
        SET @categoria = LTRIM(RTRIM(@categorias));
        SELECT @id_categoria = id_categoria
        FROM categoria
        WHERE descripcion = @categoria;

        -- Insertar en show_categoria solo si id_categoria NO es NULL
        IF @id_categoria IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM show_categoria WHERE id_show = @show_id AND id_categoria = @id_categoria)
            BEGIN
                INSERT INTO show_categoria (id_show, id_categoria) VALUES (@show_id, @id_categoria);
            END
        END

        FETCH NEXT FROM show_categoria_cursor INTO @show_id, @categorias;
    END

    CLOSE show_categoria_cursor;
    DEALLOCATE show_categoria_cursor;
END; -- Fin del procedimiento
GO

-- Ejecutamos el procedimento almacenado 
EXEC PoblarShowCategoria;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM show_categoria;
GO

------------------------------------------------------------------------------------------------------

-----------------------------------
------- INSERT - elenco -----------
-----------------------------------

-- Si existe el procedimiento lo elimina para instanciarlo nuevamente 
DROP PROCEDURE IF EXISTS InsertarElenco;
GO

-- Mejor opcion en cuanto a rendimiento : 
CREATE PROCEDURE InsertarElenco
AS
BEGIN
    -- Insertar en la tabla elenco solo los actores que existen en la tabla actor
    INSERT INTO elenco (id_actor, id_show)
    SELECT a.id_actor, nt.show_id
    FROM dbo.netflix_titles nt
    CROSS APPLY STRING_SPLIT(nt.cast, ',') AS actors
    JOIN actor a ON LTRIM(RTRIM(actors.value)) = a.nombre_apellido
    WHERE nt.cast IS NOT NULL;
END;
GO

-- El uso de cursores tiene un costo muy elevado en este caso al tratar tantos datos 
-- Inicio del procedimiento
-- CREATE PROCEDURE InsertarElenco
-- AS
-- BEGIN
--     -- Declarar variables para almacenar temporalmente los actores
--     DECLARE @actor NVARCHAR(255);
--     DECLARE @show_id NVARCHAR(50);

--     -- Cursor para recorrer todas las filas de dbo.netflix_titles que tienen actores
--     DECLARE elenco_cursor CURSOR FOR
--     SELECT show_id, value AS actor
--     FROM dbo.netflix_titles
--     CROSS APPLY STRING_SPLIT(cast, ',')
--     WHERE cast IS NOT NULL;

--     -- Abrir el cursor para comenzar a recorrer
--     OPEN elenco_cursor;

--     -- Recuperar la primera fila del cursor
--     FETCH NEXT FROM elenco_cursor INTO @show_id, @actor;

--     -- Loop sobre cada registro de netflix_titles
--     WHILE @@FETCH_STATUS = 0
--     BEGIN
--         -- Remover espacios en blanco del actor
--         SET @actor = LTRIM(RTRIM(@actor));

--         -- Insertar actor en la tabla elenco si existe en la tabla actor
--         IF EXISTS (SELECT 1 FROM actor WHERE nombre_apellido = @actor)
--         BEGIN
--             INSERT INTO elenco (id_actor, id_show)
--             SELECT id_actor, @show_id
--             FROM actor
--             WHERE nombre_apellido = @actor;
--         END

--         -- Obtener la siguiente fila del cursor
--         FETCH NEXT FROM elenco_cursor INTO @show_id, @actor;
--     END

--     -- Cerrar y liberar el cursor
--     CLOSE elenco_cursor;
--     DEALLOCATE elenco_cursor;
-- END;
-- Fin del procedimiento

-- Ejecutamos el procedimento almacenado 
EXEC InsertarElenco;
GO

-- Comprobamos que se haya desestructurado correctamente 
SELECT * FROM elenco;
GO

------------------------------------------------------------------------------------------------------

-- Funciones AUXILIARES 
-- DELETE FROM Show;
-- SELECT * FROM actor
-- CHECK DUPLICATE DATE:
    -- SELECT [description] , COUNT(*)
    -- FROM dbo.netflix_titles
    -- GROUP BY [description]
    -- HAVING COUNT(*) > 1;

    -- SELECT descripcion , COUNT(*)
    -- FROM Show
    -- GROUP BY descripcion
    -- HAVING COUNT(*) > 1;