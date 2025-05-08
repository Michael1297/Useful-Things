/*
Функция dbo.wildcard_match проверяет, соответствует ли строка (@text) шаблону (@pattern),
содержащему wildcard символы ('*' и '?').

Описание:
- Функция использует динамическое программирование (Dynamic Programming, DP) для проверки соответствия.
- Шаблон может содержать следующие wildcard символы:
  - "*" соответствует любому количеству символов (включая ноль символов).
  - "?" соответствует ровно одному любому символу.
- Результатом является BIT (0 или 1), где:
  - 1 означает, что строка соответствует шаблону.
  - 0 означает, что строка не соответствует шаблону.

Параметры:
  @text (NVARCHAR(MAX)): Исходная строка для проверки. Если NULL, функция возвращает 0.
  @pattern (NVARCHAR(MAX)): Шаблон для проверки. Если NULL, функция возвращает NULL (ошибка).

Возвращает:
  BIT:
    - 1, если строка соответствует шаблону.
    - 0, если строка не соответствует шаблону.
    - NULL, если шаблон равен NULL (ошибка).

Примеры использования:
  SELECT dbo.wildcard_match('hello', 'he*');
  -- Результат: 1 (шаблон "he*" соответствует)

  SELECT dbo.wildcard_match('hello', 'h?llo');
  -- Результат: 1 (шаблон "h?llo" соответствует)

  SELECT dbo.wildcard_match('hello', '*o');
  -- Результат: 1 (шаблон "*o" соответствует)

  SELECT dbo.wildcard_match('hello', 'world');
  -- Результат: 0 (шаблон "world" не соответствует)

  SELECT dbo.wildcard_match(NULL, 'he*');
  -- Результат: 0 (строка равна NULL)

  SELECT dbo.wildcard_match('hello', NULL);
  -- Результат: NULL (шаблон равен NULL)

Особенности:
  - Если @text равен NULL, функция возвращает 0.
  - Если @pattern равен NULL, функция возвращает NULL (это можно интерпретировать как ошибку).
  - Пустой шаблон ("") соответствует только пустой строке ("").
  - Шаблон может начинаться с "*", что позволяет ему соответствовать началу строки.

Примечание:
  Функция реализует алгоритм динамического программирования для эффективной проверки соответствия строки шаблону.
  Размер таблицы DP равен (m+1) x (n+1), где m — длина строки, n — длина шаблона.
*/
CREATE OR ALTER FUNCTION dbo.wildcard_match
(
    @text NVARCHAR(MAX),
    @pattern NVARCHAR(MAX)
)
    RETURNS BIT
AS
BEGIN
    -- Return false (0) if text is NULL
    IF @text IS NULL
        RETURN 0;

    -- Return NULL (which can be interpreted as an error) if pattern is NULL
    -- Caller should check for NULL return value to detect this error condition
    IF @pattern IS NULL
        RETURN NULL;

    DECLARE @m INT = LEN(@text);
    DECLARE @n INT = LEN(@pattern);

    -- Create a temporary table to simulate a 2D array for DP
    DECLARE @dp TABLE (
                          i INT,
                          j INT,
                          val BIT
                      );

    -- Base case: empty pattern matches empty text
    INSERT INTO @dp (i, j, val) VALUES (0, 0, 1);

    -- Handle patterns starting with '*'
    DECLARE @j INT = 1;
    WHILE @j <= @n
        BEGIN
            IF SUBSTRING(@pattern, @j, 1) = '*'
                BEGIN
                    INSERT INTO @dp (i, j, val)
                    SELECT 0, @j, val FROM @dp WHERE i = 0 AND j = @j - 1;
                END
            SET @j = @j + 1;
        END

    -- Fill the DP table
    DECLARE @i INT = 1;
    WHILE @i <= @m
        BEGIN
            SET @j = 1;
            WHILE @j <= @n
                BEGIN
                    DECLARE @textChar NCHAR(1) = SUBSTRING(@text, @i, 1);
                    DECLARE @patternChar NCHAR(1) = SUBSTRING(@pattern, @j, 1);
                    DECLARE @result BIT = 0;

                    IF @patternChar = @textChar OR @patternChar = '?'
                        BEGIN
                            SELECT @result = val FROM @dp WHERE i = @i - 1 AND j = @j - 1;
                        END
                    ELSE IF @patternChar = '*'
                        BEGIN
                            DECLARE @matchZero BIT, @matchOne BIT;

                            SELECT @matchZero = val FROM @dp WHERE i = @i AND j = @j - 1;
                            SELECT @matchOne = val FROM @dp WHERE i = @i - 1 AND j = @j;

                            SET @result = CASE WHEN @matchZero = 1 OR @matchOne = 1 THEN 1 ELSE 0 END;
                        END

                    INSERT INTO @dp (i, j, val) VALUES (@i, @j, @result);

                    SET @j = @j + 1;
                END
            SET @i = @i + 1;
        END

    -- The result is in the bottom-right cell of the DP table
    DECLARE @match BIT;
    SELECT @match = val FROM @dp WHERE i = @m AND j = @n;

    RETURN ISNULL(@match, 0);
END
