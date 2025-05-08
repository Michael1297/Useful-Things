/*
Функция dbo.alphanum_compare выполняет сравнение двух строк (a и b) по правилам "альфанумерического" (или "естественного") порядка.

Описание:
- Функция разбивает строки на числовые и нечисловые части.
- Числовые части сравниваются как числа, а нечисловые — как строки.
- Это обеспечивает "естественный" порядок сортировки, например: "item2" < "item10".

Параметры:
  @a (NVARCHAR(MAX)): Первая строка для сравнения.
  @b (NVARCHAR(MAX)): Вторая строка для сравнения.

Возвращает:
  INT:
    - -1, если @a < @b;
    - 0, если @a = @b;
    - 1, если @a > @b.

Примеры использования:
  SELECT dbo.alphanum_compare('item2', 'item10');
  -- Результат: -1 (так как "item2" < "item10")

  SELECT dbo.alphanum_compare('file100', 'file20');
  -- Результат: 1 (так как "file100" > "file20")

  SELECT dbo.alphanum_compare('abc', 'abc');
  -- Результат: 0 (строки равны)

Особенности:
  - Если одна из строк NULL, она считается пустой ('').
  - Числовые части сравниваются как BIGINT.
  - Нечисловые части сравниваются лексикографически.

Примечание:
  Функция полезна для реализации "естественной" сортировки строк, где числовые части обрабатываются корректно.
*/
CREATE OR ALTER FUNCTION dbo.alphanum_compare(@a NVARCHAR(MAX), @b NVARCHAR(MAX))
    RETURNS INT
AS
BEGIN
    DECLARE @a_chunk NVARCHAR(MAX)
    DECLARE @b_chunk NVARCHAR(MAX)
    DECLARE @a_rest NVARCHAR(MAX) = ISNULL(@a, '')
    DECLARE @b_rest NVARCHAR(MAX) = ISNULL(@b, '')
    DECLARE @a_num BIGINT
    DECLARE @b_num BIGINT
    DECLARE @is_a_num BIT
    DECLARE @is_b_num BIT
    DECLARE @a_pos INT
    DECLARE @b_pos INT

    WHILE LEN(@a_rest) > 0 OR LEN(@b_rest) > 0
        BEGIN
            -- Обработка для @a_rest
            SET @a_pos = PATINDEX('%[0-9]%', @a_rest)
            IF @a_pos = 0
                SET @a_chunk = @a_rest
            ELSE IF @a_pos = 1
                SET @a_chunk = LEFT(@a_rest, PATINDEX('%[^0-9]%', @a_rest + 'X') - 1)
            ELSE
                SET @a_chunk = LEFT(@a_rest, @a_pos - 1)

            -- Обработка для @b_rest
            SET @b_pos = PATINDEX('%[0-9]%', @b_rest)
            IF @b_pos = 0
                SET @b_chunk = @b_rest
            ELSE IF @b_pos = 1
                SET @b_chunk = LEFT(@b_rest, PATINDEX('%[^0-9]%', @b_rest + 'X') - 1)
            ELSE
                SET @b_chunk = LEFT(@b_rest, @b_pos - 1)

            IF LEN(@a_chunk) = 0 AND LEN(@b_chunk) = 0
                RETURN 0

            IF LEN(@a_chunk) = 0
                RETURN -1

            IF LEN(@b_chunk) = 0
                RETURN 1

            -- Проверяем, являются ли части числами
            SET @is_a_num = CASE WHEN @a_chunk NOT LIKE '%[^0-9]%' AND LEN(@a_chunk) > 0 THEN 1 ELSE 0 END
            SET @is_b_num = CASE WHEN @b_chunk NOT LIKE '%[^0-9]%' AND LEN(@b_chunk) > 0 THEN 1 ELSE 0 END

            IF @is_a_num = 1 AND @is_b_num = 1
                BEGIN
                    -- Сравниваем числа
                    SET @a_num = TRY_CAST(@a_chunk AS BIGINT)
                    SET @b_num = TRY_CAST(@b_chunk AS BIGINT)

                    IF @a_num < @b_num RETURN -1
                    IF @a_num > @b_num RETURN 1
                END
            ELSE
                BEGIN
                    -- Сравниваем как строки
                    IF @a_chunk < @b_chunk RETURN -1
                    IF @a_chunk > @b_chunk RETURN 1
                END

            -- Обрезаем обработанную часть
            SET @a_rest = STUFF(@a_rest, 1, LEN(@a_chunk), '')
            SET @b_rest = STUFF(@b_rest, 1, LEN(@b_chunk), '')
        END

    RETURN 0
END
