# Path to the file where user details will be recorded
$userDetailsFile = "UserMfaDetails.csv"

# Function to install the AzureAD and MSOnline modules if not already installed
function Install-Modules {
    try {
        Write-Output "Checking if AzureAD module is installed..."
        if (-not (Get-Module -ListAvailable -Name AzureAD)) {
            Write-Output "AzureAD module not found. Installing AzureAD module..."
            Install-Module AzureAD -Scope CurrentUser -Force
            Write-Output "AzureAD module installed."
        } else {
            Write-Output "AzureAD module is already installed."
        }

        Write-Output "Checking if MSOnline module is installed..."
        if (-not (Get-Module -ListAvailable -Name MSOnline)) {
            Write-Output "MSOnline module not found. Installing MSOnline module..."
            Install-Module MSOnline -Scope CurrentUser -Force
            Write-Output "MSOnline module installed."
        } else {
            Write-Output "MSOnline module is already installed."
        }
    }
    catch {
        Write-Error "Error installing modules: $_"
        exit 1
    }
}

# Function to connect to Azure AD and MSOnline
function Connect-Services {
    try {
        Write-Output "Connecting to Azure Active Directory..."
        Connect-AzureAD
        Write-Output "Connected to Azure Active Directory."

        Write-Output "Connecting to MSOnline..."
        Connect-MsolService
        Write-Output "Connected to MSOnline."
    }
    catch {
        Write-Error "Error connecting to services: $_"
        exit 1
    }
}

# Function to retrieve user details and MFA status
function Get-UserMfaDetails {
    Write-Output "Retrieving all users from AzureAD..."
    $users = Get-AzureADUser -All $true
    Write-Output "Retrieved $($users.Count) users."

    # Initialize an array to store user MFA and blocked details
    $userMfaDetails = @()

    foreach ($user in $users) {
        # Initialize MFA status as false
        $mfaEnabled = $false
        $accountEnabled = $true

        try {
            # Check MFA status using Get-MsolUser
            $msolUser = Get-MsolUser -UserPrincipalName $user.UserPrincipalName -ErrorAction Stop
            
            # Check if StrongAuthenticationRequirements is present and non-empty
            if ($msolUser.StrongAuthenticationRequirements -ne $null -and $msolUser.StrongAuthenticationRequirements.Count -gt 0) {
                foreach ($req in $msolUser.StrongAuthenticationRequirements) {
                    if ($req.State -eq "Enabled" -or $req.State -eq "Enforced") {
                        $mfaEnabled = $true
                        break
                    }
                }
            }
        } catch {
            Write-Output "Failed to retrieve MFA methods for user: $($user.UserPrincipalName). Error: $_"
            $mfaEnabled = "Error"
        }

        # Check if the account is enabled or blocked
        $accountEnabled = if ($user.AccountEnabled -eq $true) { "Active" } else { "Blocked" }
        
        # Determine the account type (Member or Guest)
        $accountType = if ($user.UserType -eq "Member") { "Member" } else { "Guest" }

        # Add user MFA, blocked details, and account type to the array
        $userMfaDetails += [PSCustomObject]@{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            MfaEnabled        = $mfaEnabled
            AccountEnabled    = $accountEnabled
            AccountType       = $accountType
        }
    }

    # Log all users and their details
    $userMfaDetails | ForEach-Object { Write-Output "User: $($_.UserPrincipalName), MFA: $($_.MfaEnabled), Account: $($_.AccountEnabled), Type: $($_.AccountType)" }

    # Export to CSV
    try {
        Write-Output "Exporting user details to CSV file..."
        $userMfaDetails | Export-Csv -Path $userDetailsFile -NoTypeInformation
        Write-Output "User details exported to $userDetailsFile"
    }
    catch {
        Write-Error "Error exporting to CSV: $_"
    }

    # Display in table format
    try {
        Write-Output "Displaying user details..."
        $userMfaDetails | Format-Table -AutoSize
    }
    catch {
        Write-Error "Error displaying user details: $_"
    }
}

# Main script logic

# Install necessary modules if not already installed
Install-Modules

# Connect to Azure AD and MSOnline
Connect-Services

# Retrieve user details and MFA status
Get-UserMfaDetails

Write-Output "Script completed successfully."
