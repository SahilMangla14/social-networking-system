from database import get_db

with get_db() as db:
    db.callproc("update_user", [3, None, None, None, None, None, None, "Shazam!"])