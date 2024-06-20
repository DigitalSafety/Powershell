# Function to connect to Microsoft Online Service and Azure Active Directory
function Connect-Services {
    try {
        Write-Output "Connecting to Microsoft Online Service..."
        Connect-MsolService
        Write-Output "Connected to Microsoft Online Service."

        Write-Output "Connecting to Azure Active Directory..."
        Connect-AzureAD
        Write-Output "Connected to Azure Active Directory."
    }
    catch {
        Write-Error "Error connecting to services: $_"
        exit 1
    }
}

# Main script logic
Connect-Services

# Prompt for domain name
$domainName = Read-Host "Please enter the domain name"

# Retrieve and display the password policy for the authenticated session
$passwordPolicy = $null
try {
    Write-Output "Retrieving the password policy for the domain: $domainName..."
    $passwordPolicy = Get-MsolPasswordPolicy -DomainName $domainName
    Write-Output "Password Policy for the domain: $domainName"
    Write-Output "Notification Days: $($passwordPolicy.NotificationDays)"
    Write-Output "Validity Period (Days): $($passwordPolicy.ValidityPeriod)"
}
catch {
    Write-Error "Error retrieving password policy: $_"
    exit 1
}

# List users by Display Name, User Principal Name, and Password Policy
$users = $null
try {
    Write-Output "Listing users with their password policies..."
    $users = Get-AzureADUser -All $true | Select-Object DisplayName, UserPrincipalName, PasswordPolicies
}
catch {
    Write-Error "Error listing users: $_"
    exit 1
}

# Prepare data for CSV
$csvData = @()
foreach ($user in $users) {
    $csvData += [PSCustomObject]@{
        DisplayName        = $user.DisplayName
        UserPrincipalName  = $user.UserPrincipalName
        PasswordPolicies   = $user.PasswordPolicies
        Domain             = $domainName
        NotificationDays   = $passwordPolicy.NotificationDays
        ValidityPeriodDays = $passwordPolicy.ValidityPeriod
    }
}

# Save the result to a CSV file
$fileName = "password_policy_for_$domainName.csv"
$outputPath = Join-Path -Path (Get-Location) -ChildPath $fileName

try {
    Write-Output "Saving results to $outputPath..."
    $csvData | Export-Csv -Path $outputPath -NoTypeInformation -Encoding utf8
    Write-Output "Results saved to $outputPath"
}
catch {
    Write-Error "Error saving results to file: $_"
    exit 1
}

Write-Output "Script completed successfully."
