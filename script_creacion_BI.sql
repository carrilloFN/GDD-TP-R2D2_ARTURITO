USE GD1C2024
GO

/************************************************************************************
 *	CREACION DIMENSIONES BASICAS SEG�N ENUNCIADO
 ************************************************************************************/

CREATE SCHEMA BI_R2D2_ARTURITO
GO

CREATE TABLE BI_R2D2_ARTURITO.BI_TIEMPO(
	id_tiempo INT PRIMARY KEY IDENTITY(0,1),
	anio INT NULL,
	cuatrimestre INT NULL,
	mes INT NULL
);
GO

CREATE TABLE BI_R2D2_ARTURITO.BI_UBICACION(
	id_ubicacion INT PRIMARY KEY IDENTITY(0,1),
	localidad VARCHAR(200) NULL,
	provincia VARCHAR(200) NULL
);
GO

CREATE TABLE BI_R2D2_ARTURITO.BI_SUCURSAL(
	id_sucursal INT PRIMARY KEY IDENTITY(0,1),
	nombre VARCHAR(200) NULL,
	id_ubicacion INT NOT NULL,
	FOREIGN KEY (id_ubicacion) REFERENCES BI_R2D2_ARTURITO.BI_UBICACION (id_ubicacion)
);
GO

CREATE TABLE BI_R2D2_ARTURITO.BI_RANGO_ETARIO(
	id_rango_etario INT PRIMARY KEY IDENTITY(0,1),
	rango_etario VARCHAR(50) NULL
);
GO



CREATE TABLE BI_R2D2_ARTURITO.BI_MEDIO_PAGO(
	id_medio_pago INT PRIMARY KEY IDENTITY(0,1),
	descripcion VARCHAR(50)
);
GO

CREATE TABLE BI_R2D2_ARTURITO.BI_CATEGORIZACION_PRODUCTOS(
	id_categorizacion INT PRIMARY KEY IDENTITY(0,1),
	descripcion_categoria VARCHAR(200) NULL,
	descripcion_subcategoria VARCHAR(200) NULL
);
GO

/************************************************************************************
 *	CREACION TABLAS NECESARIAS PARA VISTAS 1,2,3 y 4
 ************************************************************************************/

 CREATE TABLE BI_R2D2_ARTURITO.BI_TIPO_CAJA(
	id_tipo_caja INT PRIMARY KEY IDENTITY(0,1),
	descripcion VARCHAR(50) NOT NULL
 );
 GO

CREATE TABLE BI_R2D2_ARTURITO.BI_VENTA(
	total_venta DECIMAL(10,2),
	cantidad_items_vendidos INT NULL,
	id_sucursal INT NOT NULL,
	id_tiempo INT NOT NULL,
	id_turno INT NOT NULL,
	id_tipo_caja INT NOT NULL,
	id_rango_etario INT NOT NULL
	FOREIGN KEY (id_sucursal) REFERENCES BI_R2D2_ARTURITO.BI_SUCURSAL(id_sucursal),
	FOREIGN KEY (id_tiempo) REFERENCES BI_R2D2_ARTURITO.BI_TIEMPO(id_tiempo),
	FOREIGN KEY (id_turno) REFERENCES BI_R2D2_ARTURITO.BI_RANGO_TURNOS(id_turno),
	FOREIGN KEY (id_tipo_caja) REFERENCES BI_R2D2_ARTURITO.BI_TIPO_CAJA(id_tipo_caja),
	FOREIGN KEY (id_rango_etario) REFERENCES BI_R2D2_ARTURITO.BI_RANGO_ETARIO(id_rango_etario),
	PRIMARY KEY (id_sucursal,id_tiempo,id_turno,id_tipo_caja,id_rango_etario)
);
GO

/************************************************************************************
 *	MIGRACIONES DE DATOS DE DIMENSIONES OBLIGATORIAS
 ************************************************************************************/

CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_TIEMPO AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_TIEMPO (anio, cuatrimestre, mes)
	SELECT DISTINCT
		YEAR(V.fecha) AS anio,
		CASE
			WHEN MONTH(V.fecha) BETWEEN 1 AND 4 THEN 1
			WHEN MONTH(V.fecha) BETWEEN 5 AND 8 THEN 2
			WHEN MONTH(V.fecha) BETWEEN 9 AND 12 THEN 3
			ELSE NULL
		END AS cuatrimestre,
		MONTH(V.fecha) AS mes
	FROM R2D2_ARTURITO.VENTA V
END
GO

--Ubicacion
CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_UBICACION AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_UBICACION(localidad,provincia)
	SELECT 
		L.nombre AS localidad,
		P.nombre AS provincia
	FROM R2D2_ARTURITO.LOCALIDAD L INNER JOIN R2D2_ARTURITO.PROVINCIA P
		ON L.id_provincia = P.id_provincia
END
GO

--Sucursal
CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_SUCURSAL AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_SUCURSAL(nombre, id_ubicacion)
	SELECT 
		S.nombre AS nombre,
		U.id_ubicacion AS id_ubicacion
	FROM R2D2_ARTURITO.SUCURSAL S
		INNER JOIN R2D2_ARTURITO.DIRECCION D 
			ON S.id_direccion = D.id_direccion
		INNER JOIN R2D2_ARTURITO.LOCALIDAD L
			ON D.id_localidad = L.id_localidad
		INNER JOIN R2D2_ARTURITO.PROVINCIA P
			ON L.id_provincia = P.id_provincia
		INNER JOIN BI_R2D2_ARTURITO.BI_UBICACION U
			ON L.nombre = U.localidad
			AND P.nombre = U.provincia
END
GO

--Rango Etario
CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_RANGO_ETARIO AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_RANGO_ETARIO (rango_etario)
		VALUES ('< 25'), ('25 - 35'), ('35 - 50'), ('> 50')
END
GO

--Turnos
CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_RANGO_TURNOS AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_RANGO_TURNOS(inicio,fin) 
		VALUES ('08:00','12:00'), ('12:00','16:00'), ('16:00','20:00')
END
GO

CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_TIPO_CAJA AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_TIPO_CAJA (descripcion)
	SELECT DISTINCT TC.descripcion
	FROM R2D2_ARTURITO.TIPO_CAJA AS TC
	WHERE TC.id_tipo_caja IS NOT NULL
END
GO

CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_MEDIO_PAGO AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_MEDIO_PAGO(descripcion)
	SELECT MP.descripcion FROM R2D2_ARTURITO.MEDIO_PAGO MP
END
GO

CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_CATEGORIZACION_PRODUCTOS AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_CATEGORIZACION_PRODUCTOS(descripcion_categoria,descripcion_subcategoria)
	SELECT
		C.descripcion AS descripcion_categoria,
		S.descripcion AS descripcion_subcategoria
	FROM R2D2_ARTURITO.SUBCATEGORIA S
		INNER JOIN R2D2_ARTURITO.SUBCATEGORIA_X_CATEGORIA SXC
			ON S.id_subcategoria = SXC.id_subcategoria
		INNER JOIN R2D2_ARTURITO.CATEGORIA C
			ON SXC.id_categoria = C.id_categoria
END
GO

CREATE PROCEDURE BI_R2D2_ARTURITO.BI_MIGRAR_VENTAS AS
BEGIN
	INSERT INTO BI_R2D2_ARTURITO.BI_VENTA(
		id_sucursal,
		id_tiempo,
		id_turno,
		id_tipo_caja,
		total_items_vendidos,
		total_venta)
	SELECT 
	FROM R2D2_ARTURITO.VENTA V
		INNER JOIN BI_R2D2_ARTURITO.BI_SUCURSAL S
			
END
GO

/************************************************************************************
 *	VISTA 1:
 * Ticket Promedio mensual. Valor promedio de las ventas (en $) seg�n la
 * localidad, a�o y mes. Se calcula en funci�n de la sumatoria del importe de las
 * ventas sobre el total de las mismas.
 ************************************************************************************/

 CREATE VIEW BI_R2D2_ARTURITO.TICKET_PROMEDIO_MENSUAL AS
	SELECT
	FROM BI_R2D2_ARTURITO.BI_UBICACION
 GO

EXEC BI_R2D2_ARTURITO.BI_MIGRAR_TIEMPO;
EXEC BI_R2D2_ARTURITO.BI_MIGRAR_UBICACION;
EXEC BI_R2D2_ARTURITO.BI_MIGRAR_SUCURSAL;
EXEC BI_R2D2_ARTURITO.BI_MIGRAR_RANGO_ETARIO;
EXEC BI_R2D2_ARTURITO.BI_MIGRAR_RANGO_TURNOS;
EXEC BI_R2D2_ARTURITO.BI_MIGRAR_MEDIO_PAGO;
EXEC BI_R2D2_ARTURITO.BI_MIGRAR_CATEGORIZACION_PRODUCTOS;