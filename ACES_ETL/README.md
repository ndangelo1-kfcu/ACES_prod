# ACES Export Process

This project automates the process of running SQL queries, exporting the results to CSV files, copying the files to a network folder, emailing the files to recipients(this step is temporary stop-gap solution only until the SFTP automation is completed), and archiving the files for future reference. The script is designed to handle errors gracefully, log all operations, and ensure that files are processed securely and efficiently.

---

## Workflow Overview

The script follows these steps:

1. **Run SQL Queries**:
   - Executes predefined SQL queries with specific parameters.
   - Queries are read from `.sql` files, and placeholders are replaced with dynamic parameters.
   - Results are fetched from the database and processed into a Pandas DataFrame.

2. **Export Results to CSV**:
   - The query results are saved as `.csv` files in the `EXPORT` folder.
   - File names are dynamically generated based on the query parameter and the current date.

3. **Copy Files to a Network Folder**:
   - The exported files are copied to a shared network folder for accessibility.
   - The script ensures that the network folder exists and validates file accessibility before copying.

4. **Email the Files STOPGAP/TEMPORARY**:
   - The exported files are emailed to a predefined list of recipients.
   - The email includes the files as attachments and logs the operation.

5. **Archive the Files**:
   - After emailing, the files are moved to a `.zip` archive in the `ARCHIVE` folder.
   - Archives older than 30 days are automatically deleted to save storage space.

---

## Folder Structure
The script uses the following folder structure:
# Main script 
ACES_ETL/ ACESExport.py 
# Database utility functions 
database_utils.py 
# Email utility functions 
email_utils.py 
# Logger configuration 
logger_config.py 
# Folder containing SQL query files 
SQL/ 
# Folder where CSV files are exported 
EXPORT/ 
# Folder where files are archived 
ARCHIVE/ 
# Folder for log files
logs/ 

## Prerequisites

- Python 3.x
- Required Python packages (install via `requirements.txt`):
  ```bash
  pip install -r requirements.txt


---

## Key Components

### 1. **SQL Query Execution**
The `run_query_and_save` function:
- Reads SQL queries from `.sql` files.
- Replaces placeholders (e.g., `{parameter}`) with dynamic values.
- Executes the query using a database connection.
- Converts the results into a Pandas DataFrame for further processing.

### 2. **Exporting to CSV**
The `save` function:
- Saves the DataFrame to a `.csv` file in the `EXPORT` folder.
- Dynamically generates file names based on the query parameter and the current date.
- Logs the success or failure of the operation.

### 3. **Copying Files to a Network Folder**
The `copy_files_to_network` function:
- Ensures the network folder exists and is a valid directory.
- Validates the existence and accessibility of each file before copying.
- Uses `shutil.copy` to copy files to the network folder.
- Logs any errors encountered during the process.

### 4. **Emailing Files**
The `email_files` function:
- Sends the exported files as email attachments.
- Uses the `email.message.EmailMessage` class to construct the email.
- Logs the success or failure of the email operation.

### 5. **Archiving Files**
The `archive_files` function:
- Compresses the exported files into a `.zip` archive in the `ARCHIVE` folder.
- Deletes the original files after archiving.
- Automatically removes archives older than 30 days to manage storage.

---

## Error Handling and Logging

The script includes robust error handling and logging:
- **Error Handling**:
  - Critical operations are wrapped in `try-except` blocks.
  - Errors are logged using `logger.exception` and re-raised to ensure the script fails gracefully.
- **Logging**:
  - All operations are logged using the `logger` module.
  - Logs include information about successful operations, warnings, and errors.
  - Log files are stored in the `logs` folder for future reference.

---

## Configuration

### Constants
- **`export_folder`**: Path to the folder where CSV files are exported.
- **`archive_folder`**: Path to the folder where files are archived.
- **`network_folder`**: Path to the shared network folder where files are copied.

### SQL Files
- Place SQL query files in the `SQL` folder.
- Example files:
  - `KFCU_ACES_StandardFields.sql`
  - `KFCU_ACES_HMDA.sql`

---

## Usage

1. **Prepare SQL Files**:
   - Place the required `.sql` files in the `SQL` folder.

2. **Run the Script**:
   - Execute the script using Python:
     ```bash
     python ACESExport.py
     ```

3. **Monitor Logs**:
   - Check the `logs` folder for detailed logs of the script's execution.

---

## Scheduling

The script is designed to run specific queries based on the day of the week and the date:
- **Monday to Friday**: Runs `KFCU_ACES_StandardFields.sql` with the parameter `Pre-Funding`.
- **Tuesday**: Additionally runs `KFCU_ACES_StandardFields.sql` with the parameter `Adverse` and `KFCU_ACES_HMDA.sql`.
- **15th of the Month**: Runs `KFCU_ACES_StandardFields.sql` with the parameter `Post-Closing`.

---

## Example Output

### Exported Files
- Files are saved in the `EXPORT` folder with names like:
KFCU_PreFunding_20250325.csv
KFCU_Adverse_20240325.csv


### Archived Files
- Files are archived in the `ARCHIVE` folder as `.zip` files: 
archive20250325.zip