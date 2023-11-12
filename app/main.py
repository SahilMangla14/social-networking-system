from database import get_db
from fastapi import FastAPI, HTTPException, status
from pydantic import ValidationError
from schemas import UserAccount

app = FastAPI()


@app.post("/create-user", response_model=int, status_code=status.HTTP_201_CREATED)
def create_user(user_account: UserAccount):
    try:
        with get_db() as db:
            db.callproc(
                "create_user",
                [
                    user_account.first_name,
                    user_account.middle_name,
                    user_account.last_name,
                    user_account.mobile_number,
                    user_account.email,
                    user_account.password_hash,
                    user_account.bio,
                ],
            )

            user_id = db.fetchone()[0]
            return user_id
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Validation error: {e}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_user: {e}",
        )


@app.post("/make-follow-request", response_model=int, status_code=status.HTTP_201_CREATED)
def make_follow_request(source_user_id: int, target_user_id: int):
    try:
        with get_db() as db:
            db.callproc("make_follow_request", [source_user_id, target_user_id])
            request_id = db.fetchone()[0]
            return request_id
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure make_follow_request: {e}",
        )


@app.get("/view-pending-follow-requests/{user_id}", response_model=list)
def view_pending_follow_requests(user_id: int):
    try:
        with get_db() as db:
            db.callproc("view_pending_follow_requests", [user_id])
            result = db.fetchall()

            pending_requests = []
            for row in result:
                request_info = {
                    "request_id": row[0],
                    "source_user_id": row[1],
                    "source_user_name": row[2],
                    "created_at": row[3],
                }
                pending_requests.append(request_info)

            return pending_requests
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure view_pending_follow_requests: {e}",
        )


@app.post("/accept-follow-requests", response_model=dict, status_code=status.HTTP_200_OK)
def accept_follow_requests(user_id: int, request_ids: list[int]):
    try:
        with get_db() as db:
            db.callproc("accept_follow_requests", [user_id, request_ids])
            result = db.fetchall()

            response_data = {}
            for row in result:
                response_data[row[0]] = row[1]

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure accept_follow_requests: {e}",
        )
        
        

@app.post("/create-post", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_post(user_id: int, message_text: str):
    try:
        with get_db() as db:
            db.callproc("create_post", [user_id, message_text])
            result = db.fetchone()
            created_post = {
                "post_id": result[0]
            }
            return created_post
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_post: {e}",
        )
        

@app.post("/like-post", response_model=dict, status_code=status.HTTP_201_CREATED)
def like_post(user_id: int, post_id: int):
    try:
        with get_db() as db:
            db.callproc("like_post", [user_id, post_id])
            result = db.fetchone()
            liked_post = {
                "like_id": result[0]
            }
            return liked_post
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure like_post: {e}",
        )
        
        


@app.post("/comment-on-post", response_model=dict, status_code=status.HTTP_201_CREATED)
def comment_on_post(user_id: int, post_id: int, content: str):
    try:
        with get_db() as db:
            db.callproc("comment_on_post", [user_id, post_id, content])
            result = db.fetchone()

            response_data = {
                "comment_id": result[0]
            }

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure comment_on_post: {e}",
        )
        
        
        
@app.post("/message-friend", response_model=dict, status_code=status.HTTP_201_CREATED)
def message_friend(source_user_id: int, target_user_id: int, message_text: str):
    try:
        with get_db() as db:
            db.callproc("message_friend", [source_user_id, target_user_id, message_text])
            result = db.fetchone()

            response_data = {
                "message_id": result[0]
            }

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure message_friend: {e}",
        )
        
        
@app.post("/create-user-group", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_user_group(created_by_user_id: int, title: str, summary: str):
    try:
        with get_db() as db:
            db.callproc("create_user_group", [created_by_user_id, title, summary])
            result = db.fetchone()

            response_data = {
                "group_id": result[0]
            }

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_user_group: {e}",
        )
        
        
        
@app.post("/message-in-group", response_model=dict, status_code=status.HTTP_201_CREATED)
def message_in_group(user_id: int, group_id: int, message_text: str):
    try:
        with get_db() as db:
            db.callproc("message_in_group", [user_id, group_id, message_text])
            result = db.fetchone()

            response_data = {
                "message_id": result[0]
            }

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure message_in_group: {e}",
        )
        
        

@app.get("/view-group-messages", response_model=list, status_code=status.HTTP_200_OK)
def view_group_messages(user_id: int, group_id: int):
    try:
        with get_db() as db:
            db.callproc("view_group_messages", [user_id, group_id])
            results = db.fetchall()

            response_data = []
            for result in results:
                message_data = {
                    "message_id": result[0],
                    "user_id": result[1],
                    "user_name": result[2],
                    "message_text": result[3],
                    "created_at": result[4],
                }
                response_data.append(message_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure view_group_messages: {e}",
        )
        
        
        
@app.post("/add-members-to-group", response_model=list, status_code=status.HTTP_201_CREATED)
def add_members_to_group(creator_user_id: int, group_id: int, member_ids: list[int]):
    try:
        with get_db() as db:
            db.callproc("add_members_to_group", [creator_user_id, group_id, member_ids])
            results = db.fetchall()

            response_data = []
            for result in results:
                member_data = {
                    "member_id": result[0]
                }
                response_data.append(member_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure add_members_to_group: {e}",
        )
        

@app.get("/view-user-posts/{user_id}", response_model=list, status_code=status.HTTP_200_OK)
def view_user_posts(user_id: int):
    try:
        with get_db() as db:
            db.callproc("view_user_posts", [user_id])
            results = db.fetchall()

            response_data = []
            for result in results:
                post_data = {
                    "post_id": result[0],
                    "message_text": result[1],
                    "created_at": result[2],
                    "like_count": result[3],
                    "comment_count": result[4],
                }
                response_data.append(post_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure view_user_posts: {e}",
        )
        

@app.get("/view-followers/{user_id}", response_model=list, status_code=status.HTTP_200_OK)
def view_followers(user_id: int):
    try:
        with get_db() as db:
            db.callproc("view_followers", [user_id])
            results = db.fetchall()

            response_data = []
            for result in results:
                follower_data = {
                    "follower_user_id": result[0],
                    "follower_first_name": result[1],
                    "follower_last_name": result[2],
                    "follower_mobile_number": result[3],
                    "follower_email": result[4],
                }
                response_data.append(follower_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure view_followers: {e}",
        )
        
        
        
@app.get("/view-posts-of-other-user/{viewer_user_id}/{other_user_id}", response_model=list, status_code=status.HTTP_200_OK)
def view_posts_of_other_user(viewer_user_id: int, other_user_id: int):
    try:
        with get_db() as db:
            db.callproc("view_posts_of_other_user", [viewer_user_id, other_user_id])
            results = db.fetchall()

            response_data = []
            for result in results:
                post_data = {
                    "post_id": result[0],
                    "message_text": result[1],
                    "created_at": result[2],
                    "user_id": result[3],
                    "first_name": result[4],
                    "last_name": result[5],
                    "like_count": result[6],
                    "comment_count": result[7],
                }
                response_data.append(post_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure view_posts_of_other_user: {e}",
        )
        



