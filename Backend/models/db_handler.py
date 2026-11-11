# models/db_handler.py
import mysql.connector
from config import DB_CONFIG

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

def fetch_query(query, params=None):
    """Untuk operasi SELECT"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(query, params or ())
    result = cursor.fetchall()
    conn.close()
    return result

def execute_query(query, params=None):
    """Untuk operasi INSERT, UPDATE, DELETE"""
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(query, params or ())
    conn.commit()
    last_id = cursor.lastrowid
    conn.close()
    return last_id