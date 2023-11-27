from database import get_db

group_message_user_id = [
    5,7,9,11,13,15,17,1,3,19,3,7,12,16,18,6,1,10,12,14
]

group_message_group_id = [
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,1,2,3,4,5
]

group_message_text = [
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

def group_messages(user_id,group_id,message_text):
    try:
        with get_db() as db:
            db.callproc("message_in_group", [user_id, group_id, message_text])
            result = db.fetchone()

            response_data = {"message_id": result[0]}

            # print(response_data)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure message_in_group: {e}",
        )

def seed_data():
    for i in range(len(group_message_user_id)):
        group_messages(group_message_user_id[i],group_message_group_id[i],group_message_text[i])
    print("group messages done...")
