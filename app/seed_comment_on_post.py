from database import get_db

comment_post_id = [
    1,2,3,4,5,6,7,8,9,10
]

comment_user_id = [
    5,6,7,1,9,10,11,12,13,14,15,16,17,18,1,2,3,4,19,20
]

comment_content = [
    'Great post!',
    'I love this!',
    'Interesting perspective.',
    'Well said!',
    'Amazing content!',
    'Nice one!',
    'Keep it up!',
    'Inspiring!',
    'Totally agree!',
    'This is awesome!',
    'Fantastic!',
    'Thanks for sharing!',
    'Thought-provoking.',
    'Impressive!',
    'Beautiful!',
    'Well written!',
    'Kudos!',
    'Excellent point!',
    'Im inspired!',
    'Cool!'
]

def comment_on_post(user_id,post_id,content):
    try:
        with get_db() as db:
            db.callproc("comment_on_post", [user_id, post_id, content])
            result = db.fetchone()

            response_data = {"comment_id": result[0]}

            # print(response_data)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure comment_on_post: {e}",
        )

def seed_data():
    for i in range(len(comment_post_id)):
        comment_on_post(comment_user_id[2*i],comment_post_id[i],comment_content[2*i])
        comment_on_post(comment_user_id[2*i+1],comment_post_id[i],comment_content[2*i+1])
    print("comment on post done...")
