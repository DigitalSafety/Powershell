# Dynamically get the current username and the user's profile directory
$directory = "$env:USERPROFILE"
$cutoffDate = Get-Date "2024-05-05"
$foldersToCreate = @("Desktop", "Documents", "Downloads")

# Function to forcefully clear the contents of a folder, including subfolders
function Clear-Folder {
    param(
        [string]$path
    )
    
    if (Test-Path $path) {
        try {
            # Use Remove-Item with -Recurse and -Force to remove everything inside the folder
            Get-ChildItem -Path $path -Recurse | ForEach-Object {
                try {
                    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
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

# First, delete all files modified after the cutoff date
$items = Get-ChildItem -Path $directory -Recurse
foreach ($item in $items) {
    $lastWriteTime = $item.LastWriteTime

    # Ensure the item is a file and NOT a directory, and the file was modified after the cutoff date
    if ($item.PSIsContainer -eq $false -and $lastWriteTime -gt $cutoffDate) {
        try {
            Remove-Item -Path $item.FullName -Force -ErrorAction Stop
            Write-Host "Deleted file: $($item.FullName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to delete file: $($item.FullName)" -ForegroundColor Red
        }
    }
}

# Clear out the important folders (Desktop, Documents, Downloads)
foreach ($folder in $foldersToCreate) {
    $folderPath = Join-Path -Path $directory -ChildPath $folder

    # Call the function to clear the folder's contents
    Clear-Folder -path $folderPath
}

# Recreate important folders if they are missing
foreach ($folder in $foldersToCreate) {
    $folderPath = Join-Path -Path $directory -ChildPath $folder

    if (-not (Test-Path -Path $folderPath)) {
        try {
            New-Item -Path $folderPath -ItemType Directory
            Write-Host "Recreated folder: $folderPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to recreate folder: $folderPath" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Folder already exists: $folderPath" -ForegroundColor Yellow
    }
}
