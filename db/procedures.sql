CREATE OR REPLACE FUNCTION create_user(
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  mobile VARCHAR(10),
  email VARCHAR(50),
  password_hash VARCHAR(32),
  bio TEXT DEFAULT NULL,
  middle_name VARCHAR(50) DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
  user_id INT;
BEGIN
  -- Check if the email or mobile is already in use
  IF EXISTS (SELECT 1 FROM "User" WHERE "email" = email) THEN
    RAISE EXCEPTION 'Email is already in use.';
  END IF;

  IF EXISTS (SELECT 1 FROM "User" WHERE "mobile" = mobile) THEN
    RAISE EXCEPTION 'Mobile number is already in use.';
  END IF;

  -- Insert the new user
  INSERT INTO "User"("firstName", "middleName", "lastName", "mobile", "email", "passwordHash", "bio")
  VALUES (first_name, middle_name, last_name, mobile, email, password_hash, bio)
  RETURNING "id" INTO user_id;

  RETURN user_id;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION make_follow_request(
  source_user_id INT,
  target_user_id INT
)
RETURNS VOID AS $$
DECLARE
  request_id INT;
BEGIN
  -- Check if the source user and target user exist
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = source_user_id) THEN
    RAISE EXCEPTION 'Source user does not exist.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = target_user_id) THEN
    RAISE EXCEPTION 'Target user does not exist.';
  END IF;

  -- Check if a follow request from the source to the target user already exists
  IF EXISTS (SELECT 1 FROM "FollowRequest" WHERE "sourceId" = source_user_id AND "targetId" = target_user_id) THEN
    RAISE EXCEPTION 'A follow request from source to target already exists.';
  END IF;

  -- Insert the follow request with status 'PENDING'
  INSERT INTO "FollowRequest"("sourceId", "targetId")
  VALUES (source_user_id, target_user_id)
  RETURNING "id" INTO request_id;

END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION get_pending_follow_requests(user_id INT)
RETURNS TABLE (
  request_id INT,
  source_user_id INT,
  target_user_id INT,
  created_at TIMESTAMP(3)
) AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Retrieve pending follow requests
  RETURN QUERY
  SELECT
    "id" AS request_id,
    "sourceId" AS source_user_id,
    "targetId" AS target_user_id,
    "createdAt" AS created_at
  FROM "FollowRequest"
  WHERE "targetId" = user_id AND "status" = 'PENDING';

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION accept_specific_follow_requests(user_id INT, request_ids INT[])
RETURNS VOID AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Update the status of selected pending follow requests to 'ACCEPTED'
  UPDATE "FollowRequest"
  SET "status" = 'ACCEPTED', "updatedAt" = now()
  WHERE "targetId" = user_id AND "status" = 'PENDING' AND "id" = ANY(request_ids);

  -- Check if any requests were updated, and raise an exception if none were found
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No matching pending follow requests found for the user.';
  END IF;

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_post_by_user(
  user_id INT,
  post_message TEXT
)
RETURNS INT AS $$
DECLARE
  post_id INT;
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Insert the post
  INSERT INTO "Post"("userId", "message")
  VALUES (user_id, post_message)
  RETURNING "id" INTO post_id;

  -- Increment the user's post count
  UPDATE "User"
  SET "postCount" = "postCount" + 1
  WHERE "id" = user_id;

  RETURN post_id;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION like_post_by_user(
  user_id INT,
  post_id INT
)
RETURNS VOID AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Check if the post exists
  IF NOT EXISTS (SELECT 1 FROM "Post" WHERE "id" = post_id) THEN
    RAISE EXCEPTION 'Post does not exist.';
  END IF;

  -- Check if the user has already liked the post
  IF EXISTS (SELECT 1 FROM "Like" WHERE "userId" = user_id AND "postId" = post_id) THEN
    RAISE EXCEPTION 'User has already liked the post.';
  END IF;

  -- Insert the like
  INSERT INTO "Like"("userId", "postId")
  VALUES (user_id, post_id);

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION comment_on_post_by_user(
  user_id INT,
  post_id INT,
  comment_content TEXT
)
RETURNS VOID AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Check if the post exists
  IF NOT EXISTS (SELECT 1 FROM "Post" WHERE "id" = post_id) THEN
    RAISE EXCEPTION 'Post does not exist.';
  END IF;

  -- Insert the comment
  INSERT INTO "Comment"("content", "postId", "authorId")
  VALUES (comment_content, post_id, user_id);

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION message_friend(
  sender_id INT,
  recipient_id INT,
  message_text TEXT
)
RETURNS VOID AS $$
BEGIN
  -- Check if the sender and recipient users exist
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = sender_id) THEN
    RAISE EXCEPTION 'Sender user does not exist.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = recipient_id) THEN
    RAISE EXCEPTION 'Recipient user does not exist.';
  END IF;

  -- Check if there is an accepted follow request from the sender to the recipient
  IF NOT EXISTS (
    SELECT 1
    FROM "FollowRequest"
    WHERE "sourceId" = sender_id
    AND "targetId" = recipient_id
    AND "status" = 'ACCEPTED'
  ) THEN
    RAISE EXCEPTION 'The follow request from sender to recipient is not accepted.';
  END IF;

  -- Insert the message
  INSERT INTO "Message"("sourceId", "targetId", "message")
  VALUES (sender_id, recipient_id, message_text);

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION create_group_by_user(
  creator_id INT,
  group_subject VARCHAR(50),
  group_description TEXT
)
RETURNS INT AS $$
DECLARE
  group_id INT;
BEGIN
  -- Check if the creator user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = creator_id) THEN
    RAISE EXCEPTION 'Creator user does not exist.';
  END IF;

  -- Insert the group
  INSERT INTO "Group"("createdBy", "subject", "description")
  VALUES (creator_id, group_subject, group_description)
  RETURNING "id" INTO group_id;

  RETURN group_id;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION message_in_group(
  user_id INT,
  group_id INT,
  message_text TEXT
)
RETURNS VOID AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Check if the group exists
  IF NOT EXISTS (SELECT 1 FROM "Group" WHERE "id" = group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
  END IF;

  -- Check if the user is a member of the group
  IF NOT EXISTS (
    SELECT 1
    FROM "GroupMember"
    WHERE "userId" = user_id
    AND "groupId" = group_id
  ) THEN
    RAISE EXCEPTION 'User is not a member of the group.';
  END IF;

  -- Insert the message in the group
  INSERT INTO "GroupMessage"("groupId", "userId", "message")
  VALUES (group_id, user_id, message_text);

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION view_messages_in_group(
  user_id INT,
  group_id INT
)
RETURNS TABLE (
  message_id INT,
  user_id INT,
  message_text TEXT,
  created_at TIMESTAMP(3)
) AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Check if the group exists
  IF NOT EXISTS (SELECT 1 FROM "Group" WHERE "id" = group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
  END IF;

  -- Check if the user is a member of the group
  IF NOT EXISTS (
    SELECT 1
    FROM "GroupMember"
    WHERE "userId" = user_id
    AND "groupId" = group_id
  ) THEN
    RAISE EXCEPTION 'User is not a member of the group.';
  END IF;

  -- Retrieve messages in the group
  RETURN QUERY
  SELECT
    "id" AS message_id,
    "userId",
    "message",
    "createdAt"
  FROM "GroupMessage"
  WHERE "groupId" = group_id;

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION add_members_to_group(
  user_id INT,
  group_id INT,
  member_ids INT[]
)
RETURNS VOID AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Check if the group exists
  IF NOT EXISTS (SELECT 1 FROM "Group" WHERE "id" = group_id) THEN
    RAISE EXCEPTION 'Group does not exist.';
  END IF;

  -- Check if the user is the creator of the group
  IF NOT EXISTS (
    SELECT 1
    FROM "Group"
    WHERE "id" = group_id
    AND "createdBy" = user_id
  ) THEN
    RAISE EXCEPTION 'User is not the creator of the group.';
  END IF;

  -- Check if member_ids exist in the "User" table
  IF NOT EXISTS (
    SELECT 1
    FROM "User"
    WHERE "id" = ANY(member_ids)
  ) THEN
    RAISE EXCEPTION 'One or more member IDs do not exist in the "User" table.';
  END IF;

  -- Add members to the group, avoiding duplicates
  INSERT INTO "GroupMember"("groupId", "userId")
  SELECT group_id, member_id
  FROM unnest(member_ids) AS member_id
  WHERE NOT EXISTS (
    SELECT 1
    FROM "GroupMember"
    WHERE "groupId" = group_id
    AND "userId" = member_id
  );

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION view_user_posts(
  user_id INT
)
RETURNS TABLE (
  post_id INT,
  message TEXT,
  created_at TIMESTAMP(3)
) AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Retrieve the user's posts
  RETURN QUERY
  SELECT
    "id" AS post_id,
    "message",
    "createdAt"
  FROM "Post"
  WHERE "userId" = user_id;

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION view_followers(
  user_id INT
)
RETURNS TABLE (
  follower_id INT,
  follower_first_name VARCHAR(50),
  follower_last_name VARCHAR(50)
) AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = user_id) THEN
    RAISE EXCEPTION 'User does not exist.';
  END IF;

  -- Retrieve the user's followers
  RETURN QUERY
  SELECT
    "User"."id" AS follower_id,
    "User"."firstName" AS follower_first_name,
    "User"."lastName" AS follower_last_name
  FROM "User"
  JOIN "FollowRequest" ON "User"."id" = "FollowRequest"."sourceId"
  WHERE "FollowRequest"."targetId" = user_id
  AND "FollowRequest"."status" = 'ACCEPTED';

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION view_posts_by_other_user(
  viewer_id INT,
  other_user_id INT
)
RETURNS TABLE (
  post_id INT,
  message TEXT,
  created_at TIMESTAMP(3)
) AS $$
BEGIN
  -- Check if the viewer and other user exist
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = viewer_id) THEN
    RAISE EXCEPTION 'Viewer does not exist.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "id" = other_user_id) THEN
    RAISE EXCEPTION 'Other user does not exist.';
  END IF;

  -- Check if the viewer has an accepted follow request to the other user
  IF NOT EXISTS (
    SELECT 1
    FROM "FollowRequest"
    WHERE "sourceId" = viewer_id
    AND "targetId" = other_user_id
    AND "status" = 'ACCEPTED'
  ) THEN
    RAISE EXCEPTION 'Viewer does not have an accepted follow request to the other user.';
  END IF;

  -- Retrieve posts by the other user
  RETURN QUERY
  SELECT
    "id" AS post_id,
    "message",
    "createdAt"
  FROM "Post"
  WHERE "userId" = other_user_id;

END;
$$ LANGUAGE plpgsql;
