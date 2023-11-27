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

CREATE OR REPLACE FUNCTION update_follower_count ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.request_status = 'ACCEPTED' AND OLD.request_status <> 'ACCEPTED' THEN
        -- Increment follower_count when a follow request is accepted
        UPDATE
            user_account
        SET
            follower_count = follower_count + 1
        WHERE
            id = NEW.target_user_id;
    ELSIF TG_OP = 'UPDATE'
            AND NEW.request_status <> 'ACCEPTED'
            AND OLD.request_status = 'ACCEPTED' THEN
            -- Decrement follower_count when a follow request is no longer accepted
            UPDATE
                user_account
            SET
                follower_count = follower_count - 1
            WHERE
                id = OLD.target_user_id;
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_follower_count_trigger
    AFTER UPDATE ON follow_request
    FOR EACH ROW
    EXECUTE FUNCTION update_follower_count ();

CREATE OR REPLACE FUNCTION update_following_count ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.request_status = 'ACCEPTED' AND OLD.request_status <> 'ACCEPTED' THEN
        -- Increment following_count when a follow request is accepted
        UPDATE
            user_account
        SET
            following_count = following_count + 1
        WHERE
            id = NEW.source_user_id;
    ELSIF TG_OP = 'UPDATE'
            AND NEW.request_status <> 'ACCEPTED'
            AND OLD.request_status = 'ACCEPTED' THEN
            -- Decrement following_count when a follow request is no longer accepted
            UPDATE
                user_account
            SET
                following_count = following_count - 1
            WHERE
                id = OLD.source_user_id;
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_following_count_trigger
    AFTER UPDATE ON follow_request
    FOR EACH ROW
    EXECUTE FUNCTION update_following_count ();
