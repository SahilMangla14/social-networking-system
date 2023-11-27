from database import get_db

make_follow_request_source_id = [
        5, 6, 7, 
        7, 1, 3,
        9, 10, 5,
        11, 12,13,
        13, 14, 15,
        15, 16, 17,
        17, 18, 19,
        1, 2, 3,
        3, 4, 5,
        19, 20, 17,
        3,6,8,
        7, 10, 15,
        12, 14, 18,
        16, 20, 13,
        18, 20, 2,
        11, 12, 5,
        9, 10, 3,
        1, 5, 10,
        3, 6, 9,
        1,2,3
]


make_follow_request_target_id = [
    1,1,1,
    2,2,2,
    3,3,3,
    4,4,4,
    5,5,5,
    6,6,6,
    7,7,7,
    8,8,8,
    9,9,9,
    10,10,10,
    11,11,11,
    12,12,12,
    13,13,13,
    14,14,14,
    15,15,15,
    16,16,16,
    17,17,17,
    18,18,18,
    19,19,19,
    20,20,20
]


def make_follow_request(source_user_id,target_user_id):
    try:
        with get_db() as db:
            db.callproc("make_follow_request", [source_user_id, target_user_id])
            request_id = db.fetchone()[0]
            # print(request_id)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure make_follow_request: {e}",
        )
        
       
def seed_data(): 
    for i in range(len(make_follow_request_source_id)):
        make_follow_request(make_follow_request_source_id[i],make_follow_request_target_id[i])
    print("make follow request done...")       
