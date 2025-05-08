/*
Функция dbo.string_split разделяет строку на подстроки по указанному разделителю.

Описание:
- Функция принимает строку (@string) и символ-разделитель (@simbol).
- Разделяет строку на части, используя указанный разделитель.
- Возвращает таблицу с разделенными частями строки.

Параметры:
  @simbol (nvarchar(1)): Символ-разделитель, по которому разделяется строка.
  @string (nvarchar(max)): Исходная строка, которую нужно разделить.

Возвращает:
  TABLE (value nvarchar(max)):
    - value: Одна из подстрок, полученная после разделения строки.

Примеры использования:
  SELECT * FROM dbo.string_split(',', 'apple,banana,cherry');
  -- Результат:
  -- value
  -- ------
  -- apple
  -- banana
  -- cherry

  SELECT * FROM dbo.string_split(' ', 'Hello World');
  -- Результат:
  -- value
  -- ------
  -- Hello
  -- World

  SELECT * FROM dbo.string_split(',', '');
  -- Результат: Пустая таблица (нет данных для разделения)

Особенности:
  - Если входная строка пустая (''), функция возвращает пустую таблицу.
  - Если разделитель не найден в строке, функция возвращает всю строку как одну запись.
  - Если разделитель равен NULL или строка равна NULL, функция вернет пустую таблицу.

Примечание:
  Функция полезна для разделения строковых данных на отдельные элементы,
  например, при обработке CSV-подобных данных или параметров, переданных в виде строк.
*/
create OR ALTER function dbo.string_split(@simbol nvarchar(1), @string nvarchar(max))
Returns
@Result Table(value nvarchar(max))
AS
Begin
	declare @len int, @loc int = 1
	While @loc <= len(@string)
		Begin
			Set @len = CHARINDEX(@simbol, @string, @loc) - @loc
			If @len < 0 Set @len = len(@string)
Insert Into @Result values(SUBSTRING(@string, @loc, @len))
Set @loc = @loc + @len + 1
		End
		Return
End
go

