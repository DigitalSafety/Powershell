# This script checks if the Microsoft.Graph module is installed, connects to Microsoft Graph,
# prompts for a User Principal Name (UPN), and deletes the specified user.

# Function to install the Microsoft.Graph module if not already installed
function Install-MicrosoftGraphModule {
    try {
        Write-Output "Checking if Microsoft.Graph module is installed..."
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
            Write-Output "Microsoft.Graph module not found. Installing Microsoft.Graph module..."
            Install-Module Microsoft.Graph -Scope CurrentUser -Force
            Write-Output "Microsoft.Graph module installed."
        } else {
            Write-Output "Microsoft.Graph module is already installed."
        }
    }
    catch {
        Write-Error "Error installing Microsoft.Graph module: $_"
        exit
    }
}

# Function to import the necessary Microsoft.Graph module components
function Import-MicrosoftGraphComponents {
    try {
        Write-Output "Importing Microsoft.Graph.Users module..."
        Import-Module Microsoft.Graph.Users -ErrorAction Stop
        Write-Output "Microsoft.Graph.Users module imported."
    }
    catch {
        Write-Error "Error importing Microsoft.Graph.Users module: $_"
        exit
    }
}

# Install and import Microsoft.Graph module components
Install-MicrosoftGraphModule
Import-MicrosoftGraphComponents

# Connect to Microsoft Graph
try {
    Write-Output "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes "Directory.Read.All"
    Write-Output "Connected to Microsoft Graph."
}
catch {
    Write-Error "Error connecting to Microsoft Graph: $_"
    exit
}

# Prompt for User Principal Name (email)
$userPrincipalName = Read-Host "Enter User Principal Name (email) to delete the user"

# Warning and confirmation
Write-Host "WARNING: You are about to delete the user $userPrincipalName. This action cannot be undone." -ForegroundColor Yellow
$confirmation = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirmation -ne 'Y') {
    Write-Output "Operation cancelled."
    exit
}

# Delete the specified user
try {
    Write-Output "Deleting user $userPrincipalName..."
    Remove-MgUser -UserId $userPrincipalName -ErrorAction Stop
    Write-Output "User $userPrincipalName has been deleted."
}
catch {
    Write-Error "Error deleting user: $_"
}

Write-Output "Script completed successfully."
