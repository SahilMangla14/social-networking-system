from database import get_db
from pathlib import Path
import seed_user_data
import seed_make_follow_request
import seed_accept_follow_request
import seed_user_message
import seed_post
import seed_comment_on_post
import seed_like_post
import seed_user_group
import seed_group_members
import seed_group_message

DB_FOLDER = Path(__file__).resolve().parent.parent.joinpath("db")


def execute_sql_script(script_file: str):
    try:
        with open(DB_FOLDER.joinpath(script_file), "r") as file:
            sql_script = file.read()
            with get_db() as db:
                db.execute(sql_script)
    except Exception as e:
        print(f"Error executing SQL script {script_file}: {e}")
        
SEED_FOLDER = Path(__file__).resolve().parent.joinpath("seed")
def execute_seed_script(script_file: str):
    try:
        with open(SEED_FOLDER.joinpath(script_file), "r") as file:
            sql_script = file.read()
            with get_db() as db:
                db.execute(sql_script)
    except Exception as e:
        print(f"Error executing SQL script {script_file}: {e}")


def create_tables():
    execute_sql_script("schema.sql")


def reset_db():
    execute_sql_script("reset.sql")


def load_procedures():
    execute_sql_script("procedures.sql")


def seed_data():
    seed_user_data.seed_data()
    seed_make_follow_request.seed_data()
    seed_accept_follow_request.seed_data()
    seed_user_message.seed_data()
    seed_post.seed_data()
    seed_comment_on_post.seed_data()
    seed_like_post.seed_data()
    seed_user_group.seed_data()
    seed_group_members.seed_data()
    seed_group_message.seed_data()
    
    


def load_triggers():
    execute_sql_script("triggers.sql")


if __name__ == "__main__":
    print("resetting db...")
    reset_db()
    print("resetting db done!")
    print("creating tables...")
    create_tables()
    print("creating tables done!")
    print("loading procedures...")
    load_procedures()
    print("loading procedures done!")
    print("triggers loading...")
    load_triggers()
    print("triggers loaded!")
    print("seeding data...")
    seed_data()
    print("seeding data done!")
