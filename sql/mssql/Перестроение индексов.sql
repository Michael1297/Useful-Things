-- 1. Получение списка индексов для проверки
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.index_id
FROM sys.indexes i
WHERE i.type_desc IN ('CLUSTERED', 'NONCLUSTERED')
AND i.is_disabled = 0;


-- 2. Определение степени фрагментации индексов
DECLARE @DatabaseName NVARCHAR(128) = N'ELARContext';

SELECT
    DB_NAME(database_id) AS DatabaseName,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    index_type_desc,
    avg_fragmentation_in_percent,
    fragment_count,
    page_count
FROM sys.dm_db_index_physical_stats(DB_ID(@DatabaseName), NULL, NULL, NULL, 'DETAILED') s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
where avg_fragmentation_in_percent > 30 and i.name is not NULL
ORDER BY avg_fragmentation_in_percent DESC;

-- 3. Реорганизация индексов (при фрагментации 10-30%)
ALTER INDEX IndexName ON TableName REORGANIZE;

-- 4. Перестройка индексов (при фрагментации более 30%)
ALTER INDEX IndexName ON TableName REBUILD;
-- Если доступен Online Rebuild:
ALTER INDEX IndexName ON TableName REBUILD WITH (ONLINE = ON);





-- Перестроение индексов для всех таблиц в определенной БД
DECLARE @DatabaseName NVARCHAR(128) = N'ELARContext';
DECLARE @IndexName SYSNAME;
DECLARE @TableName SYSNAME;
DECLARE @SchemaName SYSNAME;
DECLARE @SQL NVARCHAR(MAX);

-- Временная таблица для хранения результатов
CREATE TABLE #FragmentedIndexes (
    ObjectID INT,
    IndexID INT,
    SchemaName SYSNAME,
    TableName SYSNAME,
    IndexName SYSNAME,
    Fragmentation DECIMAL(5, 2),
    PageCount BIGINT
);

-- Заполнение временной таблицы данными о фрагментированных индексах
INSERT INTO #FragmentedIndexes (ObjectID, IndexID, SchemaName, TableName, IndexName, Fragmentation, PageCount)
SELECT
    s.object_id,
    s.index_id,
    SCHEMA_NAME(o.schema_id),
    OBJECT_NAME(s.object_id),
    i.name,
    s.avg_fragmentation_in_percent,
    s.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(@DatabaseName), NULL, NULL, NULL, 'DETAILED') s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
JOIN sys.objects o ON s.object_id = o.object_id
WHERE s.avg_fragmentation_in_percent > 30
AND i.name IS NOT NULL;

-- Цикл по всем записям во временной таблице
WHILE EXISTS (SELECT * FROM #FragmentedIndexes)
BEGIN
    -- Выбираем первую запись
    SELECT TOP 1
        @IndexName = IndexName,
        @TableName = TableName,
        @SchemaName = SchemaName
    FROM #FragmentedIndexes;

    -- Формируем команду перестроения индекса
    SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' REBUILD WITH (ONLINE = ON);';

    -- Выполняем команду перестроения
    PRINT @SQL; -- Для отладки, можно закомментировать эту строку
    EXEC sp_executesql @SQL;

    -- Удаляем обработанный индекс из временной таблицы
    DELETE FROM #FragmentedIndexes WHERE IndexName = @IndexName AND TableName = @TableName;
END

-- Очистка временных объектов
DROP TABLE #FragmentedIndexes;