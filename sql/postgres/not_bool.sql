CREATE OR REPLACE FUNCTION public.not_bool(boolean)
RETURNS boolean AS $$
SELECT NOT $1;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

-- Добавляем комментарий к функции
COMMENT ON FUNCTION public.not_bool(boolean) IS
'Унарная функция, реализующая логическое НЕ (NOT).
Используется для поддержки пользовательского оператора "!".
Возвращает TRUE, если входное значение FALSE,
FALSE — если входное значение TRUE,
NULL — если входное значение NULL.';

-- Создаем пользовательский префиксный оператор "!"
CREATE OPERATOR public.! (
    PROCEDURE = public.not_bool,
    RIGHTARG = boolean
);

-- Добавляем комментарий к оператору
COMMENT ON OPERATOR public.! (NONE, boolean) IS
'Пользовательский унарный оператор "!", эквивалентен ключевому слову NOT в SQL.
Примеры:
  !true        => false
  !(a IS NULL) => a IS NOT NULL';