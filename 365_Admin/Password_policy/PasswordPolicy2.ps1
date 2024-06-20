# Function to prompt for and validate input
function Get-ValidatedIntegerInput {
    param (
        [string]$prompt
    )
    $input = $null
    while ($null -eq $input) {
        $input = Read-Host $prompt
        if (-not ($input -match '^\d+$' -and [int]$input -gt 0)) {
            Write-Host "Invalid input. Please enter a positive integer." -ForegroundColor Red
            $input = $null
        }
    }
    return [int]$input
}

# Prompt for domain name
$domainName = Read-Host "Enter the domain name (e.g., your-site.com)"

if (-not $domainName) {
    Write-Host "Domain name cannot be empty. Please provide a valid domain name." -ForegroundColor Red
    exit
}

# Prompt for validity period (in days)
$validityPeriod = Get-ValidatedIntegerInput -prompt "Enter the validity period (in days)"

# Prompt for notification period (in days)
$notificationPeriod = Get-ValidatedIntegerInput -prompt "Enter the notification period (in days)"

# Connect to the MsolService
try {
    Write-Output "Connecting to MSOnline Service..."
    Connect-MsolService
    Write-Output "Connected to MSOnline Service."
}
catch {
    Write-Error "Error connecting to MSOnline Service: $_"
    exit 1
}

# Set the password policy for the specified domain
try {
    Write-Output "Setting password policy for domain $domainName..."
    Set-MsolPasswordPolicy -DomainName $domainName -ValidityPeriod $validityPeriod -NotificationDays $notificationPeriod
    Write-Output "Password policy set successfully for domain $domainName."
}
catch {
    Write-Error "Error setting password policy: $_"
    exit 1
}

# Verify and report the new password policy
try {
    Write-Output "Retrieving and verifying the password policy for domain ${domainName}..."
    $policy = Get-MsolPasswordPolicy -DomainName $domainName
    Write-Output "Password policy for domain ${domainName}:"
    Write-Output "  Validity Period (days): $($policy.ValidityPeriod)"
    Write-Output "  Notification Period (days): $($policy.NotificationDays)"
}
catch {
    Write-Error "Error retrieving the password policy: $_"
    exit 1
}

Write-Output "Script completed successfully."
