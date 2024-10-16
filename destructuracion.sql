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

-- Eliminar Duplicados 
WITH CTE AS (
    SELECT 
        id_actor, 
        nombre_apellido,
        ROW_NUMBER() OVER (PARTITION BY nombre_apellido ORDER BY id_actor) AS row_num
    FROM actor
)
DELETE FROM CTE WHERE row_num > 1;
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


GO

------------------------------------------------------------------------------------------------------


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
END;
GO


-- Funciones AUXILIARES 
-- DELETE FROM director;
-- SELECT * FROM actor
-- CHECK DUPLICATE DATE:
    -- SELECT nombre_apellido , COUNT(*)
    -- FROM actor
    -- GROUP BY nombre_apellido
    -- HAVING COUNT(*) > 1;