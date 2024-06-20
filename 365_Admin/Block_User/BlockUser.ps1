# This script checks if the AzureAD module is installed, connects to AzureAD, 
# prompts for a User Principal Name (UPN), and disables the specified user's account.

# Install the AzureAD module if not already installed
try {
    Write-Output "Checking if AzureAD module is installed..."
    if (-not (Get-Module -ListAvailable -Name AzureAD)) {
        Write-Output "AzureAD module not found. Installing AzureAD module..."
        Install-Module AzureAD -Scope CurrentUser -Force
        Write-Output "AzureAD module installed."
    } else {
        Write-Output "AzureAD module is already installed."
    }
}
catch {
    Write-Error "Error installing AzureAD module: $_"
    exit
}

# Connect to AzureAD
try {
    Write-Output "Connecting to Azure Active Directory..."
    Connect-AzureAD
    Write-Output "Connected to Azure Active Directory."
}
catch {
    Write-Error "Error connecting to Azure Active Directory: $_"
    exit
}

# Prompt for User Principal Name
$userPrincipalName = Read-Host "Enter User Principal Name (UPN) to disable the account"

# Disable the specified user's account
try {
    Write-Output "Disabling account for $userPrincipalName..."
    $user = Get-AzureADUser -ObjectId $userPrincipalName

    if ($user -ne $null) {
        Set-AzureADUser -ObjectId $user.ObjectId -AccountEnabled $false
        Write-Output "Account for $userPrincipalName has been disabled."
    } else {
        Write-Output "No user found with User Principal Name: $userPrincipalName"
    }
}
catch {
    Write-Error "Error disabling user account: $_"
}

Write-Output "Script completed successfully."
