CREATE DATABASE biblioteca2;
GO

USE biblioteca2;
GO

CREATE TABLE libro (
    libro_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(70) NOT NULL,
    genero VARCHAR(30) NOT NULL,
    autor VARCHAR(50) NOT NULL,
    editorial VARCHAR(30) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0)
);

CREATE TABLE genero_libro (
    genero_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_genero VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);

CREATE TABLE editorial (
    editorial_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_editorial VARCHAR(50) NOT NULL UNIQUE
);
GO

ALTER TABLE libro ADD genero_id INT NOT NULL;
ALTER TABLE libro ADD CONSTRAINT FK_genero FOREIGN KEY (genero_id) REFERENCES genero_libro(genero_id);

ALTER TABLE libro DROP COLUMN genero;
ALTER TABLE libro ADD editorial_id INT;

ALTER TABLE libro ADD CONSTRAINT FK_editorial FOREIGN KEY (editorial_id) REFERENCES editorial(editorial_id);

ALTER TABLE libro DROP COLUMN editorial;

ALTER TABLE libro ADD CONSTRAINT nombre_autor_editorial_unicos UNIQUE (nombre, autor, editorial_id);
GO


CREATE TABLE usuario (
    usuario_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    documento VARCHAR(30) NOT NULL UNIQUE,
    telefono VARCHAR(30),
    correo VARCHAR(40) NOT NULL
);

ALTER TABLE usuario
ADD CONSTRAINT formato_correo CHECK (correo LIKE '%@%.%');
GO

CREATE TABLE reserva (
    reserva_id INT IDENTITY(1,1) PRIMARY KEY,
    tipo_reserva VARCHAR(20) NOT NULL,
    fecha_prestamo DATE NOT NULL DEFAULT GETDATE(),
    fecha_devolucion DATE NOT NULL,
    usuario_id INT NOT NULL FOREIGN KEY REFERENCES usuario(usuario_id),
    libro_id INT NOT NULL FOREIGN KEY REFERENCES libro(libro_id)
);

ALTER TABLE reserva
ADD CONSTRAINT Check_fechas CHECK (fecha_prestamo <= fecha_devolucion);

ALTER TABLE reserva
ADD CONSTRAINT chk_tipo_reserva CHECK (tipo_reserva IN ('En sala','Domicilio'));

CREATE TABLE renovacion (
    renovacion_id INT IDENTITY(1,1) PRIMARY KEY,
    reserva_id INT NOT NULL FOREIGN KEY REFERENCES reserva(reserva_id),
    fecha_renovacion DATE NOT NULL
);

ALTER TABLE renovacion
ADD CONSTRAINT chk_fecha_renovacion CHECK (fecha_renovacion >= GETDATE());
GO

-- Géneros
INSERT INTO genero_libro (nombre_genero, descripcion) VALUES
('Ciencia Ficción', 'Relatos imaginarios basados en avances científicos y tecnológicos.'),
('Fantasía', 'Narraciones con elementos sobrenaturales y mundos mágicos.'),
('Misterio', 'Historias centradas en la resolución de un crimen o un enigma.'),
('Novela Histórica', 'Ficción ambientada en un período histórico real.'),
('Terror', 'Relatos que buscan provocar miedo o suspenso.'),
('Romance', 'Historias centradas en relaciones amorosas.'),
('Aventura', 'Narraciones que implican viajes y acción.'),
('Biografía', 'Relato de la vida de una persona.'),
('Ensayo', 'Texto que analiza un tema.'),
('Distopía', 'Sociedades ficticias indeseables.');

-- Editoriales
INSERT INTO editorial (nombre_editorial) VALUES
('Acantilado'),
('Minotauro'),
('Planeta'),
('Alianza Editorial'),
('DEBOLSILLO'),
('Penguin Clásicos'),
('Anaya'),
('DEBATE');

-- Libros
INSERT INTO libro (nombre, autor, stock, genero_id, editorial_id) VALUES
('Duna', 'Frank Herbert', 15, 1, 1),
('El Señor de los Anillos', 'J.R.R. Tolkien', 12, 2, 2),
('Asesinato en el Orient Express', 'Agatha Christie', 20, 3, 3),
('Yo, Claudio', 'Robert Graves', 8, 4, 4),
('It (Eso)', 'Stephen King', 18, 5, 5),
('Orgullo y Prejuicio', 'Jane Austen', 25, 6, 6),
('La Isla del Tesoro', 'Robert Louis Stevenson', 30, 7, 7),
('Steve Jobs', 'Walter Isaacson', 10, 8, 8),
('Sapiens: De animales a dioses', 'Yuval Noah Harari', 5, 9, 8),
('1984', 'George Orwell', 22, 10, 5);

-- Usuarios
INSERT INTO usuario (nombre, documento, telefono, correo) VALUES
('Ana Pérez', '1035448710', '3101234567', 'ana.perez@email.com'),
('Luis García', '71789456', '3207654321', 'luis.garcia@email.com'),
('Sofía Rodríguez', '1039876543', '3159876543', 'sofia.r@email.com'),
('Carlos Martínez', '80123987', '3005551234', 'carlos.m@email.com'),
('Lucía Hernandez', '1045678901', '3123456789', 'lucia.h@email.com');
GO



CREATE PROCEDURE libros_bajo_stock
    @minimo INT
AS
BEGIN
    SELECT nombre, autor, stock
    FROM libro
    WHERE stock < @minimo;
END;
GO


CREATE PROCEDURE reservas_por_documento
    @documento VARCHAR(30)
AS
BEGIN
    SELECT  
        r.reserva_id,
        u.nombre AS nombre_usuario,
        u.documento,
        l.nombre AS nombre_libro,
        l.autor,
        r.tipo_reserva,
        r.fecha_prestamo,
        r.fecha_devolucion
    FROM reserva r
    INNER JOIN usuario u ON r.usuario_id = u.usuario_id
    INNER JOIN libro l ON r.libro_id = l.libro_id
    WHERE u.documento = @documento;
END;
GO


CREATE PROCEDURE usp_BuscarLibroPorGenero
    @GeneroABuscar VARCHAR(70)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        l.libro_id,
        l.nombre AS nombre_libro,
        g.nombre_genero,
        g.descripcion
    FROM libro l
    INNER JOIN genero_libro g 
        ON l.genero_id = g.genero_id
    WHERE g.nombre_genero = @GeneroABuscar;
END;
GO


CREATE PROCEDURE registrar_usuario
    @nombre VARCHAR(30),
    @documento VARCHAR(30),
    @telefono VARCHAR(30),
    @correo VARCHAR(40),
    @nuevo_usuario_id INT OUTPUT,
    @mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM usuario WHERE correo = @correo)
        BEGIN
            SET @mensaje = 'El correo ya está registrado.';
            SET @nuevo_usuario_id = NULL;
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        INSERT INTO usuario (nombre, documento, telefono, correo)
        VALUES (@nombre, @documento, @telefono, @correo);

        SET @nuevo_usuario_id = SCOPE_IDENTITY();
        SET @mensaje = 'Usuario registrado correctamente.';
        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @mensaje = 'Error al registrar el usuario: ' + ERROR_MESSAGE();
        SET @nuevo_usuario_id = NULL;
    END CATCH
END;
GO
