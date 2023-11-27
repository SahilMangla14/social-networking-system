from database import get_db

user_id_add_members = [
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,1,2,3,4,5
]

user_group_id = [
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
]

user_group_members_id = [
    [5, 6, 7], 
    [7, 1, 3],
    [9, 10, 5],
    [11, 12,13],
    [13, 14, 15],
    [15, 16, 17],
    [17, 18, 19],
    [1, 2, 3],
    [3, 4, 5],
    [19, 20, 17],
    [3,6,8],
    [7, 10, 15],
    [12, 14, 18],
    [16, 20, 13],
    [18, 20, 2],
    [11, 12, 5],
    [9, 10, 3],
    [1, 5, 10],
    [3, 6, 9],
    [1,2,3]
]





def add_members_to_group(creator_user_id, group_id, member_ids):
    try:
        with get_db() as db:
            db.callproc("add_members_to_group", [creator_user_id, group_id, member_ids])
            results = db.fetchall()

            response_data = []
            for result in results:
                member_data = {"member_id": result[0]}
                response_data.append(member_data)

            # print(response_data)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure add_members_to_group: {e}",
        )
    
def seed_data():
    for i in range(len(user_id_add_members)):
        add_members_to_group(user_id_add_members[i],user_group_id[i],user_group_members_id[i])
    print("group members added done...")