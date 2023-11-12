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
