$directory = "C:\Users"
$cutoffDate = Get-Date "2024-05-05"
$items = Get-ChildItem -Path $directory -Recurse

foreach ($item in $items) {
    $lastWriteTime = $item.LastWriteTime

    # Check if the item is a file (not a directory) and was modified after the cutoff date
    if ($item.PSIsContainer -eq $false -and $lastWriteTime -gt $cutoffDate) {
        try {
            Remove-Item -Path $item.FullName -Force -ErrorAction Stop
            Write-Host "Deleted: $($item.FullName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to delete: $($item.FullName)" -ForegroundColor Red
        }
    }
}
