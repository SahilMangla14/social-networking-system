--dropping the table first
DROP TABLE IF EXISTS post CASCADE;

CREATE TABLE IF NOT EXISTS post (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    message_text text,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- seed.sql
-- Seed data using the create_post function
DO $$ 
DECLARE
    user_id_arr INTEGER[] := ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    message_text_arr TEXT[] := ARRAY[
        'Just had a fantastic day at the beach!  #SummerVib',
        'Spent the afternoon reading a good book. What''s your current read?',
        'Exploring new coffee shops in the city. Found a hidden gem!',
        'Reached a personal milestone today. Feeling accomplished!',
        'Movie night with friends! Recommend some must-watch films.',
        'Cooked a delicious meal from scratch. Homemade is the best!',
        'Morning workout complete. Ready to conquer the day! ',
        'Visited a museum and learned something new. Knowledge is power!',
        'Adopted a new pet today! Meet my furry friend. ',
        'Saw a breathtaking sunset. Nature''s beauty never ceases to amaze me.'
    ];
    i INTEGER;
    new_post_id INTEGER;
BEGIN
    FOR i IN 1..10 LOOP
        SELECT create_post(user_id_arr[i], message_text_arr[i]) INTO new_post_id;
        RAISE NOTICE 'Created post with id: %', new_post_id;
    END LOOP;
END $$;