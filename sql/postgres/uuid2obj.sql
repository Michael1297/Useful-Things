CREATE OR REPLACE FUNCTION uuid2obj(uuid uuid)
    RETURNS text AS
$$
BEGIN
    RETURN replace(uuid::text, '-', '');
END;
$$ LANGUAGE plpgsql IMMUTABLE;


COMMENT ON FUNCTION uuid2obj(uuid) IS
'Преобразует UUID в строку без дефисов.';
