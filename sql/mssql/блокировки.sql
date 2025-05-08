-- Использование системного представления sys.dm_tran_locks
SELECT resource_type,        -- Тип ресурса (например, OBJECT, PAGE, ROW)
       resource_database_id, -- ID базы данных
       resource_description, -- Описание ресурса
       request_mode,         -- Режим блокировки (например, S, X, U)
       request_status,       -- Статус запроса (например, GRANT, WAIT)
       request_session_id    -- ID сессии, которая запрашивает блокировку
FROM sys.dm_tran_locks;


-- Определение блокирующих сессий с помощью sys.dm_exec_requests
SELECT session_id,          -- ID сессии
       blocking_session_id, -- ID сессии, которая блокирует текущую
       wait_type,           -- Тип ожидания
       wait_time,           -- Время ожидания (в миллисекундах)
       command,             -- Тип выполняемой команды
       sql_handle           -- Идентификатор SQL-запроса
FROM sys.dm_exec_requests
-- Только блокирующие сессии
WHERE blocking_session_id > 0;


-- Получение текста SQL-запроса для блокирующей сессии
SELECT r.session_id,
       r.blocking_session_id,
       t.text AS sql_text
FROM sys.dm_exec_requests r
         CROSS APPLY
     sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id > 0;


-- Использование системных представлений
SELECT t1.resource_type,
       t1.resource_database_id,
       t1.resource_associated_entity_id,
       t1.request_mode,
       t1.request_session_id,
       t2.blocking_session_id,
       t2.wait_type,
       t2.wait_duration_ms AS wait_time,
       t2.resource_description AS wait_resource
FROM sys.dm_tran_locks t1
         INNER JOIN sys.dm_os_waiting_tasks t2
                    ON t1.lock_owner_address = t2.resource_address;


-- Использование динамического административного представления
SELECT t1.resource_type,
       t1.request_session_id,
       t2.blocking_session_id,
       t2.wait_type,
       t2.wait_duration_ms AS wait_time,
       t2.resource_description AS wait_resource,
       sqltext.text AS sql_text
FROM sys.dm_tran_locks t1
         INNER JOIN sys.dm_os_waiting_tasks t2
                    ON t1.lock_owner_address = t2.resource_address
         INNER JOIN sys.dm_exec_requests r
                    ON t2.session_id = r.session_id
         CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS sqltext;
