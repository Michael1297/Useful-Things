/*
Функция dbo.alphanum_sort_key преобразует строку в "ключ сортировки", который сохраняет альфанумерический порядок.

Описание:
- Функция разбивает строку на числовые и нечисловые блоки.
- Числовые блоки дополняются ведущими нулями до фиксированной длины (30 символов).
- Нечисловые блоки остаются без изменений.
- Результат можно использовать для сортировки строк в альфанумерическом порядке.

Параметры:
  @input_string (NVARCHAR(MAX)): Исходная строка для преобразования.

Возвращает:
  NVARCHAR(MAX): Ключ сортировки, который можно использовать для альфанумерической сортировки.
  - Если входная строка NULL, возвращается NULL.

Примеры использования:
  SELECT dbo.alphanum_sort_key('item2');
  -- Результат: 'item000000000000000000000000000002'

  SELECT dbo.alphanum_sort_key('item10');
  -- Результат: 'item000000000000000000000000000010'

  SELECT dbo.alphanum_sort_key(NULL);
  -- Результат: NULL

Особенности:
  - Числовые блоки дополняются ведущими нулями до длины 30 символов.
  - Нечисловые блоки остаются без изменений.
  - Если входная строка NULL, результат также NULL.

Примечание:
  Функция полезна для генерации ключей сортировки, которые сохраняют альфанумерический порядок.
  Это особенно удобно при работе с большими объемами данных, где требуется естественная сортировка.
*/
CREATE OR ALTER FUNCTION dbo.alphanum_sort_key(@input_string NVARCHAR(MAX))
    RETURNS NVARCHAR(MAX)
    AS
BEGIN
    DECLARE @result NVARCHAR(MAX) = ''
    DECLARE @chunk NVARCHAR(MAX)
    DECLARE @remaining_text NVARCHAR(MAX) = ISNULL(@input_string, '')
    DECLARE @num_length INT = 30
    DECLARE @pos INT
    DECLARE @non_num_pos INT

    WHILE LEN(@remaining_text) > 0
BEGIN
            SET @pos = PATINDEX('%[0-9]%', @remaining_text)

            IF @pos = 0
                SET @chunk = @remaining_text
            ELSE IF @pos = 1
BEGIN
                    SET @non_num_pos = PATINDEX('%[^0-9]%', @remaining_text + 'X')
                    SET @chunk = LEFT(@remaining_text, @non_num_pos - 1)
END
ELSE
                SET @chunk = LEFT(@remaining_text, @pos - 1)

            -- Если блок числовой, добавляем ведущие нули
            IF @chunk LIKE '[0-9]%' AND @chunk NOT LIKE '%[^0-9]%'
                SET @result = @result + RIGHT(REPLICATE('0', @num_length) + @chunk, @num_length)
            ELSE
                SET @result = @result + @chunk

            SET @remaining_text = STUFF(@remaining_text, 1, LEN(@chunk), '')
END

RETURN CASE WHEN @input_string IS NULL THEN NULL ELSE @result END
END