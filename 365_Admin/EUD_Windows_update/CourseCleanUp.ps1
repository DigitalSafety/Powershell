param (
    [string]$cutoffDate = (Get-Date).AddDays(-30)  # Default to 30 days before today
)

# Set execution policy if needed
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne "RemoteSigned") {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
}

# Function to check if the script is run as an administrator
function Check-Administrator {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script! Please run as an Administrator."
        Exit
    }
}

# Function to forcefully clear the contents of a folder, including subfolders
function Clear-Folder {
    param(
        [string]$path
    )
    
    if (Test-Path $path) {
        try {
            # Use Remove-Item with -Recurse and -Force to remove everything inside the folder and auto-confirm
            Get-ChildItem -Path $path -Recurse | ForEach-Object {
                try {
                    Remove-Item -LiteralPath $_.FullName -Recurse -Force -Confirm:$false -ErrorAction Stop
                    Write-Host "Deleted: $($_.FullName)" -ForegroundColor Green
                }
                catch {
                    Write-Host "Failed to delete: $($_.FullName)" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Failed to clear folder: $path" -ForegroundColor Red
        }
    }
}

# Function to remove newly installed programs from Program Files and Program Files (x86), except the CourseCleanUp script
function Remove-NewPrograms {
    $programPaths = @(
        "C:\Program Files",
        "C:\Program Files (x86)"
    )
    
    # Get the full path of this script so we can exclude it
    $thisScript = $MyInvocation.MyCommand.Definition
    
    foreach ($programPath in $programPaths) {
        if (Test-Path $programPath) {
            $items = Get-ChildItem -Path $programPath | Where-Object { $_.PSIsContainer -eq $true -and $_.LastWriteTime -gt $cutoffDate }
            foreach ($item in $items) {
                if ($item.FullName -ne $thisScript) {  # Exclude the script from deletion
                    try {
                        Remove-Item -LiteralPath $item.FullName -Recurse -Force -Confirm:$false -ErrorAction Stop
                        Write-Host "Removed newly installed program: $($item.FullName)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed to remove: $($item.FullName)" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

# Function to clear web browser history from Google Chrome, Mozilla Firefox, Microsoft Edge, and Brave
function Clear-BrowserHistory {
    $userProfile = "$env:USERPROFILE"
    
    # Chrome History
    $chromeHistoryPath = Join-Path -Path $userProfile -ChildPath "AppData\Local\Google\Chrome\User Data\Default"
    if (Test-Path $chromeHistoryPath) {
        try {
            Remove-Item "$chromeHistoryPath\History" -Force -Confirm:$false -ErrorAction Stop
            Write-Host "Cleared Chrome History." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to clear Chrome History." -ForegroundColor Red
        }
    }

    # Firefox History
    $firefoxHistoryPath = Join-Path -Path $userProfile -ChildPath "AppData\Roaming\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxHistoryPath) {
        Get-ChildItem -Path $firefoxHistoryPath | ForEach-Object {
            try {
                Remove-Item "$($_.FullName)\places.sqlite" -Force -Confirm:$false -ErrorAction Stop
                Write-Host "Cleared Firefox History." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to clear Firefox History." -ForegroundColor Red
            }
        }
    }

    # Microsoft Edge History
    $edgeHistoryPath = Join-Path -Path $userProfile -ChildPath "AppData\Local\Microsoft\Edge\User Data\Default"
    if (Test-Path $edgeHistoryPath) {
        try {
            Remove-Item "$edgeHistoryPath\History" -Force -Confirm:$false -ErrorAction Stop
            Write-Host "Cleared Edge History." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to clear Edge History." -ForegroundColor Red
        }
    }

    # Brave History
    $braveHistoryPath = Join-Path -Path $userProfile -ChildPath "AppData\Local\BraveSoftware\Brave-Browser\User Data\Default"
    if (Test-Path $braveHistoryPath) {
        try {
            Remove-Item "$braveHistoryPath\History" -Force -Confirm:$false -ErrorAction Stop
            Write-Host "Cleared Brave History." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to clear Brave History." -ForegroundColor Red
        }
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
            $results = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot:$false -Force
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

# Function to restart the computer if necessary
function Restart-ComputerIfNecessary {
    param (
        [Parameter(Mandatory=$true)]
        [array]$updateResults
    )

    if ($updateResults) {
        $rebootRequired = $updateResults | Where-Object { $_.Result -eq 'Installed' -and $_.RebootRequired }
        if ($rebootRequired) {
            Write-Output "Restarting the computer automatically..."
            Restart-Computer -Force
        } else {
            Write-Output "No restart required."
        }
    }
}

# Main script execution order - Cleanup first, updates last

Check-Administrator

# Step 1: Cleanup and remove programs
Write-Host "Starting system cleanup and program removal..." -ForegroundColor Yellow
Manage-FoldersAndFiles  # Cleans up user folders
Clear-BrowserHistory    # Clears browser histories
Remove-NewPrograms      # Removes newly installed programs after the cutoff date

# Step 2: Install Windows updates after cleanup
Write-Host "Cleanup complete. Now checking for Windows updates..." -ForegroundColor Yellow
Install-PSWindowsUpdateModule
Import-PSWindowsUpdateModule
$updates = Check-Updates
$updateResults = Install-Updates -updates $updates

# Step 3: Restart the system if necessary
Restart-ComputerIfNecessary -updateResults $updateResults

Write-Output "Script completed successfully."

