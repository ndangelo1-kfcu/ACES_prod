import os
import pandas as pd
from datetime import datetime, date
from database_utils import execute_sql_query
from logger_config import logger
from email_utils import send_email
import shutil
import time
import zipfile
import sys
from constants import export_staging_folder, archive_folder, network_folder

os.makedirs(export_staging_folder, exist_ok=True)
os.makedirs(archive_folder, exist_ok=True)
files = []


# Function to execute SQL and save results
def run_query_and_save(query_file, parameter, export_folder):

    # Read SQL query
    print("Reading SQL query from file: " + query_file)
    try:
        with open(query_file, "r") as file:
            query = file.read()
    except FileNotFoundError:
        print(f"Error: The file '{query_file}' was not found.")
        logger.error(f"Error: The file '{query_file}' was not found.")
        sys.exit(1)
    except PermissionError:
        print(f"Error: Permission denied when accessing the file '{query_file}'.")
        logger.error(
            f"Error: Permission denied when accessing the file '{query_file}'."
        )
        sys.exit(1)
    except Exception as e:
        print(
            f"Error: An unexpected error occurred while opening the file '{query_file}': {e}"
        )
        logger.error(
            f"Error: An unexpected error occurred while opening the file '{query_file}': {e}"
        )
        sys.exit(1)

    # Replace parameter placeholder
    sql_query = query.replace("{parameter}", parameter)

    # Execute query and process results
    print("Executing SQL query...")
    logger.info("Executing SQL query...")
    df: pd.DataFrame = execute_sql_query(sql_query)

    print(f"Query returned {len(df)} rows.")
    logger.info(f"Query returned {len(df)} rows.")
    if not df.empty:
        print(df.head())
        print("Saving results to CSV...")
        logger.info("Saving results to CSV...")
        save(parameter, export_folder, df)


def save(parameter, export_folder, df):
    try:
        df.fillna("", inplace=True)  # Replace NULL values with empty strings

        # Generate filename
        today = datetime.now().strftime("%Y%m%d")
        parameter_clean = (
            parameter.replace("-", "").replace(" ", "")
            if parameter and parameter != ""
            else "HMDA"
        )
        base = "KFCU_"
        filename = f"{base}{parameter_clean}_{today}.csv"

        # Save to CSV
        file_path = os.path.join(export_folder, filename)
        df.to_csv(file_path, index=False)
        print(f"Saved (exported to csv): {file_path}")
        logger.info(f"Saved (exported to csv): {file_path}")

        files.append((file_path, filename))
    except Exception as ex:
        logger.exception(f"Error saving results to CSV: {ex}")
        sys.exit(1)


# Function to archive files and clean up old archives
def archive_files(files, archive_folder):
    try:
        today = datetime.now().strftime("%Y%m%d")
        archive_name = os.path.join(archive_folder, f"archive_{today}.zip")

        # Add files to the zip archive
        print(f"Archiving files to {archive_name}")
        logger.info(f"Archiving files to {archive_name}")
        with zipfile.ZipFile(archive_name, "w") as archive:
            for file_path, filename in files:
                archive.write(file_path, arcname=filename)
                os.remove(file_path)  # Remove the original file after archiving

        print(f"Archived files to {archive_name}")
        logger.info(f"Archived files to {archive_name}")

        # Clean up archives older than 30 days
        print("Cleaning up old archives...")
        logger.info("Cleaning up old archives...")
        thirty_days_ago = time.time() - (30 * 24 * 60 * 60)
        for file in os.listdir(archive_folder):
            file_path = os.path.join(archive_folder, file)
            if (
                os.path.isfile(file_path)
                and os.path.getmtime(file_path) < thirty_days_ago
            ):
                os.remove(file_path)
                print(f"Deleted old archive: {file_path}")
                logger.info(f"Deleted old archive: {file_path}")
    except Exception as ex:
        logger.exception(f"Error archiving files: {ex}")
        sys.exit(1)
        raise


# Function to copy files to a network folder
def copy_files_to_network(files, network_folder):
    try:
        # Ensure the network folder exists and is a directory
        if not os.path.exists(network_folder):
            os.makedirs(network_folder, exist_ok=True)
        elif not os.path.isdir(network_folder):
            print(f"Error: The path {network_folder} exists but is not a directory.")
            logger.error(f"The path {network_folder} exists but is not a directory.")
            raise NotADirectoryError(
                f"The path {network_folder} exists but is not a directory."
            )

        for file_path, filename in files:
            # Check if the file is accessible
            if not os.path.exists(file_path):
                print(f"Error: File {file_path} does not exist.")
                logger.error(f"Error: File {file_path} does not exist.")
                raise FileNotFoundError(f"File {file_path} does not exist.")
            if not os.access(file_path, os.R_OK):
                print(
                    f"Error: File {file_path} is not accessible (no read permissions)."
                )
                logger.error(
                    f"Error: File {file_path} is not accessible (no read permissions)."
                )
                raise PermissionError(
                    f"File {file_path} is not accessible (no read permissions)."
                )

            # Copy the file to the network folder, replacing it if it already exists
            # Determine subfolder based on filename
            if "HMDA" in filename:
                subfolder = "HMDA"
            else:
                subfolder = "ORIGINATIONS"
            destination_dir = os.path.join(network_folder, subfolder)
            os.makedirs(destination_dir, exist_ok=True)
            destination = os.path.join(destination_dir, filename)
            try:
                shutil.copyfile(file_path, destination)  # Overwrites if the file exists
                print(f"Copied {file_path} to {destination}")
                logger.info(f"Copied {file_path} to {destination}")
            except Exception as e:
                logger.exception(
                    f"Error copying {file_path} to network folder: {destination}: {e}"
                )
                sys.exit(1)
                raise

    except Exception as ex:
        logger.exception(f"Error accessing network file: {ex}")
        sys.exit(1)
        raise


# Main function
def main():
    try:
        # standard = r"C:\kDev\ACES\ACES_ETL\SQL\KFCU_ACES_StandardFieldsV2.sql"
        # hmda = r"C:\kDev\ACES\ACES_ETL\SQL\KFCU_ACES_HMDA.sql"

        standard = r"C:\KFCU_SSIS\Live\ACES\ACES_ETL\SQL\KFCU_ACES_StandardFieldsV3.sql"
        # hmda = r"C:\kDev\ACES\ACES_ETL\SQL\KFCU_ACES_HMDA.sql"
        hmda = r"C:\KFCU_SSIS\Live\ACES\ACES_ETL\SQL\KFCU_ACES_HMDA.sql"

        # Define schedule
        today = date.today()
        weekday = today.weekday()  # Monday=0, Tuesday=1, ..., Sunday=6
        current_hour = datetime.now().hour

        # Morning: run all
        if current_hour < 12:
            # Run STANDARD.sql with 'Pre-Funding' Monday-Friday
            if weekday in range(0, 5):  # Monday to Friday
                print("Running Pre-Funding")
                logger.info("Running Pre-Funding")
                run_query_and_save(standard, "Pre-Funding", export_staging_folder)

            # Run STANDARD.sql with 'Adverse' and HMDA.sql on Tuesday
            if weekday == 1:  # Tuesday
                print("Running Adverse and HMDA")
                logger.info("Running Adverse and HMDA")
                run_query_and_save(standard, "Adverse", export_staging_folder)
                run_query_and_save(hmda, "", export_staging_folder)

            # Run STANDARD.sql with 'Post-Closing' on the 15th of the month
            if today.day == 15:
                print("Running Post-Closing")
                logger.info("Running Post-Closing")
                run_query_and_save(standard, "Post-Closing", export_staging_folder)
        else:
            # Afternoon: run only Pre-Funding
            if weekday in range(0, 5):  # Monday to Friday
                print("Running Pre-Funding (Afternoon)")
                logger.info("Running Pre-Funding (Afternoon)")
                run_query_and_save(standard, "Pre-Funding", export_staging_folder)

        if not files:
            print(
                today.isoformat()
                + " Day:"
                + str(today.weekday())
                + " -No files to process."
            )
            logger.info(
                today.isoformat()
                + " Day:"
                + str(today.weekday())
                + " -No files to process."
            )
            return

        # Copy files to the network folder
        print("Copying files to network folder...")
        logger.info("Copying files to network folder...")
        copy_files_to_network(files, network_folder)

        # Send email with the files
        print("Emailing files...")
        logger.info("Emailing files...")
        send_email(files)

        # Archive the files and clean up old archives
        print("Archiving files...")
        logger.info("Archiving files...")
        archive_files(files, archive_folder)
    except Exception as ex:
        logger.exception(f"Error in main execution: {ex}")
        sys.exit(1)
        raise


if __name__ == "__main__":
    print("Starting ACES Export...")
    main()
