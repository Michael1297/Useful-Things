CREATE OR REPLACE FUNCTION add_or_replace_json_array_element(
    p_array jsonb,
    p_element jsonb,
    p_key text
) RETURNS jsonb AS $$
DECLARE
    v_found boolean := false;
    v_element_key_value text;
    v_array_element jsonb;
    v_new_array jsonb := '[]'::jsonb;
    i integer;
BEGIN
    -- Проверка на NULL для всех аргументов
    IF p_array IS NULL THEN
        RAISE EXCEPTION 'Первый параметр (массив) не может быть NULL';
    END IF;

    IF p_element IS NULL THEN
        RAISE EXCEPTION 'Второй параметр (элемент) не может быть NULL';
    END IF;

    IF p_key IS NULL THEN
        RAISE EXCEPTION 'Третий параметр (ключ) не может быть NULL';
    END IF;

    -- Проверка что p_array является массивом JSON
    IF p_array IS NOT NULL AND jsonb_typeof(p_array) != 'array' THEN
        RAISE EXCEPTION 'Первый параметр должен быть JSON массивом';
    END IF;

    -- Проверка что p_element является объектом JSON
    IF p_element IS NULL OR jsonb_typeof(p_element) != 'object' THEN
        RAISE EXCEPTION 'Второй параметр должен быть JSON объектом';
    END IF;

    -- Проверка, что ключ существует в JSON объекте
    IF NOT p_element ? p_key THEN
        RAISE EXCEPTION 'Ключ "%" отсутствует в JSON объекте', p_key;
    END IF;

    -- Получаем значение ключа из элемента, который нужно вставить/заменить
    v_element_key_value := p_element->>p_key;

    -- Если входной массив NULL, создаем новый массив с нашим элементом
    IF p_array IS NULL THEN
        RETURN jsonb_build_array(p_element);
    END IF;

    -- Проходим по всем элементам массива
    FOR i IN 0..jsonb_array_length(p_array) - 1 LOOP
            v_array_element := p_array->i;

            -- Проверка, что элемент массива является объектом
            IF jsonb_typeof(v_array_element) != 'object' THEN
                RAISE EXCEPTION 'Элемент массива с индексом % не является JSON объектом', i;
            END IF;

            -- Если ключ текущего элемента совпадает с ключом нового элемента
            IF v_array_element->>p_key = v_element_key_value THEN
                -- Добавляем новый элемент вместо старого
                v_new_array := v_new_array || p_element;
                v_found := true;
            ELSE
                -- Иначе добавляем существующий элемент
                v_new_array := v_new_array || v_array_element;
            END IF;
        END LOOP;

    -- Если элемент не найден, добавляем его в конец массива
    IF NOT v_found THEN
        v_new_array := v_new_array || p_element;
    END IF;

    RETURN v_new_array;
END;
$$ LANGUAGE plpgsql;



COMMENT ON FUNCTION add_or_replace_json_array_element(jsonb, jsonb, text) IS
    'Добавляет или заменяет элемент в JSONB массиве.
    Параметры:
      p_array: Входной JSONB массив.
      p_element: JSONB объект для добавления/замены.
      p_key: Ключ для сравнения.
    Возвращает: Обновленный JSONB массив.';