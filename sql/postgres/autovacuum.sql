-- Текущие процессы autovacuum
SELECT *
FROM pg_stat_activity
WHERE query LIKE 'autovacuum%';

-- Статистика по vacuum и autovacuum
SELECT schemaname,
       relname,
       last_vacuum,
       last_autovacuum,
       vacuum_count,
       autovacuum_count
FROM pg_stat_all_tables
WHERE schemaname NOT LIKE 'pg_%'
order by last_autovacuum;

-- Статистика по "мертвым" кортежам
SELECT schemaname,
       relname,
       n_dead_tup,
       n_live_tup,
       (n_dead_tup::float / (n_live_tup + n_dead_tup)) * 100 AS dead_tup_percent
FROM pg_stat_all_tables
WHERE n_live_tup + n_dead_tup > 0
  AND schemaname NOT LIKE 'pg_%'
ORDER BY dead_tup_percent DESC, n_dead_tup;

-- Просмотр глобальных настроек autovacuum
SELECT name, setting, unit, category, short_desc
FROM pg_settings
WHERE name LIKE 'autovacuum%'
ORDER BY name;

-- Просмотр настроек autovacuum для конкретной таблицы
SELECT relname    AS table_name,
       reloptions AS table_options
FROM pg_class
WHERE reloptions IS NOT NULL
  -- Только таблицы
  AND relkind = 'r';


--Чтобы изменить параметры autovacuum для всей базы данных, отредактируйте файл postgresql.conf или используйте команду ALTER SYSTEM:
ALTER SYSTEM SET autovacuum_vacuum_scale_factor = 0.1;
ALTER SYSTEM SET autovacuum_vacuum_threshold = 1000;
ALTER SYSTEM SET autovacuum_max_workers = 5;

--После изменения параметров перезагрузите конфигурацию:
SELECT pg_reload_conf();