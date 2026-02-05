# ARCU Database Connection String
ARCU_CONNECTION_STRING = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=VSARCU02;"
    "Database=ARCUSYM000;"
    "Trusted_Connection=yes;"
    "MARS_Connection=yes;"
)

# KRAP Database Connection String
KRAP_CONNECTION_STRING = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=VSARCU02;"
    "Database=kRAP;"
    "Trusted_Connection=yes;"
)

# Paths
export_staging_folder = r"\\vsarcu02\c$\KFCU_SSIS\Live\ACES\EXPORT_STAGING"
archive_folder = r"\\vsarcu02\c$\KFCU_SSIS\Live\ACES\ARCHIVE"
network_folder = r"\\kfcu\share\PR\MIS\ASD Area\ACES\EXPORT"
