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
        exit 1
    }
}

# Function to connect to Microsoft Graph and ensure proper authentication
function Connect-MicrosoftGraph {
    try {
        Write-Output "Connecting to Microsoft Graph..."
        $context = Get-MgContext
        if ($null -eq $context) {
            Connect-MgGraph -Scopes "Device.Read.All", "Device.ReadWrite.All", "User.Read.All" -ErrorAction Stop
        } else {
            Disconnect-MgGraph -ErrorAction Stop
            Connect-MgGraph -Scopes "Device.Read.All", "Device.ReadWrite.All", "User.Read.All" -ErrorAction Stop
        }
        Write-Output "Connected to Microsoft Graph."
    }
    catch {
        Write-Error "Error connecting to Microsoft Graph: $_"
        exit 1
    }
}

# Function to log the device ID for future reference
function Log-DeviceId {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeviceId
    )
    try {
        if (-not (Test-Path $blockedDevicesFile)) {
            New-Item -Path $blockedDevicesFile -ItemType File -Force | Out-Null
        }
        Add-Content -Path $blockedDevicesFile -Value $DeviceId
        Write-Output "Device ID $DeviceId has been recorded for future reference."
    }
    catch {
        Write-Error "Error recording device ID: $_"
    }
}

# Function to retrieve and list blocked devices with their details
function List-BlockedDevices {
    try {
        Write-Output "Retrieving all devices..."
        $devices = Get-MgDevice -All

        Write-Output "Processing blocked devices..."
        # Initialize an array to store blocked device details
        $blockedDevices = @()

        foreach ($device in $devices) {
            # Check if the device is blocked
            if ($device.AccountEnabled -eq $false) {
                # Get the registered owner(s) of the device
                $owners = Get-MgDeviceRegisteredOwner -DeviceId $device.Id

                # Initialize arrays for owner details
                $ownerEmails = @()

                foreach ($owner in $owners) {
                    # Get detailed user information
                    $user = Get-MgUser -UserId $owner.Id -ErrorAction SilentlyContinue
                    if ($user) {
                        $ownerEmails += $user.UserPrincipalName
                    }
                }

                # Combine owner emails
                $ownerEmailsStr = if ($ownerEmails.Count -gt 0) { $ownerEmails -join ", " } else { "N/A" }

                # Add blocked device details to the array
                $blockedDevices += [PSCustomObject]@{
                    DisplayName                    = $device.DisplayName
                    DeviceId                       = $device.Id
                    DeviceOS                       = $device.OperatingSystem
                    DeviceOSVersion                = $device.OperatingSystemVersion
                    ApproximateLastSignInDateTime  = if ($device.ApproximateLastSignInDateTime) { [datetime]::Parse($device.ApproximateLastSignInDateTime).ToString("dd/MM/yyyy HH:mm:ss") } else { "N/A" }
                    AssociatedUserEmails           = $ownerEmailsStr
                }
            }
        }

        # Export to CSV
        $blockedDevices | Export-Csv -Path "BlockedDevicesWithUserEmails.csv" -NoTypeInformation

        # Display in table format
        $blockedDevices | Format-Table -AutoSize
    }
    catch {
        Write-Error "Error retrieving blocked devices: $_"
    }
}

# Main script logic

# Install Microsoft.Graph module if not already installed
Install-MicrosoftGraphModule

# Connect to Microsoft Graph
Connect-MicrosoftGraph

# List blocked devices
List-BlockedDevices
