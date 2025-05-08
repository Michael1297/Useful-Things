CREATE OR REPLACE FUNCTION alphanum_sort_key(text) RETURNS text AS $$
DECLARE
result text := '';
    chunk text;
    remaining_text text := $1;
BEGIN
    -- Если входное значение NULL, возвращаем NULL
    IF remaining_text IS NULL THEN
        RETURN NULL;
END IF;

    WHILE remaining_text != '' LOOP
            chunk := substring(remaining_text from '^([^0-9]*|[0-9]+)');

            IF chunk ~ '^[0-9]+$' THEN
                -- Форматируем числа с ведущими нулями
                result := result || lpad(chunk, 30, '0');
ELSE
                result := result || chunk;
END IF;

            remaining_text := substring(remaining_text from length(chunk) + 1);
END LOOP;

RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION alphanum_sort_key(text) IS
'Генерирует ключ сортировки для строки, сохраняющий альфанумерический порядок.

Функция преобразует строку в формат, который можно использовать для сортировки:
- Числовые части дополняются ведущими нулями до фиксированной длины (30 символов).
- Нечисловые части остаются без изменений.

Параметры:
  text: Исходная строка для преобразования.

Возвращает:
  text: Ключ сортировки, который можно использовать для альфанумерической сортировки.

Пример использования:
  SELECT alphanum_sort_key(''item2'');
  -- Результат: ''item000000000000000000000000000002''

  SELECT alphanum_sort_key(''item10'');
  -- Результат: ''item000000000000000000000000000010''

Примечание:
  NULL на входе возвращает NULL.';