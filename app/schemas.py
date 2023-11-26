from pydantic import BaseModel


class UserAccount(BaseModel):
    first_name: str = None
    middle_name: str = None
    last_name: str = None
    mobile_number: str
    email: str
    password: str = None
    bio: str = None
