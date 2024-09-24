$directory = "C:\Users"
$cutoffDate = Get-Date "2024-05-05"
$files = Get-ChildItem -Path $directory -Recurse
foreach ($file in $files) {
   $lastWriteTime = $file.LastWriteTime
   if ($lastWriteTime -gt $cutoffDate) {
       try {
           Remove-Item -Path $file.FullName -Force -ErrorAction Stop
           Write-Host "Deleted: $($file.FullName)" -ForegroundColor Green
       }
       catch {
           Write-Host "Failed to delete: $($file.FullName)" -ForegroundColor Red
       }
   }
}
