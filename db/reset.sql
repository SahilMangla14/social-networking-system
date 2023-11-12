-- Drop foreign key constraints
ALTER TABLE IF EXISTS group_message
    DROP CONSTRAINT IF EXISTS group_message_user_id_fk,
    DROP CONSTRAINT IF EXISTS group_message_group_id_fk;

ALTER TABLE IF EXISTS group_member
    DROP CONSTRAINT IF EXISTS group_member_group_id_fk,
    DROP CONSTRAINT IF EXISTS group_member_user_id_fk;

ALTER TABLE IF EXISTS user_group
    DROP CONSTRAINT IF EXISTS user_group_created_by_user_id_fk;

ALTER TABLE IF EXISTS post_comment
    DROP CONSTRAINT IF EXISTS post_comment_post_id_fk,
    DROP CONSTRAINT IF EXISTS post_comment_author_user_id_fk;

ALTER TABLE IF EXISTS post_like
    DROP CONSTRAINT IF EXISTS post_like_post_id_fk,
    DROP CONSTRAINT IF EXISTS post_like_user_id_fk;

ALTER TABLE IF EXISTS post
    DROP CONSTRAINT IF EXISTS post_user_id_fk;

ALTER TABLE IF EXISTS user_message
    DROP CONSTRAINT IF EXISTS user_message_source_user_id_fk,
    DROP CONSTRAINT IF EXISTS user_message_target_user_id_fk;

ALTER TABLE IF EXISTS follow_request
    DROP CONSTRAINT IF EXISTS follow_request_source_user_id_fk,
    DROP CONSTRAINT IF EXISTS follow_request_target_user_id_fk;

-- Drop tables and type
DROP TABLE IF EXISTS group_message CASCADE;

DROP TABLE IF EXISTS group_member CASCADE;

DROP TABLE IF EXISTS user_group CASCADE;

DROP TABLE IF EXISTS post_comment CASCADE;

DROP TABLE IF EXISTS post_like CASCADE;

DROP TABLE IF EXISTS post CASCADE;

DROP TABLE IF EXISTS user_message CASCADE;

DROP TABLE IF EXISTS follow_request CASCADE;

DROP TABLE IF EXISTS user_account CASCADE;

DROP TYPE IF EXISTS status_enum;

-- Drop indexes
DROP INDEX IF EXISTS group_message_user_id_idx;

DROP INDEX IF EXISTS group_message_group_id_idx;

DROP INDEX IF EXISTS group_member_group_id_user_id_key;

DROP INDEX IF EXISTS group_member_user_id_idx;

DROP INDEX IF EXISTS group_member_group_id_idx;

DROP INDEX IF EXISTS user_group_created_by_user_id_idx;

DROP INDEX IF EXISTS post_comment_author_user_id_idx;

DROP INDEX IF EXISTS post_comment_post_id_idx;

DROP INDEX IF EXISTS post_like_user_id_post_id_key;

DROP INDEX IF EXISTS post_like_post_id_idx;

DROP INDEX IF EXISTS post_like_user_id_idx;

DROP INDEX IF EXISTS post_user_id_idx;

DROP INDEX IF EXISTS user_message_target_user_id_idx;

DROP INDEX IF EXISTS user_message_source_user_id_idx;

DROP INDEX IF EXISTS follow_request_source_user_id_target_user_id_key;

-- Drop functions
DROP FUNCTION IF EXISTS create_user;
