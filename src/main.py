import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the PostgreSQL connection URL from the .env file
DATABASE_URL = os.getenv("DATABASE_URL")

# Define the path to the db folder
db_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../db")


def execute_sql_script(script_file, db_connection):
    with open(script_file, "r") as file:
        sql_script = file.read()
        with db_connection.cursor() as cursor:
            cursor.execute(sql_script)
        db_connection.commit()


def create_db(db_connection):
    with db_connection:
        execute_sql_script(os.path.join(db_folder, "schema.sql"), db_connection)


def reset_db(db_connection):
    with db_connection:
        execute_sql_script(os.path.join(db_folder, "reset.sql"), db_connection)


if __name__ == "__main__":
    # Connect to the PostgreSQL database using the provided URL
    conn = psycopg2.connect(DATABASE_URL)
    reset_db(conn)
    conn.close()
