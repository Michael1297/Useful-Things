create OR REPLACE function upd_timestamp() returns trigger
    language plpgsql
as
$$
BEGIN
    NEW.updated = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$;


