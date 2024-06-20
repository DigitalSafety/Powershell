# Function to ensure the script is run as an administrator
function Check-Administrator {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script! Please run as an Administrator."
        Exit
    }
}

# Function to connect to Azure AD
function Connect-AzureADService {
    try {
        Write-Output "Connecting to Azure AD..."
        Connect-AzureAD
        Write-Output "Connected to Azure AD."
    }
    catch {
        Write-Error "Error connecting to Azure AD: $_"
        exit 1
    }
}

# Main script logic

# Ensure the script is run as an administrator
Check-Administrator

# Connect to Azure AD
Connect-AzureADService

# Message about password policies
Write-Output "Setting password policies to 'None' ensures that users must create complex passwords."

# Confirm operation with the user
$confirmation = Read-Host "This operation will set password policies to 'None' for all users, ensuring they must use complex passwords. Do you want to proceed? (Y/N)"
if ($confirmation -ne 'Y') {
    Write-Output "Operation cancelled."
    exit 0
}

# Get all users and set their password policies to "None"
try {
    $users = Get-AzureADUser -All $true
    $totalUsers = $users.Count
    $counter = 0

    foreach ($user in $users) {
        $counter++
        Write-Progress -Activity "Updating password policies" -Status "Processing user $counter of $totalUsers" -PercentComplete (($counter / $totalUsers) * 100)
        Set-AzureADUser -ObjectId $user.ObjectId -PasswordPolicies "None" -ErrorAction Stop
    }

    Write-Output "Password policies have been set to 'None' for all users."
}
catch {
    Write-Error "Error setting password policies: $_"
    exit 1
}

Write-Output "Script completed successfully."
