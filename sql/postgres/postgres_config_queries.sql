-- Путь к основному конфигурационному файлу postgresql.conf
SHOW config_file;

-- Путь к файлу аутентификации pg_hba.conf
SHOW hba_file;

-- Путь к файлу идентификации pg_ident.conf
SHOW ident_file;

-- Путь к каталогу данных (data directory)
SHOW data_directory;

-- Версия PostgreSQL
SHOW server_version;

-- Путь к исполняемому файлу сервера PostgreSQL
SHOW config_executable;

-- Путь к каталогу временных файлов
SHOW temp_tablespaces;

-- Текущая кодировка базы данных
SHOW server_encoding;

-- Локаль, используемая сервером
SHOW lc_collate;

-- Локаль для сортировки
SHOW lc_ctype;

-- Максимальное количество подключений
SHOW max_connections;

-- Путь к каталогу журналов (если настроен внутри конфигурации)
SHOW log_directory;

-- Формат файлов логов
SHOW log_filename;

-- Текущий рабочий каталог сервера
SHOW data_checksums;



SELECT name, setting, context, vartype, source
FROM pg_settings
ORDER BY name;