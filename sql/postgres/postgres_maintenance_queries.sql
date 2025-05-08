-- =============================================
-- МОНИТОРИНГ И ДИАГНОСТИКА
-- =============================================

-- Активные подключения
SELECT pid, usename, application_name, client_addr, state, query_start, query
FROM pg_stat_activity
WHERE state = 'active';

-- Долгие запросы
SELECT pid, now() - query_start as duration, query, state
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - query_start > interval '5 minutes';

-- Размеры таблиц
SELECT table_schema,
       table_name,
       pg_size_pretty(pg_total_relation_size('"' || table_schema || '"."' || table_name || '"')) as size
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size('"' || table_schema || '"."' || table_name || '"') DESC;

-- Индексная статистика
SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes;

-- =============================================
-- ОПТИМИЗАЦИЯ
-- =============================================

-- Неиспользуемые индексы
SELECT schemaname, relname, indexrelname
FROM pg_stat_user_indexes
WHERE idx_scan = 0;

-- Таблицы, нуждающиеся в vacuum
SELECT schemaname,
       relname,
       n_live_tup,
       n_dead_tup,
       round(n_dead_tup::numeric / n_live_tup::numeric * 100, 2) as dead_ratio
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY dead_ratio DESC;

-- Проверка autovacuum
SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables;

-- =============================================
-- БЛОКИРОВКИ
-- =============================================

-- Текущие блокировки
SELECT blocked_locks.pid       AS blocked_pid,
       blocking_locks.pid      AS blocking_pid,
       blocked_activity.query  AS blocked_query,
       blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
         JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
         JOIN pg_catalog.pg_locks blocking_locks
              ON blocking_locks.locktype = blocked_locks.locktype
                  AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
                  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
                  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
                  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
                  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
                  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
                  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
                  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
                  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
                  AND blocking_locks.pid != blocked_locks.pid
         JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;

-- =============================================
-- АНАЛИЗ ПРОИЗВОДИТЕЛЬНОСТИ
-- =============================================

-- Самые долгие активные запросы
SELECT pid,
       now() - query_start AS duration,
       query,
       usename,
       application_name,
       client_addr
FROM pg_stat_activity
WHERE state = 'active'
  AND query != ''
  AND query NOT LIKE '%pg_stat_activity%'
ORDER BY duration DESC
LIMIT 20;

-- Часто выполняемые шаблоны запросов
SELECT regexp_replace(query, '(VALUES ?\([^)]+\)|\?|\$[0-9]+)', '...', 'g') AS query_pattern,
       count(*)                                                             AS executions,
       avg(now() - query_start)                                             AS avg_duration,
       max(now() - query_start)                                             AS max_duration
FROM pg_stat_activity
WHERE query != ''
  AND query NOT LIKE '%pg_stat_activity%'
GROUP BY query_pattern
ORDER BY max_duration DESC
LIMIT 20;

-- =============================================
-- УПРАВЛЕНИЕ ПАМЯТЬЮ
-- =============================================

-- Статистика использования памяти таблицами
SELECT s.schemaname,
       s.relname,
       pg_size_pretty(pg_relation_size(c.oid)) AS size,
       s.seq_scan,
       s.seq_tup_read,
       s.idx_scan,
       s.idx_tup_fetch
FROM pg_stat_user_tables s
         JOIN
     pg_class c ON s.relname = c.relname AND c.relkind = 'r'
         JOIN
     pg_namespace n ON n.oid = c.relnamespace AND n.nspname = s.schemaname
ORDER BY pg_relation_size(c.oid) DESC
LIMIT 20;

-- Кэш-эффективность таблиц
SELECT schemaname,
       relname,
       heap_blks_read,
       heap_blks_hit,
       round(heap_blks_hit * 100.0 / (heap_blks_hit + heap_blks_read + 1), 2) AS hit_ratio
FROM pg_statio_user_tables
WHERE heap_blks_read > 0
ORDER BY hit_ratio
LIMIT 20;

-- Кэш хитов/миссов
SELECT sum(heap_blks_read)                                             as heap_read,
       sum(heap_blks_hit)                                              as heap_hit,
       (sum(heap_blks_hit) - sum(heap_blks_read)) / sum(heap_blks_hit) as ratio
FROM pg_statio_user_tables;

-- =============================================
-- РАСШИРЕННАЯ ДИАГНОСТИКА
-- =============================================

-- Проверка на bloat (раздувание)
SELECT schemaname,
       tablename,
       pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)))       as table_size,
       pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) as total_size,
       (SELECT count(*)
        FROM pg_index
        WHERE indrelid = (quote_ident(schemaname) || '.' || quote_ident(tablename))::regclass)          as index_count
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) DESC
LIMIT 20;

-- Статистика по последовательностям
SELECT sequencename, last_value, increment_by, max_value, cache_size, cycle
FROM pg_sequences;

-- =============================================
-- УПРАВЛЕНИЕ РАСШИРЕНИЯМИ
-- =============================================

-- Установленные расширения
SELECT name, installed_version, comment
FROM pg_available_extensions
WHERE installed_version IS NOT NULL;

-- Доступные для установки расширения
SELECT name, default_version, comment
FROM pg_available_extensions
WHERE installed_version IS NULL;

-- =============================================
-- РЕПЛИКАЦИЯ И HA
-- =============================================

-- Статус репликации (для мастера)
SELECT client_addr,
       state,
       sync_state,
       pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)   as sent_lag,
       pg_wal_lsn_diff(sent_lsn, flush_lsn)              as flush_lag,
       pg_wal_lsn_diff(flush_lsn, replay_lsn)            as replay_lag,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) as total_lag
FROM pg_stat_replication;

-- Статус репликации (для реплики)
SELECT pg_is_in_recovery(),
       pg_last_wal_receive_lsn(),
       pg_last_wal_replay_lsn(),
       pg_last_xact_replay_timestamp(),
       pg_is_wal_replay_paused();

-- =============================================
-- РАЗНОЕ
-- =============================================

-- Поиск дубликатов индексов
SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) as size,
       (array_agg(idx))[1]                                as idx1,
       (array_agg(idx))[2]                                as idx2,
       (array_agg(idx))[3]                                as idx3,
       (array_agg(idx))[4]                                as idx4
FROM (SELECT indexrelid::regclass                                                   as idx,
             (indrelid::text || E'\n' || indclass::text || E'\n' || indkey::text || E'\n' ||
              coalesce(indexprs::text, '') || E'\n' || coalesce(indpred::text, '')) as key
      FROM pg_index) sub
GROUP BY key
HAVING count(*) > 1
ORDER BY sum(pg_relation_size(idx)) DESC;

-- Проверка настройки параметров
SELECT name, setting, unit, context, short_desc
FROM pg_settings
WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size',
               'random_page_cost', 'seq_page_cost', 'autovacuum', 'autovacuum_vacuum_scale_factor')
ORDER BY name;

-- Статистика по временным файлам
SELECT datname,
       temp_files,
       temp_bytes,
       pg_size_pretty(temp_bytes)         as temp_size,
       temp_bytes / nullif(temp_files, 0) as bytes_per_file
FROM pg_stat_database;

-- =============================================
-- ОБСЛУЖИВАНИЕ
-- =============================================

-- Принудительный vacuum
-- VACUUM (VERBOSE, ANALYZE) table_name;

-- Перестроение индекса
-- REINDEX INDEX index_name;
-- или для всей таблицы
-- REINDEX TABLE table_name;

-- Обновление статистики
-- ANALYZE table_name;

-- Проверка целостности
-- Для всей БД
CHECKPOINT;  -- Принудительная запись всех данных на диск
SET statement_timeout = 0;  -- Отключает ограничение времени выполнения
SET lock_timeout = 0;  -- Отключает таймаут ожидания блокировок
SET idle_in_transaction_session_timeout = 0;  -- Отключает таймаут неактивных транзакций
SET client_encoding = 'UTF8';  -- Устанавливает кодировку клиента
SET standard_conforming_strings = on;  -- Включает стандартное поведение строк
SET check_function_bodies = false;  -- Отключает проверку тел функций
SET client_min_messages = warning;  -- Устанавливает уровень сообщений
SET row_security = off;  -- Отключает security policies
SET search_path = public, pg_catalog;  -- Устанавливает путь поиска
SELECT pg_catalog.set_config('search_path', '', false);  -- Сбрасывает search_path
SELECT 1
FROM pg_catalog.pg_class c
         LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'::"char"  -- Ищем обычные таблицы (не индексы и т.д.)
  AND n.nspname = 'pg_catalog'  -- В системном каталоге
  AND pg_catalog.pg_table_is_visible(c.oid)  -- Видима в текущем search_path
  AND c.relname = 'pg_class';  -- Конкретно таблица pg_class