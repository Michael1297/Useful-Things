CREATE OR REPLACE FUNCTION kmp_search(haystack TEXT, needle TEXT)
    RETURNS TABLE (match_position INTEGER) AS $$
DECLARE
    haystack_length INTEGER := LENGTH(COALESCE(haystack, ''));
    needle_length INTEGER;
    prefix_array INTEGER[];
    current_match_length INTEGER := 0;
    haystack_index INTEGER;
    needle_index INTEGER;
BEGIN
    -- Обработка NULL значений
    needle := COALESCE(needle, '');
    haystack := COALESCE(haystack, '');

    needle_length := LENGTH(needle);

    -- Ранний выход для пустой подстроки
    IF needle_length = 0 THEN
        RAISE NOTICE 'Needle is empty. No matches to find.';
        RETURN;
    END IF;

    -- Оптимизация: если needle длиннее haystack, совпадений быть не может
    IF needle_length > haystack_length THEN
        RETURN;
    END IF;

    -- Вычисление префикс-функции (массива длин наибольших бордеров)
    prefix_array := array_fill(0, ARRAY[needle_length]);

    FOR needle_index IN 2..needle_length LOOP
            WHILE current_match_length > 0
                AND substring(needle FROM current_match_length + 1 FOR 1)
                      <> substring(needle FROM needle_index FOR 1) LOOP
                    current_match_length := prefix_array[current_match_length];
                END LOOP;

            IF substring(needle FROM current_match_length + 1 FOR 1)
                = substring(needle FROM needle_index FOR 1) THEN
                current_match_length := current_match_length + 1;
            END IF;

            prefix_array[needle_index] := current_match_length;
        END LOOP;

    -- Основной этап поиска
    current_match_length := 0;

    FOR haystack_index IN 1..haystack_length LOOP
            WHILE current_match_length > 0
                AND substring(needle FROM current_match_length + 1 FOR 1)
                      <> substring(haystack FROM haystack_index FOR 1) LOOP
                    current_match_length := prefix_array[current_match_length];
                END LOOP;

            IF substring(needle FROM current_match_length + 1 FOR 1)
                = substring(haystack FROM haystack_index FOR 1) THEN
                current_match_length := current_match_length + 1;
            END IF;

            -- Найдено полное совпадение
            IF current_match_length = needle_length THEN
                match_position := haystack_index - needle_length + 1;
                RETURN NEXT;
                current_match_length := prefix_array[current_match_length];
            END IF;
        END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;



COMMENT ON FUNCTION kmp_search(text, text) IS
'Выполняет поиск всех вхождений подстроки (needle) в строку (haystack) с использованием алгоритма Кнута-Морриса-Пратта (KMP).

Алгоритм KMP эффективно находит все позиции, где начинается подстрока needle в строке haystack, даже если haystack содержит повторяющиеся символы.

Параметры:
  haystack (text): Строка, в которой выполняется поиск.
  needle (text): Подстрока, которую нужно найти.

Возвращает:
  TABLE (match_position INTEGER):
    - match_position: Позиция (индекс), с которой начинается вхождение needle в haystack.
      Индексация начинается с 1.

Особенности:
  - Если needle пустая строка, функция завершается без результатов.
  - Если needle длиннее haystack, функция завершается без результатов.
  - NULL значения преобразуются в пустые строки ('').

Примеры использования:
  SELECT * FROM kmp_search(''abracadabra'', ''abra'');
  -- Результат: match_position = 1, 8

  SELECT * FROM kmp_search(''hello world'', ''world'');
  -- Результат: match_position = 7

  SELECT * FROM kmp_search(''test'', '''');
  -- Результат: Нет совпадений (пустая needle)

  SELECT * FROM kmp_search(NULL, ''abra'');
  -- Результат: Нет совпадений (пустой haystack)

Примечание:
  Функция использует префикс-функцию для предварительной обработки needle,
  что обеспечивает линейную сложность поиска O(n + m),
  где n - длина haystack, m - длина needle.';