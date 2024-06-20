# This script installs the AzureAD module (if not already installed), connects to Azure Active Directory,
# retrieves the list of users, and outputs the results to the screen and a CSV file.

# Install AzureAD module if not already installed
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

# Connect to Azure Active Directory
try {
    Write-Output "Connecting to Azure Active Directory..."
    Connect-AzureAD
    Write-Output "Connected to Azure Active Directory."
}
catch {
    Write-Error "Error connecting to Azure Active Directory: $_"
    exit
}

# Initialize a variable to store the output
$output = ""

# Retrieve and display the list of users
try {
    Write-Output "Retrieving the list of users..."
    $users = Get-AzureADUser -All $true | Select-Object DisplayName, UserPrincipalName, AccountEnabled, UserType
    $output += "List of users:`n"
    $users | ForEach-Object { 
        $userInfo = "$($_.DisplayName) - $($_.UserPrincipalName) - $($_.AccountEnabled) - $($_.UserType)"
        Write-Output $userInfo
        $output += $userInfo + "`n"
    }
}
catch {
    Write-Error "Error retrieving users: $_"
    exit
}

# Save the result to a CSV file
$fileName = "UsersStatus.csv"
$outputPath = Join-Path -Path (Get-Location) -ChildPath $fileName

try {
    Write-Output "Saving results to CSV file..."
    $users | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Output "Results saved to $outputPath"
}
catch {
    Write-Error "Error saving results to CSV file: $_"
}

# Save the result to a text file
$textFileName = "UsersStatus.txt"
$textOutputPath = Join-Path -Path (Get-Location) -ChildPath $textFileName

try {
    Write-Output "Saving results to text file..."
    $output | Out-File -FilePath $textOutputPath -Encoding utf8
    Write-Output "Results saved to $textOutputPath"
}
catch {
    Write-Error "Error saving results to text file: $_"
}

Write-Output "Script completed successfully."
