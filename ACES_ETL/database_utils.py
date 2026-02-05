import pandas as pd
import pyodbc
from logger_config import logger
from database import get_arcu_db
import sys


def execute_sql_query(sql_query: str):
    try:
        # Use the connection in a context manager
        with get_arcu_db() as conn:
            # Log the first 1000 characters of the query for debugging purposes
            logger.debug(f"SQL Query Preview (first 1000 chars): {sql_query[:1000]}")
            # Create a cursor and execute the query
            cursor = conn.cursor()
            cursor.execute(sql_query)

            # Fetch all rows if the query returns rows
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()

                # Convert rows to a pandas DataFrame
                df = pd.DataFrame.from_records(rows, columns=columns)
                logger.info(
                    f"SQL query executed successfully. Rows returned: {len(df)}"
                )
                return df
            else:
                logger.warning("The query did not return any rows.")
                return (
                    pd.DataFrame()
                )  # Return an empty DataFrame if no rows are returned

    except Exception as e:
        logger.exception(f"An error occurred during sql query execution: {e}")
        sys.exit(1)  # Exit the program if an error occurs
        raise
