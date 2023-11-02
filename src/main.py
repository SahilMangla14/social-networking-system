import os
import sqlite3

# Define the path to the database folder
db_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../db')
db_path = os.path.join(db_folder, 'dev.db')

def execute_sql_script(script_file, db_connection):
    with open(script_file, 'r') as file:
        sql_script = file.read()
        db_connection.executescript(sql_script)

def create_db(db_connection):
    with db_connection:
        execute_sql_script(os.path.join(db_folder, 'schema.sql'), db_connection)

def reset_db(db_connection):
    with db_connection:
        execute_sql_script(os.path.join(db_folder, 'reset.sql'), db_connection)

if __name__ == '__main__':
    conn = sqlite3.connect(db_path)
    reset_db(conn)
    conn.close()