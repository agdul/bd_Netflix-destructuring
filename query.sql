USE netflix_bd;


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
JOIN 
    tipo_show ts ON s.id_tipo = ts.id_tipo
JOIN 
    show_director sd ON s.id_show = sd.id_show
JOIN 
    director d ON sd.id_director = d.id_director
JOIN 
    elenco e ON s.id_show = e.id_show
JOIN 
    actor a ON e.id_actor = a.id_actor
JOIN 
    show_pais sp ON s.id_show = sp.id_show
JOIN 
    pais p ON sp.id_pais = p.id_pais
JOIN 
    rating r ON s.id_rating = r.id_rating
JOIN 
    show_categoria sc ON s.id_show = sc.id_show
JOIN 
    categoria c ON sc.id_categoria = c.id_categoria
GROUP BY 
    s.id_show, ts.descripcion, s.titulo, d.nombre_apellido, p.descripcion, 
    s.fecha_salida, s.año_lanzamiento, r.descripcion, s.duracion, c.descripcion, s.descripcion;
