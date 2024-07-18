USE GD1C2024
GO

DECLARE @schemaName NVARCHAR(128) = 'R2D2_ARTURITO'
DECLARE @objectName NVARCHAR(128)
DECLARE @objectType NVARCHAR(128)
DECLARE @sql NVARCHAR(MAX)
DECLARE @tableName NVARCHAR(128)
DECLARE @constraintName NVARCHAR(128)

-- Eliminar todos los FOREIGN KEY constraints del esquema especificado
DECLARE fk_cursor CURSOR FOR
SELECT table_name, constraint_name
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE constraint_type = 'FOREIGN KEY' AND table_schema = @schemaName
OPEN fk_cursor
FETCH NEXT FROM fk_cursor INTO @tableName, @constraintName
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER TABLE ' + @schemaName + '.' + @tableName + ' DROP CONSTRAINT ' + @constraintName
    EXEC sp_executesql @sql
    FETCH NEXT FROM fk_cursor INTO @tableName, @constraintName
END
CLOSE fk_cursor
DEALLOCATE fk_cursor

-- Eliminar todos los PRIMARY KEY, UNIQUE y CHECK constraints del esquema especificado
DECLARE pk_uc_ck_cursor CURSOR FOR
SELECT table_name, constraint_name
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE constraint_type IN ('PRIMARY KEY', 'UNIQUE', 'CHECK') AND table_schema = @schemaName
OPEN pk_uc_ck_cursor
FETCH NEXT FROM pk_uc_ck_cursor INTO @tableName, @constraintName
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER TABLE ' + @schemaName + '.' + @tableName + ' DROP CONSTRAINT ' + @constraintName
    EXEC sp_executesql @sql
    FETCH NEXT FROM pk_uc_ck_cursor INTO @tableName, @constraintName
END
CLOSE pk_uc_ck_cursor
DEALLOCATE pk_uc_ck_cursor

-- Eliminar todas las tablas del esquema especificado
DECLARE table_cursor CURSOR FOR
SELECT table_name
FROM INFORMATION_SCHEMA.TABLES
WHERE table_schema = @schemaName AND table_type = 'BASE TABLE'
OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @tableName
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'DROP TABLE ' + @schemaName + '.' + @tableName
    EXEC sp_executesql @sql
    FETCH NEXT FROM table_cursor INTO @tableName
END
CLOSE table_cursor
DEALLOCATE table_cursor

-- Eliminar todos los objetos del esquema especificado
DECLARE object_cursor CURSOR FOR
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID(@schemaName)

OPEN object_cursor
FETCH NEXT FROM object_cursor INTO @objectName, @objectType
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Determinar el tipo de objeto y construir la instrucción DROP apropiada
    SET @sql = 
        CASE 
            WHEN @objectType = 'SQL_TABLE' THEN 'DROP TABLE [' + @schemaName + '].[' + @objectName + ']'
            WHEN @objectType = 'SQL_VIEW' THEN 'DROP VIEW [' + @schemaName + '].[' + @objectName + ']'
            WHEN @objectType = 'SQL_STORED_PROCEDURE' THEN 'DROP PROCEDURE [' + @schemaName + '].[' + @objectName + ']'
            WHEN @objectType = 'SQL_SCALAR_FUNCTION' THEN 'DROP FUNCTION [' + @schemaName + '].[' + @objectName + ']'
            WHEN @objectType = 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 'DROP FUNCTION [' + @schemaName + '].[' + @objectName + ']'
            WHEN @objectType = 'SQL_TABLE_VALUED_FUNCTION' THEN 'DROP FUNCTION [' + @schemaName + '].[' + @objectName + ']'
            ELSE 'UNKNOWN'
        END

    -- Ejecutar la instrucción DROP si no es desconocido
    IF @sql <> 'UNKNOWN'
    BEGIN
        EXEC sp_executesql @sql
    END

    FETCH NEXT FROM object_cursor INTO @objectName, @objectType
END
CLOSE object_cursor
DEALLOCATE object_cursor

-- Eliminar todos los tipos de datos definidos por el usuario en el esquema especificado
DECLARE type_cursor CURSOR FOR
SELECT name
FROM sys.types
WHERE schema_id = SCHEMA_ID(@schemaName) AND is_user_defined = 1

OPEN type_cursor
FETCH NEXT FROM type_cursor INTO @objectName
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Construir y ejecutar la instrucción para eliminar el tipo de datos
    SET @sql = 'DROP TYPE [' + @schemaName + '].[' + @objectName + ']'
    EXEC sp_executesql @sql
    FETCH NEXT FROM type_cursor INTO @objectName
END
CLOSE type_cursor
DEALLOCATE type_cursor

-- Eliminar el esquema
SET @sql = 'DROP SCHEMA [' + @schemaName + ']'
EXEC sp_executesql @sql