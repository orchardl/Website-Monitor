# Define the URL and the string to search for
$Url = "https://domain.com/uri"
$SearchString = "<string 1>"
$SearchString2 = "<string 2>"
$MinContentLength = 40000 # could be more or less
$MaxResponseTime = 5 # in seconds

# Email settings
$EmailFrom = "<brevo email>"
$EmailTo = "<to email>"
$Subject = "Problem: <website name>"
$SMTPServer = "smtp-relay.brevo.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("<account>@smtp-brevo.com", "<smtp password>");

# AWS Email Settings
$AWSFrom = "<from email>"
$AWSTo = "<phone number>@tmomail.net"
$AWSsmtp = "email-smtp.us-east-2.amazonaws.com"
$AWSsmtpUsername = "<smtp username>"  # Replace with your SMTP username
$AWSsmtpPassword = "<smtp password>"  # Replace with your SMTP password; also, remember to run the script to get that password
$AWSsecurePassword = ConvertTo-SecureString $AWSsmtpPassword -AsPlainText -Force
$AWSCredential = New-Object System.Management.Automation.PSCredential($AWSsmtpUsername, $AWSsecurePassword)

# Function to send email
function Send-AlertEmail {
    param (
        [string]$Body
    )

    $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
    Send-MailMessage -From $AWSFrom -To $AWSTo -Subject $Subject -Body $Body -SmtpServer $AWSsmtp -UseSsl -Credential $AWSCredential -Port 587
}

try {
    # Send a web request to the URL
    $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $MaxResponseTime

    # Check the status code
    if ($Response.StatusCode -ne 200) {
        $Body = "$Url did not return 200 OK. Status code: $($Response.StatusCode)"
        Send-AlertEmail -Body $Body
        Write-Output $Body
        return
    }

    # Check the content length
    if ($Response.Content.Length -lt $MinContentLength) {
        $Body = "$Url length is less than the expected minimum. Length: $($Response.Content.Length)"
        Send-AlertEmail -Body $Body
        Write-Output $Body
        return
    }

    # Check if the content contains the search string (case-insensitive)
    if ($Response.Content -notmatch [regex]::Escape($SearchString)) {
        $Body = "$Url content does not contain: $SearchString"
        Send-AlertEmail -Body $Body
        return
    }

    # Check if the content contains the search string (case-insensitive)
    if ($Response.Content -notmatch [regex]::Escape($SearchString2)) {
        $Body = "$Url content does not contain: $SearchString2"
        Send-AlertEmail -Body $Body
        Write-Output $Body
        return
    }

    $currentDate = Get-Date -Format "yyy-MM-dd HH:mm:ss"
    Write-Output "$currentDate $Url is returning normal."
} catch {
    $Body = "Failed to reach $Url Error: $_"
    Send-AlertEmail -Body $Body
    Write-Output $Body
