from database import get_db

like_post_id = [
    1,2,3,4,5,6,7,8,9,10
]

like_user_id = [
    5,6,7,1,9,10,11,12,13,14,15,16,17,18,1,2,3,4,19,20
]

def like_post(user_id,post_id):
    try:
        with get_db() as db:
            db.callproc("like_post", [user_id, post_id])
            result = db.fetchone()
            liked_post = {"like_id": result[0]}
            # print(liked_post)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure like_post: {e}",
        )


def seed_data():
    for i in range(len(like_post_id)):
        like_post(like_user_id[2*i],like_post_id[i])
        like_post(like_user_id[2*i+1],like_post_id[i])
    print("like post done...")

