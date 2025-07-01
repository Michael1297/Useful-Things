CREATE OR REPLACE FUNCTION public.distinct_from_not_eq(anyelement, anyelement)
RETURNS boolean AS $$
SELECT $1 IS DISTINCT FROM $2;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

COMMENT ON FUNCTION public.distinct_from_not_eq(anyelement, anyelement) IS
    'Проверяет, различаются ли два значения, включая NULL.
    Возвращает TRUE, если значения различаются или одно из них NULL, а другое нет.
    Аналог стандартного выражения "IS DISTINCT FROM".';

CREATE OPERATOR public.<!=> (
    LEFTARG = anyelement,
    RIGHTARG = anyelement,
    PROCEDURE = public.distinct_from_not_eq
    );


COMMENT ON OPERATOR public.<!=> (anyelement, anyelement) IS
    'Пользовательский оператор сравнения <!=>.
    Означает "значения различаются с учётом NULL", аналог "IS DISTINCT FROM".
    Примеры:
      a <!=> b → TRUE, если a ≠ b или одно из них NULL, а другое — нет.';