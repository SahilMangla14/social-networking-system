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

CREATE OR REPLACE FUNCTION update_follow_request_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    -- Update the updated_at timestamp whenever a row is updated
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER follow_request_updated_at_trigger
    BEFORE UPDATE ON follow_request
    FOR EACH ROW
    EXECUTE FUNCTION update_follow_request_updated_at ();

CREATE OR REPLACE FUNCTION update_user_message_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    -- Update the updated_at timestamp whenever a row is updated
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER user_message_updated_at_trigger
    BEFORE UPDATE ON user_message
    FOR EACH ROW
    EXECUTE FUNCTION update_user_message_updated_at ();

CREATE OR REPLACE FUNCTION update_post_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    -- Update the updated_at timestamp whenever a row is updated
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER post_updated_at_trigger
    BEFORE UPDATE ON post
    FOR EACH ROW
    EXECUTE FUNCTION update_post_updated_at ();

CREATE OR REPLACE FUNCTION update_post_like_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    -- Update the updated_at timestamp whenever a row is updated
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER post_like_updated_at_trigger
    BEFORE UPDATE ON post_like
    FOR EACH ROW
    EXECUTE FUNCTION update_post_like_updated_at ();

CREATE OR REPLACE FUNCTION update_post_comment_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    -- Update the updated_at timestamp whenever a row is updated
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER post_comment_updated_at_trigger
    BEFORE UPDATE ON post_comment
    FOR EACH ROW
    EXECUTE FUNCTION update_post_comment_updated_at ();

CREATE OR REPLACE FUNCTION update_group_message_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    -- Update the updated_at timestamp whenever a row is updated
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER group_message_updated_at_trigger
    BEFORE UPDATE ON group_message
    FOR EACH ROW
    EXECUTE FUNCTION update_group_message_updated_at ();
