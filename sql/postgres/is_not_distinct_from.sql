CREATE OR REPLACE FUNCTION is_not_distinct_from(anyelement, anyelement)
RETURNS BOOLEAN AS $$
SELECT $1 IS NOT DISTINCT FROM $2;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

COMMENT ON FUNCTION is_not_distinct_from(anyelement, anyelement) IS
    'Сравнивает два значения, включая NULL. Возвращает TRUE, если значения равны или оба NULL.
    Аналог оператора IS NOT DISTINCT FROM, но используется для пользовательского оператора <=>';




CREATE OPERATOR <=> (
    LEFTARG = anyelement,
    RIGHTARG = anyelement,
    PROCEDURE = public.is_not_distinct_from
    );

COMMENT ON OPERATOR <=> (anyelement, anyelement) IS
    'Пользовательский оператор сравнения, эквивалентен "IS NOT DISTINCT FROM".
    Возвращает TRUE, если оба значения равны или оба являются NULL.
    Поддерживает типы text, citext, integer, date и другие.';
