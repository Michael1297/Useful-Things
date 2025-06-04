-- Основная функция для текстового ввода
CREATE OR REPLACE FUNCTION obj2uuid(object TEXT)
RETURNS UUID AS $$
SELECT (
           substr(object, 1, 8) || '-' ||
           substr(object, 9, 4) || '-' ||
           substr(object, 13, 4) || '-' ||
           substr(object, 17, 4) || '-' ||
           substr(object, 21, 12)
           )::UUID;
$$ LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE;



COMMENT ON FUNCTION obj2uuid(text) IS
'Преобразует строку из 32 шестнадцатеричных символов в UUID.

Функция принимает строку, а затем преобразует её в стандартный формат UUID:
- Разделяет строку на группы символов: 8-4-4-4-12.
- Возвращает значение типа UUID.';
