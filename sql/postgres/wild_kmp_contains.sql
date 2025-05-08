CREATE OR REPLACE FUNCTION wild_kmp_contains(
    text TEXT,
    pattern TEXT
) RETURNS BOOLEAN AS
$$
DECLARE
    text_length          INTEGER;
    pattern_length       INTEGER;
    prefix_table         INTEGER[];
    longest_prefix_index INTEGER;
    i                    INTEGER;
    match_length         INTEGER;
    wild_letter          TEXT;
    is_already_matched   BOOLEAN;
    matched_text         TEXT;
    matched_pattern      TEXT;
BEGIN
    text_length := length(text);
    pattern_length := length(pattern);

    IF pattern_length > text_length THEN
        RETURN FALSE;
    END IF;

    -- Create prefix table (DFA)
    prefix_table := array_fill(0, ARRAY [pattern_length]);
    longest_prefix_index := 0;

    FOR i IN 2..pattern_length - 1
        LOOP

            -- back-track
            WHILE longest_prefix_index > 0 AND
                  substring(pattern FROM longest_prefix_index + 1 FOR 1) != substring(pattern FROM i + 1 FOR 1)
                LOOP
                    longest_prefix_index := prefix_table[longest_prefix_index + 1];
                END LOOP;

            -- match
            IF substring(pattern FROM longest_prefix_index + 1 FOR 1) = substring(pattern FROM i + 1 FOR 1) THEN
                longest_prefix_index := longest_prefix_index + 1;
            END IF;

            prefix_table[i + 1] := longest_prefix_index;
        END LOOP;

    match_length := 0;
    wild_letter := NULL;

    FOR i IN 0..text_length - 1
        LOOP
            -- back-track on failure
            WHILE match_length > 0 AND
                  substring(pattern FROM match_length + 1 FOR 1) != substring(text FROM i + 1 FOR 1)
                LOOP
                    -- check if fail was due to wildcard
                    IF substring(pattern FROM match_length + 1 FOR 1) = '*' THEN

                        -- if initial wildcard, set it
                        IF wild_letter IS NULL THEN
                            wild_letter := substring(text FROM i + 1 FOR 1);

                            -- loop-back with KMP - double check already matched pattern
                            matched_text := substring(text FROM i - match_length + 1 FOR match_length);
                            matched_pattern := substring(pattern FROM 1 FOR match_length);

                            is_already_matched := wild_kmp_contains(matched_text, matched_pattern);

                            IF NOT is_already_matched THEN
                                match_length := 0; -- reset match
                            ELSIF match_length > 0 AND substring(pattern FROM match_length FOR 1) = '*' THEN
                                wild_letter := substring(text FROM i FOR 1); -- reset wildcard
                            END IF;
                            EXIT;
                        ELSIF wild_letter = substring(text FROM i + 1 FOR 1) THEN
                            EXIT; -- wildcard matches
                        END IF;
                    END IF;

                    match_length := prefix_table[match_length]; -- fall-back
                    wild_letter := NULL;

                    -- edge case - match previous seen for proper shift
                    IF match_length = 0 AND pattern_length > 1 AND substring(pattern FROM match_length + 2 FOR 1) = '*'
                        AND i > 0 AND substring(text FROM i FOR 1) = substring(pattern FROM match_length + 1 FOR 1) THEN
                        match_length := match_length + 1;
                    END IF;
                END LOOP;

            -- match or wildcard
            IF match_length < pattern_length AND
               (substring(pattern FROM match_length + 1 FOR 1) = substring(text FROM i + 1 FOR 1)
                   OR substring(pattern FROM match_length + 1 FOR 1) = '*') THEN

                -- wildcard
                IF substring(pattern FROM match_length + 1 FOR 1) = '*' THEN
                    IF wild_letter IS NULL THEN
                        wild_letter := substring(text FROM i + 1 FOR 1); -- set wildcard
                    ELSIF wild_letter != substring(text FROM i + 1 FOR 1) THEN
                        -- doesn't match current wildcard
                        IF match_length = 1 THEN
                            wild_letter := substring(text FROM i + 1 FOR 1); -- edge case, new wildcard
                            CONTINUE;
                        END IF;
                        -- reset
                        wild_letter := NULL;
                        match_length := 0;
                        CONTINUE;
                    END IF;
                ELSE
                    wild_letter := NULL; -- reset wildcard
                END IF;
                match_length := match_length + 1; -- matched
            END IF;

            -- found the pattern
            IF match_length = pattern_length THEN
                RETURN TRUE;
            END IF;
        END LOOP;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;



COMMENT ON FUNCTION wild_kmp_contains(text, text) IS
'Проверяет, содержится ли подстрока (pattern) в строке (text) с использованием алгоритма Кнута-Морриса-Пратта (KMP) с поддержкой символа-шаблона ("*").

Функция проверяет, содержится ли pattern в text. Символ "*" в pattern обрабатывается как "любой одиночный символ" (wildcard).

Параметры:
  text (text): Исходная строка, в которой выполняется поиск.
  pattern (text): Подстрока для поиска, которая может содержать символ "*" как wildcard.

Возвращает:
  BOOLEAN:
    - TRUE, если pattern найден в text.
    - FALSE, если pattern не найден.

Особенности:
  - Если pattern длиннее text, функция возвращает FALSE.
  - Символ "*" в pattern соответствует любому одному символу в text.
  - Если pattern содержит несколько символов "*", они обрабатываются независимо.
  - NULL значения для text или pattern не поддерживаются.

Примеры использования:
  SELECT wild_kmp_contains(''hello world'', ''he*'');
  -- Результат: TRUE (pattern "he*" найден)

  SELECT wild_kmp_contains(''hello world'', ''*o w*'');
  -- Результат: TRUE (pattern "*o w*" найден)

  SELECT wild_kmp_contains(''hello world'', ''world'');
  -- Результат: TRUE (точное совпадение без wildcard)

  SELECT wild_kmp_contains(''hello world'', ''abc'');
  -- Результат: FALSE (pattern не найден)

Примечание:
  Функция реализует модифицированный алгоритм KMP, который учитывает wildcard "*".
  Это обеспечивает эффективный поиск даже при наличии шаблонов с wildcard.

  Для корректной работы:
  - Убедитесь, что входные данные не содержат NULL.
  - Убедитесь, что pattern не пустой.';