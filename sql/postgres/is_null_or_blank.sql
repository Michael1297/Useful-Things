CREATE OR REPLACE FUNCTION is_null_or_blank(str TEXT)
RETURNS BOOLEAN AS $$
SELECT str IS NULL OR trim(str) = '';
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


COMMENT ON FUNCTION is_null_or_blank(text) IS
'Проверяет, является ли строка NULL или пустой (состоит только из пробельных символов).

Функция возвращает:
  - TRUE, если строка равна NULL или состоит только из пробелов, табуляций и других пробельных символов.
  - FALSE, если строка содержит хотя бы один непробельный символ.

Параметры:
  str (text): Строка для проверки.

Возвращает:
  boolean:
    - TRUE, если строка NULL или пустая.
    - FALSE, если строка содержит значимые символы.

Примеры использования:
  SELECT is_null_or_blank(NULL);
  -- Результат: TRUE

  SELECT is_null_or_blank(''   '');
  -- Результат: TRUE

  SELECT is_null_or_blank(''hello'');
  -- Результат: FALSE

Примечание:
  Функция использует функцию trim() для удаления пробельных символов с обоих концов строки перед проверкой.';
