# Ensure the script is run as an administrator
function Check-Administrator {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script! Please run as an Administrator."
        Exit
    } else {
        Write-Host "Administrator check passed."
    }
}

# Function to remove non-system programs installed after a specific date
function Remove-NewPrograms {
    param (
        [DateTime]$cutoffDate
    )

    Write-Host "Removing newly installed programs since $cutoffDate..."

    # Define program directories (non-system)
    $programDirs = @(
        "C:\Program Files\Custom Programs",  # Non-system directory (adjust accordingly)
        "C:\Program Files (x86)\Custom Programs"  # Non-system directory (adjust accordingly)
    )

    foreach ($path in $programDirs) {
        try {
            Get-ChildItem -Path $path -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { 
                $_.CreationTime -gt $cutoffDate
            } | ForEach-Object {
                Write-Host "Removing program: $($_.FullName)"
                try {
                    Remove-Item -Recurse -Force -Path $_.FullName -ErrorAction Stop
                    Write-Host "Removed: $($_.FullName)" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove: $($_.FullName). The program might be locked." -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "Failed to get directory listing for: $path" -ForegroundColor Red
        }
    }

    Write-Host "Program removal completed."
}

# Function to clear user-specific data from AppData\Local
function Clear-LocalAppData {
    param (
        [string]$username
    )

    $appDataPath = "C:\Users\$username\AppData\Local"
    Write-Host "Clearing data from AppData\Local for user: $username"

    $excludeDirs = @("Microsoft", "Temp", "Packages", "ConnectedDevicesPlatform")  # Exclude system/important directories

    Get-ChildItem -Path $appDataPath -Directory | Where-Object { $_.Name -notin $excludeDirs } | ForEach-Object {
        try {
            Remove-Item -Recurse -Force -Path $_.FullName
            Write-Host "Cleared: $($_.FullName)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear: $($_.FullName). File might be in use or locked." -ForegroundColor Red
        }
    }

    Write-Host "AppData\Local cleanup complete for user: $username"
}

# Function to clear browser data for specific browsers
function Clear-BrowserData {
    Write-Host "Clearing browser data..."

    # Edge
    $edgeCache = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
    if (Test-Path -Path $edgeCache) {
        try {
            Remove-Item -Recurse -Force -Path $edgeCache
            Write-Host "Cleared data for Edge." -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear data for Edge: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Edge data not found."
    }

    # Chrome
    $chromeCache = "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Cache"
    if (Test-Path -Path $chromeCache) {
        try {
            Remove-Item -Recurse -Force -Path $chromeCache
            Write-Host "Cleared data for Chrome." -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear data for Chrome: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Chrome not found."
    }

    # Firefox
    $firefoxProfile = "C:\Users\$env:USERNAME\AppData\Roaming\Mozilla\Firefox\Profiles"
    if (Test-Path -Path $firefoxProfile) {
        try {
            Remove-Item -Recurse -Force -Path $firefoxProfile
            Write-Host "Cleared data for Firefox." -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear data for Firefox: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Firefox not found."
    }

    # Brave
    $braveCache = "C:\Users\$env:USERNAME\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache"
    if (Test-Path -Path $braveCache) {
        try {
            Remove-Item -Recurse -Force -Path $braveCache
            Write-Host "Cleared data for Brave." -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear data for Brave: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Brave not found."
    }
}

# Function to empty the Recycle Bin
function Empty-RecycleBin {
    Write-Host "Emptying the Recycle Bin..."
    try {
        Clear-RecycleBin -Force
        Write-Host "Recycle Bin emptied." -ForegroundColor Green
    } catch {
        Write-Host "Failed to empty the Recycle Bin: $_" -ForegroundColor Red
    }
}

# Function to install Windows updates
function Install-WindowsUpdates {
    Write-Host "PSWindowsUpdate module is already installed."
    Write-Host "Importing PSWindowsUpdate module..."
    try {
        Import-Module PSWindowsUpdate
        Write-Host "PSWindowsUpdate module imported."
    } catch {
        Write-Host "Failed to import PSWindowsUpdate module: $_" -ForegroundColor Red
    }

    Write-Host "Checking for updates..."
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll
    if ($updates) {
        Write-Host "Installing updates..."
        $updateResults = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot:$false
        Write-Host "Updates installed."
    } else {
        Write-Host "No updates found."
    }
}

# Main script logic
Check-Administrator

# Remove newly installed non-system programs
$cutoffDate = (Get-Date).AddMonths(-6)
Remove-NewPrograms -cutoffDate $cutoffDate

# Clear AppData\Local for specific users
Clear-LocalAppData -username "admin"
Clear-LocalAppData -username "vagrant"

# Clear browser data
Clear-BrowserData

# Empty the Recycle Bin
Empty-RecycleBin

# Install Windows Updates
Install-WindowsUpdates

Write-Host "Script completed successfully."
