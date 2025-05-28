CREATE OR REPLACE FUNCTION is_null_or_empty(str TEXT)
RETURNS BOOLEAN AS $$
SELECT str IS NULL OR str = '';
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


COMMENT ON FUNCTION is_null_or_empty(text) IS
'Проверяет, является ли строка NULL или пустой (равной '''').

Функция возвращает:
  - TRUE, если строка равна NULL или является пустой строкой ('''').
  - FALSE, если строка содержит хотя бы один символ (включая пробелы).

Параметры:
  str (text): Строка для проверки.

Возвращает:
  boolean:
    - TRUE, если строка NULL или пустая.
    - FALSE, если строка содержит символы.

Примеры использования:
  SELECT is_null_or_empty(NULL);
  -- Результат: TRUE

  SELECT is_null_or_empty('');
  -- Результат: TRUE

  SELECT is_null_or_empty(''   '');
  -- Результат: FALSE (строка содержит пробелы)

  SELECT is_null_or_empty(''hello'');
  -- Результат: FALSE

Примечание:
  Функция не учитывает пробельные символы. Для проверки строки с учётом пробельных символов используйте функцию is_null_or_blank.';
