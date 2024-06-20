# This script installs the Microsoft Graph PowerShell module if not already installed,
# connects to Microsoft Graph using device code authentication, retrieves all devices and their details,
# including owner information, checks for recent activity, and exports the results to a CSV file and displays it in a table format.

# Install the Microsoft Graph PowerShell module if not already installed
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

# Connect to Microsoft Graph using device code authentication
try {
    Write-Output "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes "Device.Read.All", "Directory.Read.All"
    Write-Output "Connected to Microsoft Graph."
}
catch {
    Write-Error "Error connecting to Microsoft Graph: $_"
    exit
}

# Verify connection
try {
    Get-MgUser -Top 1 | Out-Null
    Write-Output "Verified connection to Microsoft Graph."
}
catch {
    Write-Error "Failed to verify connection to Microsoft Graph: $_"
    exit
}

# Define a threshold for recent activity (e.g., 30 days)
$recentThreshold = (Get-Date).AddDays(-30)

# Retrieve all devices
try {
    Write-Output "Retrieving all devices..."
    $devices = Get-MgDevice -All
    Write-Output "Retrieved $($devices.Count) devices."
}
catch {
    Write-Error "Error retrieving devices: $_"
    exit
}

# Initialize an array to store device details with owners
$deviceDetails = @()

foreach ($device in $devices) {
    try {
        # Get the registered owner(s) of the device
        $owners = Get-MgDeviceRegisteredOwner -DeviceId $device.Id
        $ownerNames = @()

        foreach ($owner in $owners) {
            try {
                # Get detailed user information
                $user = Get-MgUser -UserId $owner.Id
                $ownerNames += $user.UserPrincipalName
            }
            catch {
                Write-Error "Error retrieving user details for owner $($owner.Id): $_"
            }
        }

        # Check for ApproximateLastSignInDateTime and set it as "N/A" if null
        if ($device.ApproximateLastSignInDateTime) {
            $lastSignIn = [datetime]::Parse($device.ApproximateLastSignInDateTime).ToString("dd/MM/yyyy HH:mm:ss")
        } else {
            $lastSignIn = "N/A"
        }

        # Determine if the device is currently signed in (recently active)
        $currentlySignedIn = if ($lastSignIn -ne "N/A" -and [datetime]::Parse($device.ApproximateLastSignInDateTime) -gt $recentThreshold) {
            "Yes"
        } else {
            "No"
        }

        # Add device details and owner information to the array
        $deviceDetails += [PSCustomObject]@{
            DisplayName                    = $device.DisplayName
            DeviceId                       = $device.Id
            DeviceOS                       = $device.OperatingSystem
            DeviceOSVersion                = $device.OperatingSystemVersion
            AccountEnabled                 = $device.AccountEnabled
            ApproximateLastSignInDateTime  = $lastSignIn
            CurrentlySignedIn              = $currentlySignedIn
            Owners                         = ($ownerNames -join ", ")
        }
    }
    catch {
        Write-Error "Error processing device $($device.DisplayName): $_"
    }
}

# Sort by CurrentlySignedIn and then by ApproximateLastSignInDateTime
$sortedDeviceDetails = $deviceDetails | Sort-Object CurrentlySignedIn, { if ($_.ApproximateLastSignInDateTime -eq "N/A") { [datetime]::MinValue } else { [datetime]::ParseExact($_.ApproximateLastSignInDateTime, "dd/MM/yyyy HH:mm:ss", $null) } } -Descending

# Export to CSV
$csvPath = "DeviceDetailsWithOwnersAndSignInStatus.csv"
try {
    Write-Output "Exporting device details to CSV file..."
    $sortedDeviceDetails | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "Device details exported to $csvPath"
}
catch {
    Write-Error "Error exporting to CSV: $_"
}

# Display in table format
try {
    Write-Output "Displaying device details..."
    $sortedDeviceDetails | Format-Table -AutoSize
}
catch {
    Write-Error "Error displaying device details: $_"
}

Write-Output "Script completed successfully."
