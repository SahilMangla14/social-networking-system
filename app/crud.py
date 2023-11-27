from database import get_db
from pathlib import Path
import seed_user_data

DB_FOLDER = Path(__file__).resolve().parent.parent.joinpath("db")


def execute_sql_script(script_file: str):
    try:
        with open(DB_FOLDER.joinpath(script_file), "r") as file:
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
    execute_sql_script("seed.sql")


if __name__ == "__main__":
    # reset_db()
    create_tables()
    load_procedures()
    # seed_user_data.seed_data()
    # seed_data()
