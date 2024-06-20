# This script checks if the AzureAD module is installed, connects to AzureAD, 
# prompts for a User Principal Name (UPN), and retrieves the user's details.

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
$userPrincipalName = Read-Host "Enter User Principal Name to be checked"

# Retrieve and display user details
try {
    Write-Output "Retrieving user details for $userPrincipalName..."
    $user = Get-AzureADUser -ObjectId $userPrincipalName | Select-Object DisplayName, UserPrincipalName, AccountEnabled, UserType, JobTitle, Department

    if ($user -ne $null) {
        Write-Output "User details:"
        $user | Format-Table -AutoSize
    } else {
        Write-Output "No user found with User Principal Name: $userPrincipalName"
    }
}
catch {
    Write-Error "Error retrieving user details: $_"
}

Write-Output "Script completed successfully."
