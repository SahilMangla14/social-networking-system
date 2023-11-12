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
