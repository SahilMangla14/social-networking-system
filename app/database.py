import os
import psycopg2
from contextlib import contextmanager
from dotenv import load_dotenv
from pathlib import Path

ENV_PATH = Path(__file__).resolve().parent.parent.joinpath(".env")
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")


@contextmanager
def get_db():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        yield cursor
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cursor.close()
        conn.close()
