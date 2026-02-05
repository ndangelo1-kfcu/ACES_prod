import smtplib
from email.message import EmailMessage
import mimetypes
from datetime import datetime, date
from logger_config import logger

# senderEmail = 'svc.UI@kfcu.org'
# recieverEmail = 'DevProd@kfcu.org'
domain = "@kfcu.org"
senderEmail = "svcui"
recieverEmails = [
    "Nathan.DAngelo",
    "Naomi.Albert",
    "Kastia.Ladner",
    "Alyssa.Bryant",
    "Callie.Gress",
]


def send_email(files):
    today = datetime.now().strftime("%Y%m%d")
    content = "The following ACES csv file(s) have been delivered and will automatically be uploaded to ACES: \n\n"
    # at https://new.acesaudit.com/KeeslerFCU/LoanImport/Index \n\n"
    content += "\n".join([f"{filename}" for _, filename in files])
    content += "\n\nYou are responsible for confirming the data import was successful at https://new.acesaudit.com/KeeslerFCU/LoanCombinedImportLog \n\nIn case of an issue or failure or if you have any questions, please create a support ticket or email devprod@kfcu.org.\n\nThank you!\n\n\nDO NOT REPLY TO THIS EMAIL. IT IS AUTOMATICALLY GENERATED.\n\n"
    msg = EmailMessage()
    msg.set_content(content)
    msg["Subject"] = "ACES Files"
    msg["From"] = f"{senderEmail}{domain}"
    msg["To"] = (
        ", ".join([f"{email}{domain}" for email in recieverEmails])
        if isinstance(recieverEmails, list)
        else f"{recieverEmails}{domain}"
    )

    # for file_path, filename in files:
    #     # Validate file extension
    #     if not (filename.endswith(f"{today}.csv") or filename.endswith(f"{today}.zip")):
    #         print(f"Skipping file {filename}: Unsupported file type.")
    #         logger.warning(f"Skipping file {filename}: Unsupported file type.")
    #         continue

    #     try:
    #         # Add the attachment
    #         mime_type, _ = mimetypes.guess_type(file_path)
    #         if mime_type:e
    #             mime_type, mime_subtype = mime_type.split("/")
    #         else:
    #             mime_type, mime_subtype = "application", "octet-stream"

    #         with open(file_path, "rb") as file:
    #             msg.add_attachment(
    #                 file.read(),
    #                 maintype=mime_type,
    #                 subtype=mime_subtype,
    #                 filename=filename,
    #             )
    #     except Exception as ex:
    #         print(f"Error attaching file: {ex}")
    #         logger.exception(f"Error attaching file: {ex}")
    #         raise

    s = smtplib.SMTP("mx.kfcu.org")
    s.send_message(msg)
    s.quit()
    print("Email sent!")
    logger.info("Email sent!")
