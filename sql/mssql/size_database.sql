SELECT
    DB_NAME(database_id) AS DatabaseName,
    CAST((SUM(size)*8.0)/1024/ 1024 AS DECIMAL(18,2)) AS SizeInGB
FROM sys.master_files
GROUP BY database_id
ORDER BY SUM(size) DESC;


SELECT
    t.NAME AS TableName,
    s.Name AS SchemaName,
    SUM(p.rows) AS RowCounts,
    CAST(SUM(a.total_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS TotalSpaceGB, -- Размер в ГБ
    CAST(SUM(a.used_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS UsedSpaceGB,   -- Используемое пространство в ГБ
    CAST((SUM(a.total_pages) - SUM(a.used_pages)) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS UnusedSpaceGB -- Неиспользуемое пространство в ГБ
FROM
    sys.tables t
        INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
        INNER JOIN
    sys.indexes i ON t.object_id = i.object_id
        INNER JOIN
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
        INNER JOIN
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE
    t.is_ms_shipped = 0 -- Исключаем системные таблицы
GROUP BY
    t.Name, s.Name
ORDER BY
    TotalSpaceGB DESC; -- Сортировка по занимаемому месту (от большего к меньшему)



-- Информация о файлах базы данных
SELECT
    name AS FileName,
    type_desc AS FileType,
    size * 8 / 1024 AS SizeMB, -- Размер файла в МБ
    FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024 AS UsedSpaceMB, -- Используемое пространство в МБ
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8 / 1024 AS FreeSpaceMB -- Свободное пространство в МБ
FROM
    sys.database_files;


-- Сжатие файла данных
DBCC SHRINKFILE (N'DataMart', 28481);