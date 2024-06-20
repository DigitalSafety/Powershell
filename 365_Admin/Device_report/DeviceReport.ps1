# This script installs the AzureAD module if not already installed, connects to Azure AD, 
# retrieves all devices, and gathers detailed information about each device and its registered owners.

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

# Connect to Azure AD
try {
    Write-Output "Connecting to Azure Active Directory..."
    Connect-AzureAD
    Write-Output "Connected to Azure Active Directory."
}
catch {
    Write-Error "Error connecting to Azure Active Directory: $_"
    exit
}

# Retrieve all devices
try {
    Write-Output "Retrieving all devices..."
    $devices = Get-AzureADDevice -All $true
    Write-Output "Retrieved $($devices.Count) devices."
}
catch {
    Write-Error "Error retrieving devices: $_"
    exit
}

# Initialize an array to store device details with owners and additional details
$deviceDetails = @()

foreach ($device in $devices) {
    try {
        # Get the registered owner(s) of the device
        $owners = Get-AzureADDeviceRegisteredOwner -ObjectId $device.ObjectId
        $ownerNames = $owners | Select-Object -ExpandProperty UserPrincipalName -Unique

        # Determine the status of each owner
        $ownerStatuses = @()
        foreach ($owner in $owners) {
            $user = Get-AzureADUser -ObjectId $owner.ObjectId
            $status = if ($user.AccountEnabled) { "Active" } else { "Blocked" }
            $ownerStatuses += $status
        }

        # Combine owners and their statuses
        $ownerStatusInfo = @()
        for ($i = 0; $i -lt $ownerNames.Count; $i++) {
            $ownerStatusInfo += "$($ownerNames[$i]) ($($ownerStatuses[$i]))"
        }

        # Check for ApproximateLastSignInDateTime and set it as "Unavailable" if null
        $lastSignIn = if ($device.ApproximateLastSignInDateTime) {
            $device.ApproximateLastSignInDateTime
        } else {
            "Unavailable"
        }

        # Add device details, owner information, and additional details to the array
        $deviceDetails += [PSCustomObject]@{
            DisplayName                    = $device.DisplayName
            DeviceId                       = $device.DeviceId
            DeviceOS                       = $device.DeviceOSType
            DeviceOSVersion                = $device.DeviceOSVersion
            Owners                         = ($ownerNames -join ", ")
            UserStatus                     = ($ownerStatuses -join ", ")
            DeviceTrustType                = $device.DeviceTrustType
            DevicePhysicalIds              = $device.DevicePhysicalIds -join ", "
            ApproximateLastSignInDateTime  = $lastSignIn
        }
    }
    catch {
        Write-Error "Error processing device $($device.DisplayName): $_"
    }
}

# Sort by last sign-in date, placing "Unavailable" at the end
$deviceDetails = $deviceDetails | Sort-Object { if ($_.ApproximateLastSignInDateTime -eq "Unavailable") { [datetime]::MinValue } else { $_.ApproximateLastSignInDateTime } } -Descending

# Export to CSV
$csvPath = "EnabledDevicesWithOwnersAndStatusReport.csv"
try {
    Write-Output "Exporting device details to CSV file..."
    $deviceDetails | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "Device details exported to $csvPath"
}
catch {
    Write-Error "Error exporting to CSV: $_"
}

# Display in table format
try {
    Write-Output "Displaying device details..."
    $deviceDetails | Format-Table -AutoSize
}
catch {
    Write-Error "Error displaying device details: $_"
}

Write-Output "Script completed successfully."
