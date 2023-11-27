CREATE OR REPLACE FUNCTION create_user (p_first_name text, p_middle_name text, p_last_name text, p_mobile_number varchar(10), p_email text, p_password_hash text, p_bio text)
    RETURNS int
    AS $$
DECLARE
    v_user_id int;
BEGIN
    -- Check if mobile_number and email are unique
    IF EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            mobile_number = p_mobile_number
            OR email = p_email) THEN
    RAISE EXCEPTION 'User with the provided mobile number or email already exists.';
END IF;
    -- Insert new user with optional attributes
    INSERT INTO user_account (first_name, middle_name, last_name, mobile_number, email, password_hash, bio)
        VALUES (p_first_name, p_middle_name, p_last_name, p_mobile_number, p_email, p_password_hash, p_bio)
    RETURNING
        id INTO v_user_id;
    RETURN v_user_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_user (p_id integer)
    RETURNS int
    AS $$
DECLARE
    v_user_id int;
BEGIN
    -- Check if email exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_id) THEN
    RAISE EXCEPTION 'User with the provided id does not exist.';
END IF;
    -- Delete the user from the user_account table
    DELETE FROM user_account
    WHERE id = p_id
    RETURNING id INTO v_user_id;
    
    RETURN v_user_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION make_follow_request (p_source_user_id integer, p_target_user_id integer)
    RETURNS int
    AS $$
DECLARE
    v_request_id int;
BEGIN
    -- Check if source and target users exist
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_source_user_id) THEN
    RAISE EXCEPTION 'Source user does not exist.';
END IF;
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_target_user_id) THEN
    RAISE EXCEPTION 'Target user does not exist.';
END IF;
    -- Check if there is an existing follow request
    IF EXISTS (
        SELECT
            1
        FROM
            follow_request
        WHERE
            source_user_id = p_source_user_id
            AND target_user_id = p_target_user_id) THEN
    RAISE EXCEPTION 'Follow request already exists.';
END IF;
    -- Insert new follow request
    INSERT INTO follow_request (source_user_id, target_user_id, request_status, updated_at)
        VALUES (p_source_user_id, p_target_user_id, 'PENDING', CURRENT_TIMESTAMP)
    RETURNING
        id INTO v_request_id;
    -- Return the ID of the new follow request
    RETURN v_request_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_pending_follow_requests (p_user_id integer)
    RETURNS TABLE (
        request_id int,
        source_user_id int,
        source_user_name text,
        created_at timestamp
    )
    AS $$
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Retrieve pending follow requests
    RETURN QUERY
    SELECT
        fr.id AS request_id,
        fr.source_user_id,
        CONCAT(ua.first_name, ' ', ua.last_name) AS source_user_name,
        fr.created_at
    FROM
        follow_request fr
        JOIN user_account ua ON fr.source_user_id = ua.id
    WHERE
        fr.target_user_id = p_user_id
        AND fr.request_status = 'PENDING';
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION accept_follow_requests (p_user_id integer, p_request_ids integer[])
    RETURNS TABLE (
        request_id int,
        status_text text
    )
    AS $$
DECLARE
    v_request_status status_enum;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RETURN QUERY
VALUES (NULL,
    'User does not exist.');
    RETURN;
END IF;
    -- Loop through the array of request IDs
    FOR request_id IN
    SELECT
        unnest(p_request_ids) AS id LOOP
            -- Check if the follow request exists for the given user
            SELECT
                request_status INTO v_request_status
            FROM
                follow_request
            WHERE
                id = request_id
                AND target_user_id = p_user_id
                AND request_status = 'PENDING';
            IF NOT FOUND THEN
                RETURN QUERY
            VALUES (request_id,
                'Follow request does not exist or is not pending for the user.');
                CONTINUE;
            END IF;
            -- Update the status of the follow request to 'ACCEPTED'
            UPDATE
                follow_request
            SET
                request_status = 'ACCEPTED',
                updated_at = CURRENT_TIMESTAMP
            WHERE
                id = request_id;
            -- Perform any additional actions or notifications if needed
            RETURN QUERY
        VALUES (request_id,
            'Follow request accepted.');
        END LOOP;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_post (p_user_id integer, p_message_text text)
    RETURNS TABLE (
        post_id int
    )
    AS $$
DECLARE
    new_post_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Insert new post
    INSERT INTO post (user_id, message_text, created_at, updated_at)
        VALUES (p_user_id, p_message_text, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING
        id INTO new_post_id;
    -- Update user's post count
    UPDATE
        user_account
    SET
        post_count = post_count + 1
    WHERE
        id = p_user_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_post_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_post (p_post_id integer, p_user_id integer)
    RETURNS TABLE (
        post_id int
    )
    AS $$
DECLARE
    deleted_post_id int;
BEGIN
    -- Check if the post exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post
        WHERE
            id = p_post_id AND user_id = p_user_id) THEN
    RAISE EXCEPTION 'The post which you are trying to delete does not exist.';
END IF;
    -- Delete the post
    DELETE FROM post
    WHERE user_id = p_user_id AND id = p_post_id
    RETURNING
        id INTO deleted_post_id;
    -- Update user's post count
    UPDATE
        user_account
    SET
        post_count = post_count - 1
    WHERE
        id = p_user_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_post_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION like_post (p_user_id integer, p_post_id integer)
    RETURNS TABLE (
        like_id int
    )
    AS $$
DECLARE
    new_like_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the post exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post
        WHERE
            id = p_post_id) THEN
    RAISE EXCEPTION 'Post does not exist.';
END IF;
    -- Check if the user has already liked the post
    IF EXISTS (
        SELECT
            1
        FROM
            post_like
        WHERE
            user_id = p_user_id
            AND post_id = p_post_id) THEN
    RAISE EXCEPTION 'User has already liked the post.';
END IF;
    -- Insert new post like
    INSERT INTO post_like (user_id, post_id, created_at, updated_at)
        VALUES (p_user_id, p_post_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING
        id INTO new_like_id;
    -- Update post's like count
    -- UPDATE post
    -- SET like_count = like_count + 1
    -- WHERE id = p_post_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_like_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION unlike_post (p_post_id integer, p_user_id integer)
    RETURNS TABLE (
        like_id int
    )
    AS $$
DECLARE
    deleted_like_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the post exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post
        WHERE
            id = p_post_id) THEN
    RAISE EXCEPTION 'Post does not exist.';
END IF;
    -- Check if the user has not liked the post
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post_like
        WHERE
            user_id = p_user_id
            AND post_id = p_post_id) THEN
    RAISE EXCEPTION 'User has not liked the post.';
END IF;
    -- Insert new post like
    DELETE FROM post_like
    WHERE user_id = p_user_id AND post_id = p_post_id
    RETURNING id into deleted_like_id;
    -- Update post's like count
    -- UPDATE post
    -- SET like_count = like_count + 1
    -- WHERE id = p_post_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_like_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION comment_on_post (p_user_id integer, p_post_id integer, p_content text)
    RETURNS TABLE (
        comment_id int
    )
    AS $$
DECLARE
    new_comment_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the post exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post
        WHERE
            id = p_post_id) THEN
    RAISE EXCEPTION 'Post does not exist.';
END IF;
    -- Insert new comment
    INSERT INTO post_comment (content, post_id, author_user_id, created_at, updated_at)
        VALUES (p_content, p_post_id, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING
        id INTO new_comment_id;
    -- Update post's comment count
    -- UPDATE post
    -- SET comment_count = comment_count + 1
    -- WHERE id = p_post_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_comment_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_comment_on_post (p_comment_id integer, p_post_id integer, p_user_id integer)
    RETURNS TABLE (
        comment_id int
    )
    AS $$
DECLARE
    deleted_comment_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the post exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post
        WHERE
            id = p_post_id) THEN
    RAISE EXCEPTION 'Post does not exist.';
END IF;
    -- Check if the comment exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            post_comment
        WHERE
            id = p_comment_id) THEN
    RAISE EXCEPTION 'Comment does not exist.';
END IF;
    -- Delete the comment
    DELETE FROM post_comment
    WHERE id = p_comment_id AND post_id = p_post_id AND author_user_id = p_user_id
    RETURNING
        id INTO deleted_comment_id;
    -- Update post's comment count
    -- UPDATE post
    -- SET comment_count = comment_count + 1
    -- WHERE id = p_post_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_comment_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION message_friend (p_source_user_id integer, p_target_user_id integer, p_message_text text)
    RETURNS TABLE (
        message_id int
    )
    AS $$
DECLARE
    new_message_id int;
BEGIN
    -- Check if the source user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_source_user_id) THEN
    RAISE EXCEPTION 'Source user does not exist.';
END IF;
    -- Check if the target user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_target_user_id) THEN
    RAISE EXCEPTION 'Target user does not exist.';
END IF;
    -- Check if the follow request has been accepted
    IF NOT EXISTS (
        SELECT
            1
        FROM
            follow_request
        WHERE
            source_user_id = p_source_user_id
            AND target_user_id = p_target_user_id
            AND request_status = 'ACCEPTED') THEN
    RAISE EXCEPTION 'Follow request has not been accepted. Cannot send a message.';
END IF;
    -- Insert new message
    INSERT INTO user_message (source_user_id, target_user_id, message_text, created_at, updated_at)
        VALUES (p_source_user_id, p_target_user_id, p_message_text, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING
        id INTO new_message_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_message_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_message_friend (p_message_id integer, p_user_id integer)
    RETURNS TABLE (
        message_id int
    )
    AS $$
DECLARE
    deleted_message_id int;
BEGIN
    -- Check if the message exists
    IF NOT EXISTS (
        SELECT 1
        FROM user_message
        WHERE id = p_message_id
    ) THEN RAISE EXCEPTION 'The message does not exist.';
END IF;   
    -- Delete the message
    DELETE FROM user_message
    WHERE id = p_message_id AND source_user_id = p_user_id
    RETURNING
        id INTO deleted_message_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_message_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_user_group (p_created_by_user_id integer, p_title varchar(50), p_summary text)
    RETURNS TABLE (
        group_id int
    )
    AS $$
DECLARE
    new_group_id int;
BEGIN
    -- Check if the creating user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_created_by_user_id) THEN
    RAISE EXCEPTION 'Creating user does not exist.';
END IF;
    -- Insert new user group
    INSERT INTO user_group (created_by_user_id, title, summary, created_at, updated_at)
        VALUES (p_created_by_user_id, p_title, p_summary, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING
        id INTO new_group_id;
    -- Insert the creating user as a member of the group
    INSERT INTO group_member (group_id, user_id, joined_at)
        VALUES (new_group_id, p_created_by_user_id, CURRENT_TIMESTAMP);
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_group_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_user_group (p_group_id integer, p_user_id integer)
    RETURNS TABLE (
        group_id int
    )
    AS $$
DECLARE
    deleted_group_id int;
BEGIN
    -- Check if the group exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_group
        WHERE
            id = p_group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
END IF;
    -- Check if the creating user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    DELETE FROM user_group
    WHERE id = group_id AND created_by_user_id = p_user_id
    RETURNING
        id INTO deleted_group_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_group_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION message_in_group (p_user_id integer, p_group_id integer, p_message_text text)
    RETURNS TABLE (
        message_id int
    )
    AS $$
DECLARE
    new_message_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the group exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_group
        WHERE
            id = p_group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
END IF;
    -- Check if the user is a member of the group
    IF NOT EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = p_user_id) THEN
    RAISE EXCEPTION 'User is not a member of the group. Cannot send a message.';
END IF;
    -- Insert new group message
    INSERT INTO group_message (group_id, user_id, message_text, created_at, updated_at)
        VALUES (p_group_id, p_user_id, p_message_text, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING
        id INTO new_message_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_message_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_message_in_group (p_message_id integer, p_group_id integer, p_user_id integer)
    RETURNS TABLE (
        message_id int
    )
    AS $$
DECLARE
    deleted_message_id int;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the group exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_group
        WHERE
            id = p_group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
END IF;
    -- Check if the user is a member of the group
    IF NOT EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = p_user_id) THEN
    RAISE EXCEPTION 'User is not a member of the group. Cannot delete a message.';
END IF;
    DELETE FROM group_message
    WHERE id = p_message_id AND group_id = p_group_id AND user_id = p_user_id
    RETURNING
        id INTO deleted_message_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_message_id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION view_group_messages (p_user_id integer, p_group_id integer)
    RETURNS TABLE (
        message_id int,
        mes_user_id int,
        user_name text,
        message_text text,
        created_at timestamp
    )
    AS $$
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Check if the group exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_group
        WHERE
            id = p_group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
END IF;
    -- Check if the user is a member of the group
    IF NOT EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = p_user_id) THEN
    RAISE EXCEPTION 'User is not a member of the group. Cannot view messages.';
END IF;
    -- Retrieve group messages
    RETURN QUERY
    SELECT
        gm.id AS message_id,
        gm.user_id,
        CONCAT(ua.first_name, ' ', ua.last_name) AS user_name,
        gm.message_text,
        gm.created_at
    FROM
        group_message gm
        JOIN user_account ua ON gm.user_id = ua.id
    WHERE
        gm.group_id = p_group_id
    ORDER BY
        gm.created_at;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_members_to_group (p_creator_user_id integer, p_group_id integer, p_member_ids integer[])
    RETURNS TABLE (
        member_id int
    )
    AS $$
DECLARE
    new_member_id int;
BEGIN
    -- Check if the creator user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_creator_user_id) THEN
    RAISE EXCEPTION 'Creator user does not exist.';
END IF;
    -- Check if the group exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_group
        WHERE
            id = p_group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
END IF;
    -- Check only members of group can add other members
    IF NOT EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = p_creator_user_id) THEN
    RAISE EXCEPTION 'Only Members of group can add other members';
END IF;
    -- Loop through the array of member IDs
    FOR member_id IN
    SELECT
        unnest(p_member_ids) AS id LOOP
            -- Check if the member user exists
            IF NOT EXISTS (
                SELECT
                    1
                FROM
                    user_account
                WHERE
                    id = member_id) THEN
            RAISE EXCEPTION 'User with ID % does not exist.', member_id;
        END IF;
    -- Check if the member is not already in the group
    IF EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = member_id) THEN
    RAISE EXCEPTION 'User with ID % is already a member of the group.', member_id;
END IF;
    -- Insert new group member
    INSERT INTO group_member (group_id, user_id, joined_at)
        VALUES (p_group_id, member_id, CURRENT_TIMESTAMP)
    RETURNING
        user_id INTO new_member_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        new_member_id;
END LOOP;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_members_from_group (p_member_ids integer[], p_group_id integer, p_creator_user_id integer)
    RETURNS TABLE (
        member_id int
    )
    AS $$
DECLARE
    deleted_member_id int;
BEGIN
    -- Check if the creator user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_creator_user_id) THEN
    RAISE EXCEPTION 'Creator user does not exist.';
END IF;
    -- Check if the group exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_group
        WHERE
            id = p_group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
END IF;
    -- Check only members of group can add other members
    IF NOT EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = p_creator_user_id) THEN
    RAISE EXCEPTION 'Only members of group can delete other members';
END IF;
    -- Loop through the array of member IDs
    FOR member_id IN
    SELECT
        unnest(p_member_ids) AS id LOOP
            -- Check if the member user exists
            IF NOT EXISTS (
                SELECT
                    1
                FROM
                    user_account
                WHERE
                    id = member_id) THEN
            RAISE EXCEPTION 'User with ID % does not exist.', member_id;
        END IF;
    -- Check if the member is not in the group
    IF NOT EXISTS (
        SELECT
            1
        FROM
            group_member
        WHERE
            group_id = p_group_id
            AND user_id = member_id) THEN
    RAISE EXCEPTION 'User with ID % is not a member of the group.', member_id;
END IF;
    -- Delete the group member
    DELETE FROM group_member
    WHERE group_id = p_group_id AND user_id = member_id
    RETURNING
        user_id INTO deleted_member_id;
    -- Perform any additional actions or notifications if needed
    RETURN QUERY
    SELECT
        deleted_member_id;
END LOOP;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION view_user_posts (p_user_id integer)
    RETURNS TABLE (
        user_post_id int,
        message_text text,
        created_at timestamp,
        like_count bigint,
        comment_count bigint
    )
    AS $$
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Retrieve user posts along with like and comment counts
    RETURN QUERY
    SELECT
        p.id AS user_post_id,
        p.message_text,
        p.created_at::timestamp, -- Ensure the correct casting to timestamp
        COALESCE(plike.like_count, 0)::bigint AS like_count,
        COALESCE(pcomment.comment_count, 0)::bigint AS comment_count
    FROM
        post p
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS like_count
        FROM
            post_like
        GROUP BY
            post_id) plike ON p.id = plike.post_id
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS comment_count
        FROM
            post_comment
        GROUP BY
            post_id) pcomment ON p.id = pcomment.post_id
WHERE
    p.user_id = p_user_id
ORDER BY
    p.created_at DESC;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_followers (p_user_id integer)
    RETURNS TABLE (
        follower_user_id int,
        follower_first_name text,
        follower_last_name text,
        follower_mobile_number varchar(10),
        follower_email text
    )
    AS $$
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Retrieve followers of the user
    RETURN QUERY
    SELECT
        fr.source_user_id AS follower_user_id,
        ua.first_name AS follower_first_name,
        ua.last_name AS follower_last_name,
        ua.mobile_number AS follower_mobile_number,
        ua.email AS follower_email
    FROM
        follow_request fr
        JOIN user_account ua ON fr.source_user_id = ua.id
    WHERE
        fr.target_user_id = p_user_id
        AND fr.request_status = 'ACCEPTED';
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_posts_of_other_user (p_viewer_user_id integer, p_other_user_id integer)
    RETURNS TABLE (
        new_post_id int,
        message_text text,
        created_at timestamp,
        user_id int,
        first_name text,
        last_name text,
        like_count bigint,
        comment_count bigint
    )
    AS $$
BEGIN
    -- Check if the viewer user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_viewer_user_id) THEN
    RAISE EXCEPTION 'Viewer user does not exist.';
END IF;
    -- Check if the other user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_other_user_id) THEN
    RAISE EXCEPTION 'Other user does not exist.';
END IF;
    -- Check if there is an accepted follow request between viewer and other user
    IF NOT EXISTS (
        SELECT
            1
        FROM
            follow_request
        WHERE
            source_user_id = p_viewer_user_id
            AND target_user_id = p_other_user_id
            AND request_status = 'ACCEPTED') THEN
    RAISE EXCEPTION 'Viewer user is not allowed to view posts of the other user.';
END IF;
    -- Retrieve posts of the other user along with user details and like/comment counts
    RETURN QUERY
    SELECT
        p.id AS new_post_id,
        p.message_text,
        p.created_at,
        ua.id AS user_id,
        ua.first_name,
        ua.last_name,
        COALESCE(plike.like_count, 0)::bigint AS like_count,
        COALESCE(pcomment.comment_count, 0)::bigint AS comment_count
    FROM
        post p
        JOIN user_account ua ON p.user_id = ua.id
        LEFT JOIN (
            SELECT
                post_id,
                COUNT(*) AS like_count
            FROM
                post_like
            GROUP BY
                post_id) plike ON p.id = plike.post_id
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS comment_count
        FROM
            post_comment
        GROUP BY
            post_id) pcomment ON p.id = pcomment.post_id
WHERE
    p.user_id = p_other_user_id
ORDER BY
    p.created_at DESC;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION who_to_follow (p_user_id int)
    RETURNS TABLE (
        user_id int,
        first_name text,
        last_name text,
        mobile_number varchar(10),
        email text,
        bio text
    )
    AS $$
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    RETURN QUERY SELECT DISTINCT
        u.id AS user_id,
        u.first_name,
        u.last_name,
        u.mobile_number,
        u.email,
        u.bio
    FROM
        post p
        JOIN post_comment pc ON p.id = pc.post_id
        JOIN user_account u ON pc.author_user_id = u.id
    WHERE
        p.user_id = p_user_id
        AND u.id != p_user_id;
    RETURN;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION view_post_feed (p_user_id integer)
    RETURNS TABLE (
        feed_post_id int,
        creator_id int,
        message_text text,
        created_at timestamp,
        like_count bigint,
        comment_count bigint
    )
    AS $$
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (
        SELECT
            1
        FROM
            user_account
        WHERE
            id = p_user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
END IF;
    -- Retrieve user posts along with like and comment counts
    RETURN QUERY
    SELECT
        p.id AS feed_post_id,
        p.user_id as creator_id,
        p.message_text,
        p.created_at::timestamp, -- Ensure the correct casting to timestamp
        COALESCE(plike.like_count, 0)::bigint AS like_count,
        COALESCE(pcomment.comment_count, 0)::bigint AS comment_count
    FROM
        post p
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS like_count
        FROM
            post_like
        GROUP BY
            post_id) plike ON p.id = plike.post_id
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS comment_count
        FROM
            post_comment
        GROUP BY
            post_id) pcomment ON p.id = pcomment.post_id
WHERE
    p.user_id IN 
                (
                    SELECT source_user_id
                    FROM follow_request
                    WHERE p_user_id = target_user_id and request_status='ACCEPTED'
                )
                OR 
    p.user_id IN 
                (
                    SELECT target_user_id
                    FROM follow_request
                    WHERE p_user_id = source_user_id 
                )
ORDER BY
    p.created_at DESC;
END;
$$
LANGUAGE plpgsql;
