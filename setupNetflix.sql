-- SELECT * FROM dbo.netflix_titles;

CREATE TABLE actor
(
  id_actor INT IDENTITY(1, 1),
  nombre_apellido VARCHAR(150) NOT NULL,
  CONSTRAINT PK_id_actor PRIMARY KEY (id_actor)
);

CREATE TABLE tipo_show
(
  id_tipo INT IDENTITY(1, 1),
  descripcion VARCHAR(100) NOT NULL,
  CONSTRAINT PK_id_tipo PRIMARY KEY (id_tipo)
);

CREATE TABLE pais
(
  id_pais INT IDENTITY(1, 1),
  descripcion VARCHAR(100) NOT NULL,
  CONSTRAINT PK_id_pais PRIMARY KEY (id_pais)
);

CREATE TABLE director
(
  id_director INT IDENTITY(1, 1),
  nombre_apellido VARCHAR(300) NOT NULL,
  CONSTRAINT PK_id_director PRIMARY KEY (id_director)
);

CREATE TABLE rating
(
  id_rating INT IDENTITY(1, 1),
  descripcion VARCHAR(50) NOT NULL,
  CONSTRAINT PK_id_rating PRIMARY KEY (id_rating)
);

CREATE TABLE categoria
(
  id_categoria INT IDENTITY(1, 1),
  descripcion VARCHAR(100) NOT NULL,
  CONSTRAINT PK_id_categoria PRIMARY KEY (id_categoria)
);

CREATE TABLE Show
(
  id_show VARCHAR(25) NOT NULL,
  titulo VARCHAR(200) NOT NULL,
  fecha_salida date,
  duracion VARCHAR(50),
  año_lanzamiento smallint NOT NULL,
  descripcion VARCHAR(1000) NOT NULL,
  id_tipo INT NOT NULL,
  id_rating INT,
  CONSTRAINT PK_id_show PRIMARY KEY (id_show),
  CONSTRAINT FK_show_id_tipo FOREIGN KEY (id_tipo) REFERENCES tipo_show(id_tipo),
  CONSTRAINT FK_show_id_rating FOREIGN KEY (id_rating) REFERENCES rating(id_rating)
);

CREATE TABLE show_director
(
  id_director INT,
  id_show VARCHAR(25),
  CONSTRAINT PK_id_show_director PRIMARY KEY (id_director, id_show),
  CONSTRAINT FK_show_director_id_director FOREIGN KEY (id_director) REFERENCES director(id_director),
  CONSTRAINT FK_show_director_id_show FOREIGN KEY (id_show) REFERENCES Show(id_show)
);

CREATE TABLE show_pais
(
  id_pais INT,
  id_show VARCHAR(25),
  CONSTRAINT PK_id_show_pais PRIMARY KEY (id_pais, id_show),
  CONSTRAINT FK_show_pais_id_pais FOREIGN KEY (id_pais) REFERENCES pais(id_pais),
  CONSTRAINT FK_show_pais_id_show FOREIGN KEY (id_show) REFERENCES Show(id_show)
);

CREATE TABLE show_categoria
(
  id_show VARCHAR(25) NOT NULL,
  id_categoria INT NOT NULL,
  CONSTRAINT PK_id_show_categoria PRIMARY KEY (id_show, id_categoria),
  CONSTRAINT FK_show_categoria_id_show FOREIGN KEY (id_show) REFERENCES Show(id_show),
  CONSTRAINT FK_show_categoria_id_categoria FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

CREATE TABLE elenco
(
  id_actor INT,
  id_show VARCHAR(25),
  CONSTRAINT PK_id_elenco PRIMARY KEY (id_actor, id_show),
  CONSTRAINT FK_elenco_id_actor FOREIGN KEY (id_actor) REFERENCES actor(id_actor),
  CONSTRAINT FK_elenco_id_show FOREIGN KEY (id_show) REFERENCES Show(id_show)
);







