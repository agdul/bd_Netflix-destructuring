------------------------------------------------------------------------------------------------------
-- Comentarios : Antes de ejecutar este scrip es necesario ejecutar antes destructuracionNetflix.sql
-- USE bd_name; GO
------------------------------------------------------------------------------------------------------

-----------------------------------
--- Validaciones de los datos -----
-----------------------------------

-- Cantidad de directores con más de 10 películas o series dirigidas

-- Tabla normalizada 
SELECT d.nombre_apellido, COUNT(sd.id_show) AS cantidad_shows
FROM show_director sd
JOIN director d ON sd.id_director = d.id_director
GROUP BY d.nombre_apellido
HAVING COUNT(sd.id_show) > 10;

-- Tabla madre 
SELECT director, COUNT(*) AS cantidad
FROM netflix_titles
WHERE director IS NOT NULL
GROUP BY director
HAVING COUNT(*) > 10;

------------------------------------------------------------------------------------------------------

-----------------------------------
--- Validaciones de los datos -----
-----------------------------------

-- El actor con mayor participación en películas o series

-- Tabla normalizada 
SELECT TOP 1 a.nombre_apellido AS actor, COUNT(e.id_show) AS participaciones
FROM elenco e
JOIN actor a ON e.id_actor = a.id_actor
GROUP BY a.nombre_apellido
ORDER BY participaciones DESC;

-- Tabla madre 

WITH ActorList AS ( SELECT TRIM(value) AS actor FROM netflix_titles
CROSS APPLY STRING_SPLIT(cast, ',')
)
SELECT TOP 1 actor, COUNT(*) AS cantidad FROM ActorList
GROUP BY actor
ORDER BY cantidad DESC;

------------------------------------------------------------------------------------------------------

-----------------------------------
--- Validaciones de los datos -----
-----------------------------------

--Cantidad de series añadidas en los últimos cinco años

-- Tabla normalizada 
SELECT COUNT(*) AS cantidad_series
FROM Show s
JOIN tipo_show t ON s.id_tipo = t.id_tipo
WHERE t.descripcion = 'TV Show'
AND s.fecha_salida >= DATEADD(YEAR, -5, GETDATE());

--Tabla madre
SELECT COUNT(*) AS cantidad_series
FROM netflix_titles
WHERE type = 'TV Show'
AND date_added >= DATEADD (YEAR, -5, GETDATE());

------------------------------------------------------------------------------------------------------

-- Consulta que representa la tabla madre 
SELECT 
    s.id_show AS show_id,
    ts.descripcion AS type,
    s.titulo AS title,
    d.nombre_apellido AS director,
    STRING_AGG(a.nombre_apellido, ', ') AS cast,
    p.descripcion AS country,
    s.fecha_salida AS date_added,
    s.año_lanzamiento AS release_year,
    r.descripcion AS rating,
    s.duracion AS duration,
    c.descripcion AS listed_in,
    s.descripcion AS description
FROM 
    Show s
LEFT JOIN 
    tipo_show ts ON s.id_tipo = ts.id_tipo
LEFT JOIN 
    show_director sd ON s.id_show = sd.id_show
LEFT JOIN 
    director d ON sd.id_director = d.id_director
LEFT JOIN 
    elenco e ON s.id_show = e.id_show
LEFT JOIN 
    actor a ON e.id_actor = a.id_actor
LEFT JOIN 
    show_pais sp ON s.id_show = sp.id_show
LEFT JOIN 
    pais p ON sp.id_pais = p.id_pais
LEFT JOIN 
    rating r ON s.id_rating = r.id_rating
LEFT JOIN 
    show_categoria sc ON s.id_show = sc.id_show
LEFT JOIN 
    categoria c ON sc.id_categoria = c.id_categoria
GROUP BY 
    s.id_show, ts.descripcion, s.titulo, d.nombre_apellido, p.descripcion, 
    s.fecha_salida, s.año_lanzamiento, r.descripcion, s.duracion, c.descripcion, s.descripcion;
