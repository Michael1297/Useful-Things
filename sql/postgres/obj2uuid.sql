-- Основная функция для текстового ввода
CREATE OR REPLACE FUNCTION obj2uuid(object TEXT)
RETURNS UUID AS $$
SELECT (
           substring(object FROM 1 FOR 8) || '-' ||
           substring(object FROM 9 FOR 4) || '-' ||
           substring(object FROM 13 FOR 4) || '-' ||
           substring(object FROM 17 FOR 4) || '-' ||
           substring(object FROM 21 FOR 12)
           )::UUID;
$$ LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE;



COMMENT ON FUNCTION obj2uuid(text) IS
'Преобразует строку из 32 шестнадцатеричных символов в UUID.

Функция принимает строку, проверяет её длину и формат, а затем преобразует её в стандартный формат UUID:
- Разделяет строку на группы символов: 8-4-4-4-12.
- Возвращает значение типа UUID.';
