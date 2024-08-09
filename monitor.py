import smtplib
import requests
from email.mime.text import MIMEText
from requests.exceptions import RequestException
import datetime

# Define the URL and the strings to search for
url = "https://domain.com/uri"
search_string1 = "<string 1 to check for>"
search_string2 = "<string 2 to check for>"
min_content_length = 40000 # could be more or less
max_response_time = 7  # in seconds

# Email settings
email_from = "<brevo account email>"
email_to = "<username>@<domain>.com"
subject = "Problem: <website name>"
smtp_server = "smtp-relay.brevo.com"
smtp_username = "<account>@smtp-brevo.com"
smtp_password = "<smtp password>"

# AWS Email Settings
aws_from = "<username>@<domain>.com"
aws_to = "<phone number>@tmomail.net"
aws_smtp = "email-smtp.us-east-2.amazonaws.com"
aws_smtp_username = "<username>"  # Replace with your SMTP username
aws_smtp_password = "<smtp password>"  # Replace with your SMTP password; also, remember to run the script to generate this

def log(message):
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{current_time}] {message}")

def send_alert_email(body):
    # Send first email
    msg = MIMEText(body)
    msg['From'] = email_from
    msg['To'] = email_to
    msg['Subject'] = subject

    with smtplib.SMTP(smtp_server, 587) as server:
        server.starttls()
        server.login(smtp_username, smtp_password)
        server.sendmail(email_from, [email_to], msg.as_string())

    # Send second email
    aws_msg = MIMEText(body)
    aws_msg['From'] = aws_from
    aws_msg['To'] = aws_to
    aws_msg['Subject'] = subject

    with smtplib.SMTP(aws_smtp, 587) as server:
        server.starttls()
        server.login(aws_smtp_username, aws_smtp_password)
        server.sendmail(aws_from, [aws_to], aws_msg.as_string())

try:
    response = requests.get(url, timeout=max_response_time)

    if response.status_code != 200:
        body = f"{url} did not return 200 OK. Status code: {response.status_code}"
        send_alert_email(body)
        log(body)
    elif len(response.content) < min_content_length:
        body = f"{url} length is less than the expected minimum. Length: {len(response.content)}"
        send_alert_email(body)
        log(body)
    elif search_string1 not in response.text:
        body = f"{url} content does not contain: {search_string1}"
        send_alert_email(body)
        log(body)
    elif search_string2 not in response.text:
        body = f"{url} content does not contain: {search_string2}"
        send_alert_email(body)
        log(body)
    else:
        log(f"{url} is returning normal.")
except RequestException as e:
    body = f"Failed to reach the {url}. Error: {e}"
    send_alert_email(body)
    log(body)
