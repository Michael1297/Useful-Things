CREATE OR REPLACE FUNCTION wildcard_match(text TEXT, pattern TEXT)
    RETURNS BOOLEAN AS $$
DECLARE
m INT;
    n INT;
    dp BOOLEAN[][];
    i INT;
    j INT;
BEGIN
    -- Return false if text is NULL
    IF text IS NULL THEN
        RETURN false;
    END IF;

    -- Throw exception if pattern is NULL
    IF pattern IS NULL THEN
        RAISE EXCEPTION 'Pattern cannot be NULL';
    END IF;

    m := length(text);
    n := length(pattern);

    -- Initialize DP table with false values
    dp := array_fill(false, ARRAY[m+1, n+1]);

    -- Base case: empty pattern matches empty text
    dp[1][1] := true;

    -- Handle patterns starting with '*'
FOR j IN 2..n+1 LOOP
            IF substring(pattern FROM j-1 FOR 1) = '*' THEN
                dp[1][j] := dp[1][j-1];
END IF;
END LOOP;

    -- Fill the DP table
FOR i IN 2..m+1 LOOP
            FOR j IN 2..n+1 LOOP
                    IF substring(pattern FROM j-1 FOR 1) = substring(text FROM i-1 FOR 1)
                        OR substring(pattern FROM j-1 FOR 1) = '?' THEN
                        dp[i][j] := dp[i-1][j-1];
                    ELSIF substring(pattern FROM j-1 FOR 1) = '*' THEN
                        -- '*' can match zero or more characters
                        dp[i][j] := dp[i-1][j] OR dp[i][j-1];
ELSE
                        dp[i][j] := false;
END IF;
END LOOP;
END LOOP;

    -- The result is in the bottom-right cell of the DP table
RETURN dp[m+1][n+1];
END;
$$ LANGUAGE plpgsql;



COMMENT ON FUNCTION wildcard_match(text, text) IS
'Проверяет, соответствует ли строка (text) шаблону (pattern) с поддержкой wildcard символов ("*" и "?").

Функция использует динамическое программирование для проверки соответствия строки шаблону.
Шаблон может содержать следующие wildcard символы:
  - "*" соответствует любому количеству символов (включая ноль символов).
  - "?" соответствует ровно одному любому символу.

Параметры:
  text (text): Исходная строка для проверки. Не может быть NULL.
  pattern (text): Шаблон для проверки. Не может быть NULL.

Возвращает:
  BOOLEAN:
    - TRUE, если строка соответствует шаблону.
    - FALSE, если строка не соответствует шаблону.

Особенности:
  - Если text равен NULL, функция возвращает FALSE.
  - Если pattern равен NULL, выбрасывается исключение.
  - Пустой шаблон ("") соответствует только пустой строке ("").
  - Шаблон может начинаться с "*", что позволяет ему соответствовать началу строки.

Примеры использования:
  SELECT wildcard_match(''hello'', ''he*'');
  -- Результат: TRUE (шаблон "he*" соответствует)

  SELECT wildcard_match(''hello'', ''h?llo'');
  -- Результат: TRUE (шаблон "h?llo" соответствует)

  SELECT wildcard_match(''hello'', ''*o'');
  -- Результат: TRUE (шаблон "*o" соответствует)

  SELECT wildcard_match(''hello'', ''world'');
  -- Результат: FALSE (шаблон "world" не соответствует)

  SELECT wildcard_match(NULL, ''*'');
  -- Результат: FALSE (text равен NULL)

  SELECT wildcard_match(''hello'', NULL);
  -- Ошибка: Pattern cannot be NULL

Примечание:
  Функция реализует алгоритм динамического программирования для эффективной проверки соответствия строки шаблону.
  Размер таблицы DP равен (m+1) x (n+1), где m - длина строки, n - длина шаблона.';