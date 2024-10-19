USE netflix_bd2;


-- Cantidad de directores con más de 10 películas o series dirigidas
SELECT COUNT(*) AS cantidad_directores
FROM (
    SELECT id_director, COUNT(id_show) AS cantidad_shows
    FROM show_director
    GROUP BY id_director
    HAVING COUNT(id_show) > 10
) AS directores_con_mas_de_10;


-- El actor con mayor participación en películas o series

SELECT TOP 1 a.nombre_apellido, COUNT(e.id_show) AS participaciones
FROM elenco e
JOIN actor a ON e.id_actor = a.id_actor
GROUP BY a.nombre_apellido
ORDER BY participaciones DESC;


--Cantidad de series añadidas en los últimos cinco años
SELECT COUNT(*) AS cantidad_series
FROM Show s
JOIN tipo_show t ON s.id_tipo = t.id_tipo
WHERE t.descripcion = 'Series' AND s.fecha_salida >= DATEADD(YEAR, -5, GETDATE());




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
