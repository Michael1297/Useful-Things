CREATE OR REPLACE FUNCTION uuid2obj(uuid uuid)
RETURNS text AS $$
SELECT translate($1::text, '-', '');
$$ LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE;


COMMENT ON FUNCTION uuid2obj(uuid) IS
'Преобразует UUID в строку без дефисов.';
