# Ensure the script is run as an administrator
function Check-Administrator {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script! Please run as an Administrator."
        Exit
    } else {
        Write-Host "Administrator check passed."
    }
}

# Function to stop all Edge and related services
function Close-EdgeProcesses {
    Write-Host "Closing Microsoft Edge and related processes..."
    
    # Stop all Edge and Edge-related processes (including msedgewebview2)
    $edgeProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*msedge*" -or $_.ProcessName -like "*edge*" -or $_.ProcessName -like "*msedgewebview2*"
    }

    foreach ($process in $edgeProcesses) {
        try {
            Write-Host "Stopping process: $($process.ProcessName) (ID: $($process.Id))"
            Stop-Process -Id $process.Id -Force
        } catch {
            Write-Host "Failed to stop process: $($process.ProcessName)" -ForegroundColor Red
        }
    }

    # Wait to ensure processes have been fully terminated
    Start-Sleep -Seconds 10
}

# Function to schedule file deletion on reboot using MoveFileEx
function Schedule-DeleteOnReboot {
    param (
        [string]$filePath
    )
    
    Write-Host "Scheduling deletion of $filePath on reboot..."

    try {
        $signature = @"
        [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
        public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
"@
        Add-Type -MemberDefinition $signature -Name "MoveFileEx" -Namespace "Win32"
        $result = [Win32.MoveFileEx]::MoveFileEx($filePath, $null, 4)  # 4 == MOVEFILE_DELAY_UNTIL_REBOOT

        if ($result) {
            Write-Host "Scheduled for deletion on reboot: $filePath" -ForegroundColor Green
        } else {
            $errorMessage = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Host "Failed to schedule deletion: Error code $errorMessage" -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to schedule deletion for: $filePath" -ForegroundColor Red
    }
}

# Function to clear Microsoft Edge history, cache, session, and favorites
function Clear-EdgeData {
    Write-Host "Clearing Microsoft Edge history, cache, session files, and favorites..."

    $edgeUserDataPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
    $edgeHistoryPath = "$edgeUserDataPath\History"
    $edgeCachePath = "$edgeUserDataPath\Cache"
    $edgeFavoritesPath = "$edgeUserDataPath\Bookmarks"
    $edgeSessionPath = "$edgeUserDataPath\Sessions"

    # Ensure Edge processes are closed before deleting files
    Close-EdgeProcesses

    # Remove Edge history file
    if (Test-Path -Path $edgeHistoryPath) {
        try {
            Remove-Item -Path $edgeHistoryPath -Force
            Write-Host "Cleared: $edgeHistoryPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear history: File is locked. Scheduling for deletion on reboot." -ForegroundColor Red
            Schedule-DeleteOnReboot -filePath $edgeHistoryPath
        }
    } else {
        Write-Host "History file not found: $edgeHistoryPath"
    }

    # Remove Edge cache
    if (Test-Path -Path $edgeCachePath) {
        try {
            Remove-Item -Path $edgeCachePath -Recurse -Force
            Write-Host "Cleared: $edgeCachePath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear cache: File is locked. Scheduling for deletion on reboot." -ForegroundColor Red
            Schedule-DeleteOnReboot -filePath $edgeCachePath
        }
    } else {
        Write-Host "Cache directory not found: $edgeCachePath"
    }

    # Remove saved favorites (Bookmarks)
    if (Test-Path -Path $edgeFavoritesPath) {
        try {
            Remove-Item -Path $edgeFavoritesPath -Force
            Write-Host "Cleared saved favorites: $edgeFavoritesPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear favorites: File is locked. Scheduling for deletion on reboot." -ForegroundColor Red
            Schedule-DeleteOnReboot -filePath $edgeFavoritesPath
        }
    } else {
        Write-Host "Favorites (Bookmarks) file not found: $edgeFavoritesPath"
    }

    # Remove Edge session data to prevent session restoration
    if (Test-Path -Path $edgeSessionPath) {
        try {
            Remove-Item -Path $edgeSessionPath -Recurse -Force
            Write-Host "Cleared session data: $edgeSessionPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to clear session data: Files are locked. Scheduling for deletion on reboot." -ForegroundColor Red
            Schedule-DeleteOnReboot -filePath $edgeSessionPath
        }
    } else {
        Write-Host "Session data not found: $edgeSessionPath"
    }
}

# Main script execution
#Check-Administrator

# Clear Microsoft Edge data immediately after admin check
#Clear-EdgeData


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
# Main script execution
Check-Administrator
# Clear Microsoft Edge data immediately after admin check
Clear-EdgeData
Remove-NewPrograms -daysAgo 30
Clear-OldUserFiles -daysOld 30
Empty-RecycleBin
Install-WindowsUpdates

Write-Host "Script completed successfully."

# Add a 10-second pause before reboot
Write-Host "The system will restart in 10 seconds..."
Start-Sleep -Seconds 10

# Add a forced reboot
Write-Host "Forcing system reboot..."
Restart-Computer -Force
