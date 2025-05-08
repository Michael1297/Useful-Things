-- =============================================
-- МОНИТОРИНГ И ДИАГНОСТИКА
-- =============================================

-- Активные подключения
SELECT session_id,
       login_name,
       host_name,
       program_name,
       status,
       cpu_time,
       memory_usage,
       reads,
       writes,
       logical_reads,
       open_transaction_count,
       last_request_start_time
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
ORDER BY cpu_time DESC;

-- Долгие выполняющиеся запросы
SELECT session_id,
       blocking_session_id,
       wait_time,
       wait_type,
       wait_resource,
       transaction_isolation_level,
       lock_timeout,
       TEXT AS query_text
FROM sys.dm_exec_requests
         CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE session_id > 50
ORDER BY wait_time DESC;

-- Размеры таблиц
SELECT t.NAME                                                           AS TableName,
       s.Name                                                           AS SchemaName,
       p.rows                                                           AS RowCounts,
       FORMAT(SUM(a.total_pages) * 8 / 1024.0, 'N2')                    AS TotalSpaceMB, -- Конвертация в мегабайты
       CAST(SUM(a.total_pages) * 8 / 1024.0 / 1024.0 AS DECIMAL(10, 2)) AS TotalSpaceGB  -- Дополнительно в гигабайтах
FROM sys.tables t
         INNER JOIN
     sys.indexes i ON t.OBJECT_ID = i.object_id
         INNER JOIN
     sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
         INNER JOIN
     sys.allocation_units a ON p.partition_id = a.container_id
         LEFT OUTER JOIN
     sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0 -- Исключаем системные таблицы
GROUP BY t.Name, s.Name, p.Rows
ORDER BY (SUM(a.total_pages) * 8 / 1024.0) DESC;

-- =============================================
-- ОПТИМИЗАЦИЯ
-- =============================================

-- Неиспользуемые индексы
SELECT OBJECT_NAME(i.OBJECT_ID)               AS TableName,
       i.name                                 AS IndexName,
       i.type_desc                            AS IndexType,
       user_updates                           AS WritesToIndex,
       user_seeks + user_scans + user_lookups AS ReadsFromIndex
FROM sys.dm_db_index_usage_stats us
         INNER JOIN
     sys.indexes i ON us.OBJECT_ID = i.OBJECT_ID AND us.index_id = i.index_id
WHERE database_id = DB_ID()
  AND OBJECTPROPERTY(us.OBJECT_ID, 'IsUserTable') = 1
  AND user_seeks + user_scans + user_lookups = 0
ORDER BY user_updates DESC;

-- Статистика по фрагментации индексов
SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName,
       ind.name                   AS IndexName,
       indexstats.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
         INNER JOIN
     sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 30
ORDER BY indexstats.avg_fragmentation_in_percent DESC;

-- =============================================
-- БЛОКИРОВКИ
-- =============================================

-- Текущие блокировки
SELECT DB_NAME(tl.resource_database_id) AS database_name,
       tl.resource_type,
       CASE
           WHEN tl.resource_type = 'OBJECT' THEN OBJECT_NAME(tl.resource_associated_entity_id)
           WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN
               OBJECT_NAME(p.object_id)
           ELSE CAST(tl.resource_associated_entity_id AS VARCHAR)
           END                          AS object_name,
       tl.request_mode,
       tl.request_session_id,
       wt.blocking_session_id,
       wt.wait_duration_ms / 1000.0     AS wait_time_seconds,
       wt.wait_type,
       es.host_name,
       es.program_name,
       es.login_name,
       er.blocking_session_id,
       CASE
           WHEN er.sql_handle IS NULL THEN NULL
           ELSE (SELECT text FROM sys.dm_exec_sql_text(er.sql_handle))
           END                          AS query_text
FROM sys.dm_tran_locks tl
         INNER JOIN
     sys.dm_os_waiting_tasks wt ON tl.lock_owner_address = wt.resource_address
         LEFT JOIN
     sys.partitions p ON p.hobt_id = tl.resource_associated_entity_id
         LEFT JOIN
     sys.dm_exec_sessions es ON wt.blocking_session_id = es.session_id
         LEFT JOIN
     sys.dm_exec_requests er ON wt.blocking_session_id = er.session_id
WHERE tl.resource_database_id = DB_ID()
ORDER BY wt.wait_duration_ms DESC;

-- Упрощенная версия (если предыдущая не работает)
SELECT DB_NAME(tl.resource_database_id) AS database_name,
       tl.resource_type,
       tl.request_mode,
       tl.request_session_id            AS waiting_session_id,
       wt.blocking_session_id,
       wt.wait_duration_ms / 1000.0     AS wait_time_seconds,
       wt.wait_type,
       es.host_name,
       es.program_name,
       es.login_name
FROM sys.dm_tran_locks tl
         INNER JOIN
     sys.dm_os_waiting_tasks wt ON tl.lock_owner_address = wt.resource_address
         LEFT JOIN
     sys.dm_exec_sessions es ON wt.blocking_session_id = es.session_id
WHERE tl.resource_database_id = DB_ID()
ORDER BY wt.wait_duration_ms DESC;

-- =============================================
-- АНАЛИЗ ПРОИЗВОДИТЕЛЬНОСТИ
-- =============================================

-- Самые ресурсоемкие запросы (из кэша)
SELECT TOP 20 qs.execution_count,
              qs.total_logical_reads / qs.execution_count                AS avg_logical_reads,
              qs.total_elapsed_time / qs.execution_count                 AS avg_elapsed_time,
              qs.total_worker_time / qs.execution_count                  AS avg_cpu_time,
              SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1,
                        ((CASE qs.statement_end_offset
                              WHEN -1 THEN DATALENGTH(qt.text)
                              ELSE qs.statement_end_offset
                              END - qs.statement_start_offset) / 2) + 1) AS query_text,
              qt.dbid,
              qt.objectid
FROM sys.dm_exec_query_stats qs
         CROSS APPLY
     sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.total_logical_reads DESC;

-- =============================================
-- УПРАВЛЕНИЕ ПАМЯТЬЮ
-- =============================================

-- Использование памяти
SELECT total_physical_memory_kb / 1024.0     AS total_physical_memory_gb,
       available_physical_memory_kb / 1024.0 AS available_physical_memory_gb,
       total_page_file_kb / 1024.0           AS total_page_file_gb,
       available_page_file_kb / 1024.0       AS available_page_file_gb,
       system_memory_state_desc
FROM sys.dm_os_sys_memory;


-- Кэшированные объекты
SELECT TOP 20 COUNT(*) AS cached_pages_count,
              obj.name AS object_name,
              obj.type_desc
FROM sys.dm_os_buffer_descriptors bd
         INNER JOIN
     sys.allocation_units au ON bd.allocation_unit_id = au.allocation_unit_id
         INNER JOIN
     sys.partitions p ON au.container_id = p.hobt_id
         INNER JOIN
     sys.objects obj ON p.object_id = obj.object_id
WHERE database_id = DB_ID()
GROUP BY obj.name, obj.type_desc
ORDER BY cached_pages_count DESC;

-- =============================================
-- ОБСЛУЖИВАНИЕ
-- =============================================

-- Обновление статистики для всех таблиц
EXEC sp_updatestats;

-- Проверка целостности БД
DBCC CHECKDB WITH NO_INFOMSGS;

-- Очистка кэша планов
DBCC FREEPROCCACHE;

-- Очистка буферного кэша
DBCC DROPCLEANBUFFERS;