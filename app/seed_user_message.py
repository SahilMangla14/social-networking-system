from database import get_db

message_target_id = [
    1,2,3,4,5,6,7,8,9,10
]

message_source_id = [
    5,6,7,1,9,10,11,12,13,14,15,16,17,18,1,2,3,4,19,20
]

message_text = [
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

def message_friend(source_user_id,target_user_id,message_text):
    try:
        with get_db() as db:
            db.callproc(
                "message_friend", [source_user_id, target_user_id, message_text]
            )
            result = db.fetchone()

            response_data = {"message_id": result[0]}

            # print(response_data)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure message_friend: {e}",
        )


def seed_data():
    for i in range(len(message_target_id)):
        message_friend(message_source_id[2*i],message_target_id[i],message_text[2*i])
        message_friend(message_source_id[2*i+1],message_target_id[i],message_text[2*i+1])
    print("seed user group message done...")

