# Path to the file where blocked device IDs will be recorded
$blockedDevicesFile = "BlockedDevices.txt"

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

# Function to block a device by its Device ID using Microsoft Graph
function Block-DeviceById {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeviceId
    )

    try {
        # Trim any extra spaces from the Device ID
        $DeviceId = $DeviceId.Trim()

        Write-Output "Retrieving device information for Device ID $DeviceId..."
        $device = Get-MgDevice -DeviceId $DeviceId

        if ($device) {
            Write-Output "Device found. Blocking the device..."
            # Block the device by setting AccountEnabled to false
            $body = @{
                accountEnabled = $false
            }
            Update-MgDevice -DeviceId $DeviceId -BodyParameter $body
            Write-Output "Device with ID $DeviceId has been blocked."
            Log-DeviceId -DeviceId $DeviceId
        } else {
            Write-Output "Device with ID $DeviceId not found, recording for future reference."
            Log-DeviceId -DeviceId $DeviceId
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Output "Device with ID $DeviceId not found, recording for future reference."
            Log-DeviceId -DeviceId $DeviceId
        } elseif ($_.Exception.Response.StatusCode -eq 403) {
            Write-Output "Error: Insufficient permissions to block device with ID $DeviceId."
        } elseif ($_.Exception.Response.StatusCode -eq 401) {
            Write-Output "Error: Unauthorized access. Please check your permissions and ensure you have 'Device.ReadWrite.All' permissions."
        } else {
            Write-Error "Error blocking device: $_"
        }
    }
}

# Main script logic

# Install Microsoft.Graph module if not already installed
Install-MicrosoftGraphModule

# Connect to Microsoft Graph
Connect-MicrosoftGraph

# Retrieve and list all devices
try {
    Write-Output "Retrieving all devices..."
    $devices = Get-MgDevice -All
    Write-Output "Retrieved $($devices.Count) devices."
}
catch {
    Write-Error "Error retrieving devices: $_"
    exit
}

# Display devices
$devices | Format-Table DisplayName, Id, OperatingSystem, OperatingSystemVersion, ApproximateLastSignInDateTime, AccountEnabled

# Prompt for Device ID
$deviceId = Read-Host "Enter Device ID to block the device"

# Trim any extra spaces from the Device ID
$deviceId = $deviceId.Trim()

# Warning and confirmation
Write-Host "WARNING: You are about to block the device with ID $deviceId. This action cannot be undone." -ForegroundColor Yellow
$confirmation = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirmation -ne 'Y') {
    Write-Output "Operation cancelled."
    exit 0
}

# Block the specified device
Block-DeviceById -DeviceId $deviceId

Write-Output "Script completed successfully."
