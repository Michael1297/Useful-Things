/*
Функция kmp_search выполняет поиск всех вхождений подстроки (@needle) в строку (@haystack)
с использованием алгоритма Кнута-Морриса-Пратта (KMP).

Описание:
- Функция использует префиксную функцию (prefix function) для эффективного поиска подстроки.
- Алгоритм KMP обеспечивает линейную сложность O(m + n), где:
  - m — длина строки @haystack;
  - n — длина подстроки @needle.
- Результат возвращается в виде таблицы с позициями начала каждого вхождения.

Параметры:
  @haystack (NVARCHAR(MAX)): Строка, в которой выполняется поиск. Если NULL, считается пустой строкой ('').
  @needle (NVARCHAR(MAX)): Подстрока, которую нужно найти. Если NULL, считается пустой строкой ('').

Возвращает:
  TABLE (match_position INT):
    - match_position: Позиция (индекс), с которой начинается вхождение @needle в @haystack.
      Индексация начинается с 1.

Примеры использования:
  SELECT * FROM kmp_search('abracadabra', 'abra');
  -- Результат: match_position = 1, 8

  SELECT * FROM kmp_search('hello world', 'world');
  -- Результат: match_position = 7

  SELECT * FROM kmp_search('test', '');
  -- Результат: Пустая таблица (пустая подстрока не ищется)

  SELECT * FROM kmp_search(NULL, 'abra');
  -- Результат: Пустая таблица (пустая строка haystack)

Особенности:
  - Если @needle пустая строка, функция возвращает пустую таблицу без ошибок.
  - Если @haystack пустая строка, функция также возвращает пустую таблицу.
  - NULL значения для @haystack и @needle автоматически преобразуются в пустые строки ('').

Примечание:
  Функция полезна для поиска всех вхождений подстроки в строку с высокой производительностью,
  особенно при работе с большими объемами данных.
*/
CREATE OR ALTER FUNCTION kmp_search(@haystack NVARCHAR(MAX), @needle NVARCHAR(MAX))
    RETURNS @results TABLE (match_position INT)
AS
BEGIN
    DECLARE @m INT = ISNULL(LEN(@haystack), 0);
    DECLARE @n INT;
    DECLARE @pi TABLE (idx INT, val INT);
    DECLARE @q INT = 0;
    DECLARE @i INT;
    DECLARE @j INT;

    -- Если needle равен NULL, считаем его пустой строкой
    IF @needle IS NULL
        SET @needle = '';

    -- Если haystack равен NULL, считаем его пустой строкой
    IF @haystack IS NULL
        SET @haystack = '';

    SET @n = LEN(@needle);

    -- Проверяем, что иголка не пустая
    IF @n = 0
        BEGIN
            -- Просто возвращаем пустой результат без сообщения
            RETURN;
        END;

    -- Инициализация таблицы префиксной функции
    DECLARE @k INT = 1;
    WHILE @k <= @n
        BEGIN
            INSERT INTO @pi VALUES (@k, 0);
            SET @k = @k + 1;
        END;

    -- Вычисляем префиксную функцию для иголки
    SET @j = 1;
    WHILE @j < @n
        BEGIN
            WHILE @q > 0 AND SUBSTRING(@needle, @q + 1, 1) <> SUBSTRING(@needle, @j + 1, 1)
                SELECT @q = val FROM @pi WHERE idx = @q;

            IF SUBSTRING(@needle, @q + 1, 1) = SUBSTRING(@needle, @j + 1, 1)
                SET @q = @q + 1;

            UPDATE @pi SET val = @q WHERE idx = @j + 1;
            SET @j = @j + 1;
        END;

    -- Основной цикл поиска подстроки в строке
    SET @q = 0;
    SET @i = 1;
    WHILE @i <= @m
        BEGIN
            WHILE @q > 0 AND SUBSTRING(@needle, @q + 1, 1) <> SUBSTRING(@haystack, @i, 1)
                SELECT @q = val FROM @pi WHERE idx = @q;

            IF SUBSTRING(@needle, @q + 1, 1) = SUBSTRING(@haystack, @i, 1)
                SET @q = @q + 1;

            IF @q = @n
                BEGIN
                    -- Возвращаем позицию начала совпадения
                    INSERT INTO @results VALUES (@i - @n + 1);
                    SELECT @q = val FROM @pi WHERE idx = @q;
                END;

            SET @i = @i + 1;
        END;

    RETURN;
END;