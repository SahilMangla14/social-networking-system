from pydantic import BaseModel


class UserAccount(BaseModel):
    first_name: str = None
    middle_name: str = None
    last_name: str = None
    mobile_number: str
    email: str
    password: str = None
    bio: str = None

class UpdateUserAccount(BaseModel):
    first_name: str | None = None
    middle_name: str | None = None
    last_name: str | None = None
    mobile_number: str | None = None
    email: str | None = None
    password: str | None = None
    bio: str | None = None