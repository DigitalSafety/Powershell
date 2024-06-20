# Ensure the script is run as an administrator
function Check-Administrator {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script! Please run as an Administrator."
        Exit
    }
}

# Function to install the PSWindowsUpdate module if not already installed
function Install-PSWindowsUpdateModule {
    try {
        if (-Not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Output "PSWindowsUpdate module not found. Installing PSWindowsUpdate module..."
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
            Write-Output "PSWindowsUpdate module installed."
        } else {
            Write-Output "PSWindowsUpdate module is already installed."
        }
    }
    catch {
        Write-Error "Error installing PSWindowsUpdate module: $_"
        Exit
    }
}

# Function to import the PSWindowsUpdate module
function Import-PSWindowsUpdateModule {
    try {
        Write-Output "Importing PSWindowsUpdate module..."
        Import-Module PSWindowsUpdate
        Write-Output "PSWindowsUpdate module imported."
    }
    catch {
        Write-Error "Error importing PSWindowsUpdate module: $_"
        Exit
    }
}

# Function to check for updates
function Check-Updates {
    try {
        Write-Output "Checking for updates..."
        $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll
        return $updates
    }
    catch {
        Write-Error "Error checking for updates: $_"
        Exit
    }
}

# Function to install updates
function Install-Updates {
    param (
        [Parameter(Mandatory=$true)]
        [array]$updates
    )

    if ($updates) {
        try {
            Write-Output "Installing updates..."
            $results = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot:$false
            Write-Output "Updates installation results:"
            $results | Format-Table -AutoSize
            return $results
        }
        catch {
            Write-Error "Error installing updates: $_"
            Exit
        }
    } else {
        Write-Output "No updates found."
    }
}

# Function to restart the computer
function Restart-ComputerIfNecessary {
    param (
        [Parameter(Mandatory=$true)]
        [array]$updateResults
    )

    if ($updateResults) {
        $rebootRequired = $updateResults | Where-Object { $_.Result -eq 'Installed' -and $_.RebootRequired }
        if ($rebootRequired) {
            $confirmation = Read-Host "Updates require a restart. Do you want to restart the computer now? (Y/N)"
            if ($confirmation -eq 'Y') {
                Write-Output "Restarting the computer..."
                Restart-Computer -Force
            } else {
                Write-Output "Restart skipped. Please remember to restart the computer later."
            }
        } else {
            Write-Output "No restart required."
        }
    }
}

# Main script logic
Check-Administrator
Install-PSWindowsUpdateModule
Import-PSWindowsUpdateModule
$updates = Check-Updates
$updateResults = Install-Updates -updates $updates
Restart-ComputerIfNecessary -updateResults $updateResults

Write-Output "Script completed successfully."
