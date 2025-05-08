CREATE OR REPLACE FUNCTION remove_json_array_element(
    p_array jsonb,
    p_key text,
    p_value text
) RETURNS jsonb AS $$
DECLARE
    v_result jsonb := '[]'::jsonb;
    v_array_element jsonb;
    i integer;
BEGIN
    -- Проверка на NULL для всех аргументов
    IF p_array IS NULL THEN
        RAISE EXCEPTION 'Первый параметр (массив) не может быть NULL';
    END IF;

    IF p_key IS NULL THEN
        RAISE EXCEPTION 'Второй параметр (ключ) не может быть NULL';
    END IF;

    IF p_value IS NULL THEN
        RAISE EXCEPTION 'Третий параметр (значение) не может быть NULL';
    END IF;

    -- Проверка что p_array является массивом JSON
    IF jsonb_typeof(p_array) != 'array' THEN
        RAISE EXCEPTION 'Первый параметр должен быть JSON массивом';
    END IF;

    -- Проходим по всем элементам массива
    FOR i IN 0..jsonb_array_length(p_array) - 1 LOOP
            v_array_element := p_array->i;

            -- Проверка, что элемент массива является объектом
            IF jsonb_typeof(v_array_element) != 'object' THEN
                RAISE EXCEPTION 'Элемент массива с индексом % не является JSON объектом', i;
            END IF;

            -- Если ключ текущего элемента не совпадает с искомым значением, добавляем в результат
            IF v_array_element->>p_key IS DISTINCT FROM p_value THEN
                v_result := v_result || v_array_element;
            END IF;
        END LOOP;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;


COMMENT ON FUNCTION remove_json_array_element(jsonb, text, text) IS
'Удаляет элемент из JSONB массива на основе значения указанного ключа.

Функция проходит по всем элементам JSONB массива и удаляет те, у которых значение указанного ключа совпадает с заданным значением.

Параметры:
  p_array (jsonb): Входной JSONB массив. Не может быть NULL.
  p_key (text): Ключ, по которому выполняется сравнение. Не может быть NULL.
  p_value (text): Значение, которое нужно найти и удалить. Не может быть NULL.

Возвращает:
  jsonb: Новый JSONB массив, из которого удалены все элементы с указанным ключом и значением.

Особенности:
  - Если входной массив пуст, возвращается пустой массив.
  - Если ни один элемент не соответствует критерию, возвращается исходный массив без изменений.
  - Если входной массив не является JSONB массивом или его элементы не являются JSONB объектами, выбрасывается исключение.

Примеры использования:
  SELECT remove_json_array_element(
      ''[{"id": "1", "name": "Alice"}, {"id": "2", "name": "Bob"}]''::jsonb,
      ''id'',
      ''1''
  );
  -- Результат: [{"id": "2", "name": "Bob"}]

  SELECT remove_json_array_element(
      ''[{"id": "1", "name": "Alice"}, {"id": "2", "name": "Bob"}]''::jsonb,
      ''id'',
      ''3''
  );
  -- Результат: [{"id": "1", "name": "Alice"}, {"id": "2", "name": "Bob"}]

  SELECT remove_json_array_element(
      ''[]''::jsonb,
      ''id'',
      ''1''
  );
  -- Результат: []

Примечание:
  Функция чувствительна к регистру ключей и значений. Убедитесь, что ключ и значение передаются в правильном формате.';