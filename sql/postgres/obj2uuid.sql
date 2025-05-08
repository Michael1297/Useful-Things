-- Основная функция для текстового ввода
CREATE OR REPLACE FUNCTION obj2uuid(object text)
    RETURNS uuid AS
$$
BEGIN
    -- Проверяем длину строки (должно быть ровно 32 hex-символа)
    IF length(object) <> 32 THEN
        RAISE EXCEPTION 'Input string must be exactly 32 hex characters long';
    END IF;

    -- Форматируем в стандартный UUID вид и конвертируем в тип UUID
    RETURN (
        substr(object, 1, 8) || '-' ||
        substr(object, 9, 4) || '-' ||
        substr(object, 13, 4) || '-' ||
        substr(object, 17, 4) || '-' ||
        substr(object, 21, 12)
        )::uuid;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Invalid UUID hex string: %', object;
END;
$$ LANGUAGE plpgsql IMMUTABLE
                    STRICT;



COMMENT ON FUNCTION obj2uuid(text) IS
'Преобразует строку из 32 шестнадцатеричных символов в UUID.

Функция принимает строку, проверяет её длину и формат, а затем преобразует её в стандартный формат UUID:
- Разделяет строку на группы символов: 8-4-4-4-12.
- Возвращает значение типа UUID.

Параметры:
  object (text): Строка, содержащая ровно 32 шестнадцатеричных символа (hex).

Возвращает:
  uuid: Преобразованное значение типа UUID.

Особенности:
  - Если входная строка не содержит ровно 32 hex-символа, выбрасывается исключение.
  - Если строка содержит недопустимые символы, выбрасывается исключение.

Примеры использования:
  SELECT obj2uuid(''123e4567e89b12d3a456426614174000'');
  -- Результат: 123e4567-e89b-12d3-a456-426614174000

  SELECT obj2uuid(''123e4567e89b12d3a4564266141740'');
  -- Ошибка: Input string must be exactly 32 hex characters long

  SELECT obj2uuid(''123e4567e89b12d3a45642661417400z'');
  -- Ошибка: Invalid UUID hex string

Примечание:
  Функция строгая (STRICT), поэтому она автоматически возвращает NULL,
  если входной параметр равен NULL.';