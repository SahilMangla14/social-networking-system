from database import get_db

users = [1, 2, 3, 4, 5, 6, 7, 8, 9 ,10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
rids =  [
[1,2], 
[4,5],
[7,8],
[10,11],
[13,14],
[16,17],
[19,20],
[22,23],
[25,26],
[28,29],
[31,32],
[34,35],
[37,38],
[40,41],
[43,44],
[46,47],
[49,50],
[52,53],
[55,56],
[58,59]]

def accept_user_request(user_id, request_ids):
    try:
        with get_db() as db:
            db.callproc("accept_follow_requests", [user_id, request_ids])
            result = db.fetchall()

            response_data = {}
            for row in result:
                response_data[row[0]] = row[1]

            # print (response_data)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure accept_follow_requests: {e}",
        )
        

def seed_data():
    for i in range(len(users)):
        accept_user_request(users[i],rids[i])
    print("Accept follow request done...")