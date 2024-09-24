# Dynamically get the current username and the user's profile directory
$directory = "$env:USERPROFILE"
$cutoffDate = Get-Date "2024-05-05"
$items = Get-ChildItem -Path $directory -Recurse

# List of important folders to recreate
$foldersToCreate = @("Desktop", "Documents", "Downloads")

# First, loop through files and delete those modified after the cutoff date
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

# Next, ensure subdirectories inside the target folders are removed
foreach ($folder in $foldersToCreate) {
    $folderPath = Join-Path -Path $directory -ChildPath $folder

    if (Test-Path -Path $folderPath) {
        # Get all items (files and directories) within the folder
        $folderItems = Get-ChildItem -Path $folderPath -Recurse

        # Remove all items within the folder
        foreach ($item in $folderItems) {
            try {
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "Deleted: $($item.FullName)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to delete: $($item.FullName)" -ForegroundColor Red
            }
        }
    }
}

# Finally, recreate important folders if they are missing
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
