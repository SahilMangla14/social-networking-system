CREATE OR REPLACE FUNCTION update_post_count ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Increment post_count when a new post is created
        UPDATE
            user_account
        SET
            post_count = post_count + 1
        WHERE
            id = NEW.user_id;
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrement post_count when a post is deleted
        UPDATE
            user_account
        SET
            post_count = post_count - 1
        WHERE
            id = OLD.user_id;
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_post_count_trigger
    AFTER INSERT OR DELETE ON post
    FOR EACH ROW
    EXECUTE FUNCTION update_post_count ();
