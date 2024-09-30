# Ensure the script is run as an administrator
function Check-Administrator {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script! Please run as an Administrator."
        Exit
    } else {
        Write-Host "Administrator check passed."
    }
}

# Function to remove non-essential programs installed in the last 30 days
function Remove-NewPrograms {
    param (
        [int]$daysAgo = 30
    )

    Write-Host "Removing non-essential programs installed in the last $daysAgo days..."

    # Get the full path of the script to avoid deleting it
    $scriptPath = "C:\Program Files\CourseCleanUp.ps1"

    # Get the cutoff date for the past X days
    $cutoffDate = (Get-Date).AddDays(-$daysAgo)

    # Paths to check for installed programs
    $programPaths = @(
        "C:\Program Files",
        "C:\Program Files (x86)"
    )

    foreach ($path in $programPaths) {
        Get-ChildItem -Path $path -Directory | ForEach-Object {
            # Skip the directory if it contains CourseCleanUp.ps1
            if ($_.FullName -eq "C:\Program Files" -and (Test-Path $scriptPath)) {
                Write-Host "Skipping: $($_.FullName) because it contains CourseCleanUp.ps1" -ForegroundColor Yellow
            } elseif ($_.LastWriteTime -gt $cutoffDate) {
                try {
                    # Try to remove the directory, ignoring protected and in-use ones
                    Remove-Item -Recurse -Force -Path $_.FullName -ErrorAction Stop
                    Write-Host "Removed: $($_.FullName)" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove: $($_.FullName). It might be protected or in use." -ForegroundColor Red
                }
            }
        }
    }

    Write-Host "Program removal completed."
}


# Function to clear old user files older than 30 days
function Clear-OldUserFiles {
    param (
        [int]$daysOld = 30
    )

    Write-Host "Clearing old user files older than $daysOld days..."

    $foldersToClean = @("Documents", "Downloads", "Pictures")
    $cutoffDate = (Get-Date).AddDays(-$daysOld)

    # Loop through all user profiles
    Get-ChildItem "C:\Users" | ForEach-Object {
        $userProfile = $_.FullName

        foreach ($folder in $foldersToClean) {
            $userFolder = "$userProfile\$folder"
            if (Test-Path $userFolder) {
                Get-ChildItem -Path $userFolder -Recurse | Where-Object { $_.LastWriteTime -lt $cutoffDate } | ForEach-Object {
                    try {
                        Remove-Item -Recurse -Force -Path $_.FullName
                        Write-Host "Deleted: $($_.FullName)" -ForegroundColor Green
                    } catch {
                        Write-Host "Failed to delete: $($_.FullName). It might be in use or protected." -ForegroundColor Red
                    }
                }
            }
        }
    }
    Write-Host "Old user files cleared."
}

# Function to reset Microsoft Edge data for all users
function Reset-EdgeData {
    Write-Host "Resetting Microsoft Edge data for all users..."

    # Ensure Edge is not running
    $edgeProcesses = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
    if ($edgeProcesses) {
        Write-Host "Stopping Microsoft Edge processes..."
        Stop-Process -Name "msedge" -Force
        Write-Host "Microsoft Edge processes stopped."
    }

    Get-ChildItem "C:\Users" | ForEach-Object {
        $userProfile = $_.FullName
        $edgeDataPath = "$userProfile\AppData\Local\Microsoft\Edge\User Data\Default"

        if (Test-Path $edgeDataPath) {
            $filesToClear = @("History", "Cache", "Cookies", "Top Sites", "Preferences", "Visited Links", "Sessions")

            foreach ($file in $filesToClear) {
                $filePath = "$edgeDataPath\$file"
                if (Test-Path $filePath) {
                    try {
                        Remove-Item -Recurse -Force -Path $filePath -ErrorAction Stop
                        Write-Host "Cleared: $filePath" -ForegroundColor Green
                    } catch {
                        Write-Host "Failed to clear: $filePath. File may be locked or in use." -ForegroundColor Red
                    }
                } else {
                    Write-Host "Path not found: $filePath" -ForegroundColor Yellow
                }
            }
        }
    }

    Write-Host "Microsoft Edge reset completed."
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
    Write-Host "Installing Windows updates..."
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -AutoReboot
        Write-Host "Windows updates installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Windows updates: $_" -ForegroundColor Red
    }
}

# Main script logic
Check-Administrator
Remove-NewPrograms -daysAgo 30
Clear-OldUserFiles -daysOld 30
Reset-EdgeData
Empty-RecycleBin
Install-WindowsUpdates

Write-Host "Script completed successfully."
