from database import get_db

post_user_id = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5
]

post_message = [
        'Just had a fantastic day at the beach! #SummerVibes',
        'Spent the afternoon reading a good book. What''s your current read?',
        'Exploring new coffee shops in the city. Found a hidden gem!',
        'Reached a personal milestone today. Feeling accomplished!',
        'Movie night with friends! Recommend some must-watch films.',
        'Cooked a delicious meal from scratch. Homemade is the best!',
        'Morning workout complete. Ready to conquer the day! ',
        'Visited a museum and learned something new. Knowledge is power!',
        'Adopted a new pet today! Meet my furry friend. ',
        'Saw a breathtaking sunset. Nature''s beauty never ceases to amaze me.',
        'Enjoying a quiet night with a good book and a cup of tea. ',
        'Attended a live concert and danced the night away! ',
        'Spontaneous road trip with no destination. Sometimes, getting lost is the best adventure!',
        'Completed a coding project. Feeling accomplished and ready for the next challenge! ',
        'Art gallery exploration. Creativity is everywhere!',
        'Visited a wildlife sanctuary. The beauty of nature never fails to amaze me. ',
        'Game night with friends. Board games and laughter make for a perfect evening! ',
        'Stargazing on a clear night. The universe is vast and full of wonders. ',
        'Volunteered at a local charity. Small acts of kindness can make a big difference. ',
        'Learning a new instrument. Music is the language of the soul. '
]

def create_post(user_id,message_text):
    try:
        with get_db() as db:
            db.callproc("create_post", [user_id, message_text])
            result = db.fetchone()
            created_post = {"post_id": result[0]}
            # print(created_post)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_post: {e}",
        )


def seed_data():
    for i in range(len(post_user_id)):
        create_post(post_user_id[i],post_message[i])
    print("seed post done...")
