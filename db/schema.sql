DO $$
BEGIN
    IF NOT EXISTS (
        SELECT
            1
        FROM
            pg_type
        WHERE
            typname = 'status_enum') THEN
    CREATE TYPE status_enum AS ENUM (
        'PENDING',
        'ACCEPTED',
        'REJECTED'
);
END IF;
END
$$;

CREATE TABLE IF NOT EXISTS user_account (
    id serial PRIMARY KEY,
    first_name text,
    middle_name text,
    last_name text,
    mobile_number varchar(10) UNIQUE NOT NULL,
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    registered_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp,
    bio text,
    post_count integer NOT NULL DEFAULT 0,
    follower_count integer NOT NULL DEFAULT 0,
    following_count integer NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS follow_request (
    id serial PRIMARY KEY,
    source_user_id integer NOT NULL,
    target_user_id integer NOT NULL,
    request_status status_enum NOT NULL DEFAULT 'PENDING',
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (source_user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS user_message (
    id serial PRIMARY KEY,
    source_user_id integer NOT NULL,
    target_user_id integer NOT NULL,
    message_text text,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (source_user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS post (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    message_text text,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS post_like (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    post_id integer NOT NULL,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (post_id) REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS post_comment (
    id serial PRIMARY KEY,
    content text NOT NULL,
    post_id integer NOT NULL,
    author_user_id integer NOT NULL,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (author_user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS user_group (
    id serial PRIMARY KEY,
    created_by_user_id integer NOT NULL,
    title varchar(50) NOT NULL,
    summary text,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS group_member (
    id serial PRIMARY KEY,
    group_id integer NOT NULL,
    user_id integer NOT NULL,
    joined_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES user_group (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS group_message (
    id serial PRIMARY KEY,
    group_id integer NOT NULL,
    user_id integer NOT NULL,
    message_text text,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (group_id) REFERENCES user_group (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS follow_request_source_user_id_target_user_id_key ON follow_request (source_user_id, target_user_id);

CREATE INDEX IF NOT EXISTS user_message_source_user_id_idx ON user_message (source_user_id);

CREATE INDEX IF NOT EXISTS user_message_target_user_id_idx ON user_message (target_user_id);

CREATE INDEX IF NOT EXISTS post_user_id_idx ON post (user_id);

CREATE INDEX IF NOT EXISTS post_like_user_id_idx ON post_like (user_id);

CREATE INDEX IF NOT EXISTS post_like_post_id_idx ON post_like (post_id);

CREATE UNIQUE INDEX IF NOT EXISTS post_like_user_id_post_id_key ON post_like (user_id, post_id);

CREATE INDEX IF NOT EXISTS post_comment_post_id_idx ON post_comment (post_id);

CREATE INDEX IF NOT EXISTS post_comment_author_user_id_idx ON post_comment (author_user_id);

CREATE INDEX IF NOT EXISTS user_group_created_by_user_id_idx ON user_group (created_by_user_id);

CREATE INDEX IF NOT EXISTS group_member_group_id_idx ON group_member (group_id);

CREATE INDEX IF NOT EXISTS group_member_user_id_idx ON group_member (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS group_member_group_id_user_id_key ON group_member (group_id, user_id);

CREATE INDEX IF NOT EXISTS group_message_group_id_idx ON group_message (group_id);

CREATE INDEX IF NOT EXISTS group_message_user_id_idx ON group_message (user_id);
