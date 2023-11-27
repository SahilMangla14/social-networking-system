from database import get_db
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from passlib.context import CryptContext
from pydantic import ValidationError
from schemas import UserAccount
from typing import Annotated

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

app = FastAPI()

security = HTTPBasic()


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


def get_user(email: str):
    with get_db() as db:
        db.execute("SELECT * FROM user_account WHERE email = %s", (email,))
        user_data = db.fetchone()

        if not user_data:
            return None

        user_dict = dict(zip([desc[0] for desc in db.description], user_data))
        return user_dict


def authenticate_user(email: str, password: str):
    user = get_user(email)
    if not user:
        return False
    if not verify_password(password, user["password_hash"]):
        return False
    return user


def get_current_user_id(
    credentials: Annotated[HTTPBasicCredentials, Depends(security)]
):
    user = authenticate_user(credentials.username, credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    return user["id"]


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
                    get_password_hash(user_account.password),
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


@app.post(
    "/make-follow-request", response_model=int, status_code=status.HTTP_201_CREATED
)
def make_follow_request(
    target_user_id: int, source_user_id: int = Depends(get_current_user_id)
):
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


@app.get("/view-pending-follow-requests", response_model=list)
def view_pending_follow_requests(user_id: int = Depends(get_current_user_id)):
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


@app.post(
    "/accept-follow-requests", response_model=dict, status_code=status.HTTP_200_OK
)
def accept_follow_requests(
    request_ids: list[int], user_id: int = Depends(get_current_user_id)
):
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
def create_post(message_text: str, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("create_post", [user_id, message_text])
            result = db.fetchone()
            created_post = {"post_id": result[0]}
            return created_post
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_post: {e}",
        )


@app.post("/like-post", response_model=dict, status_code=status.HTTP_201_CREATED)
def like_post(post_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("like_post", [user_id, post_id])
            result = db.fetchone()
            liked_post = {"like_id": result[0]}
            return liked_post
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure like_post: {e}",
        )


@app.post("/comment-on-post", response_model=dict, status_code=status.HTTP_201_CREATED)
def comment_on_post(
    post_id: int, content: str, user_id: int = Depends(get_current_user_id)
):
    try:
        with get_db() as db:
            db.callproc("comment_on_post", [user_id, post_id, content])
            result = db.fetchone()

            response_data = {"comment_id": result[0]}

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure comment_on_post: {e}",
        )


@app.post("/message-friend", response_model=dict, status_code=status.HTTP_201_CREATED)
def message_friend(
    target_user_id: int,
    message_text: str,
    source_user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db() as db:
            db.callproc(
                "message_friend", [source_user_id, target_user_id, message_text]
            )
            result = db.fetchone()

            response_data = {"message_id": result[0]}

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure message_friend: {e}",
        )


@app.post(
    "/create-user-group", response_model=dict, status_code=status.HTTP_201_CREATED
)
def create_user_group(
    title: str,
    summary: str,
    created_by_user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db() as db:
            db.callproc("create_user_group", [created_by_user_id, title, summary])
            result = db.fetchone()

            response_data = {"group_id": result[0]}

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_user_group: {e}",
        )


@app.post("/message-in-group", response_model=dict, status_code=status.HTTP_201_CREATED)
def message_in_group(
    group_id: int,
    message_text: str,
    user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db() as db:
            db.callproc("message_in_group", [user_id, group_id, message_text])
            result = db.fetchone()

            response_data = {"message_id": result[0]}

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure message_in_group: {e}",
        )


@app.get("/view-group-messages", response_model=list, status_code=status.HTTP_200_OK)
def view_group_messages(group_id: int, user_id: int = Depends(get_current_user_id)):
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


@app.post(
    "/add-members-to-group", response_model=list, status_code=status.HTTP_201_CREATED
)
def add_members_to_group(
    group_id: int,
    member_ids: list[int],
    creator_user_id: int = Depends(get_current_user_id),
):
    try:
        with get_db() as db:
            db.callproc("add_members_to_group", [creator_user_id, group_id, member_ids])
            results = db.fetchall()

            response_data = []
            for result in results:
                member_data = {"member_id": result[0]}
                response_data.append(member_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure add_members_to_group: {e}",
        )


@app.get("/view-user-posts", response_model=list, status_code=status.HTTP_200_OK)
def view_user_posts(user_id: int = Depends(get_current_user_id)):
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


@app.get("/view-followers", response_model=list, status_code=status.HTTP_200_OK)
def view_followers(user_id: int = Depends(get_current_user_id)):
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


@app.get(
    "/view-posts-of-other-user/{other_user_id}",
    response_model=list,
    status_code=status.HTTP_200_OK,
)
def view_posts_of_other_user(
    other_user_id: int, viewer_user_id: int = Depends(get_current_user_id)
):
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


@app.get("/who-to-follow", response_model=list, status_code=status.HTTP_200_OK)
def who_to_follow(user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("who_to_follow", [user_id])
            results = db.fetchall()

            response_data = []
            for result in results:
                user_data = {
                    "user_id": result[0],
                    "first_name": result[1],
                    "last_name": result[2],
                    "mobile_number": result[3],
                    "email": result[4],
                    "bio": result[5],
                }
                response_data.append(user_data)

            return response_data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure who_to_follow: {e}",
        )

@app.get("/view-post-feed", response_model=list, status_code=status.HTTP_200_OK)
def view_post_feed(user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("view_post_feed", [user_id])
            results = db.fetchall()
            print(results)
            response_data = []
            for result in results:
                post_data = {
                    "post_id": result[0],
                    "creator_id": result[1],
                    "message_text": result[2],
                    "created_at": result[3],
                    "like_count": result[4],
                    "comment_count": result[5],
                }
                response_data.append(post_data)

            return response_data
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure view_post_feed: {e}",
        )
    

## =========delete routes===========

@app.delete("/delete-user", response_model=dict, status_code=status.HTTP_200_OK)
def delete_user(user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("delete_user", [user_id])
            results = db.fetchall()    
            deleted_user = {"deleted_user_id": results}
            return deleted_user

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure delete_user: {e}",
        )


@app.delete("/delete-post/{post_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_post(post_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("delete_post", [post_id, user_id])
            results = db.fetchall()
            deleted_post_id = {"deleted_post_id": results}    
            return deleted_post_id

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure delete_post: {e}",
        )
    

    # unlike_post
@app.delete("/unlike-post/{post_id}", response_model=dict, status_code=status.HTTP_200_OK)
def unlike_post(post_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("unlike_post", [post_id, user_id])
            results = db.fetchall()
            unliked_id = {"unliked_id": results}    
            return unliked_id

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure unlike-post: {e}",
        )


# delete_comment_on_post
@app.delete("/delete-comment-on-post/{post_id}/{comment_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_comment_on_post(comment_id:int, post_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("delete_comment_on_post", [comment_id, post_id, user_id])
            results = db.fetchall()
            deleted_comment_id = {"deleted_comment_id": results}    
            return deleted_comment_id

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure delete_comment_on_post: {e}",
        )

@app.delete("/delete-message-friend/{message_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_message_friend(message_id:int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("delete_message_friend", [message_id, user_id])
            results = db.fetchall()
            deleted_message_id = {"deleted_message_id": results}    
            return deleted_message_id

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure delete_message_friend: {e}",
        ) 

@app.delete("/delete-user-group/{group_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_user_group(group_id:int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("delete_user_group", [group_id, user_id])
            results = db.fetchall()
            deleted_group_id = {"deleted_group_id": results}    
            return deleted_group_id

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure delete_user_group: {e}",
        ) 

@app.delete("/delete-message-in-group/{group_id}/{message_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_message_in_group(group_id:int, message_id:int, user_id: int = Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("delete_message_in_group", [group_id, message_id ,user_id])
            results = db.fetchall()
            deleted_message_id = {"deleted_message_id": results}    
            return deleted_message_id

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure delete_message_in_group: {e}",
        ) 

#remove members from a group
@app.delete("/remove-members-from-group", response_model=list, status_code=status.HTTP_200_OK)
def remove_members_from_group(group_id: int, members_id: list[int], creator_id=Depends(get_current_user_id)):
    try:
        with get_db() as db:
            db.callproc("remove_members_from_group", [group_id , members_id, creator_id])
            results = db.fetchall()
            deleted_members = []    
            for result in results:
                deleted_members.append({"member_id": result[0]})
            return deleted_members

    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure remove_members_from_group: {e}",
        ) 
    


