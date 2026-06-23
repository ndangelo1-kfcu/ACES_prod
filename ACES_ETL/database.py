import pyodbc
from contextlib import contextmanager
from logger_config import logger
from constants import ARCU_CONNECTION_STRING


@contextmanager
def get_arcu_db():
    conn = None
    try:
        # Establish a connection to the database
        conn = pyodbc.connect(ARCU_CONNECTION_STRING)
        logger.debug("Database connection established.")
        yield conn
    except Exception as e:
        logger.exception(f"An error occurred while connecting to the database: {e}")
        raise
    finally:
        if conn:
            conn.close()
            logger.debug("Database connection closed.")
