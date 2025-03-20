# Function to check and enable Windows Auto Updates
function Check-AutoUpdates {
    Write-Host "`nChecking Windows Auto Updates Status..." -ForegroundColor Cyan

    # Check Windows Update service status
    $updateService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    if ($updateService.Status -ne "Running") {
        Write-Host "❌ Windows Update service is not running!" -ForegroundColor Red
        Write-Host "Fixing issue: Starting Windows Update service..." -ForegroundColor Yellow
        Start-Service wuauserv
        Set-Service wuauserv -StartupType Automatic
    } else {
        Write-Host "✅ Windows Update service is running." -ForegroundColor Green
    }

    # Check if Automatic Updates are enabled in Group Policy
    $updatePolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue
    if ($updatePolicy.NoAutoUpdate -eq 1) {
        Write-Host "❌ Auto Updates are DISABLED in Group Policy!" -ForegroundColor Red
        Write-Host "Fixing issue: Enabling Automatic Updates..." -ForegroundColor Yellow
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0
    } else {
        Write-Host "✅ Auto Updates are ENABLED." -ForegroundColor Green
    }

    # Ensure Windows Update is configured for automatic updates
    $updateMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").AUOptions
    if ($updateMode -lt 4) {
        Write-Host "❌ Automatic Updates are not set to install updates automatically!" -ForegroundColor Red
        Write-Host "Fixing issue: Configuring Auto Updates to install updates automatically..." -ForegroundColor Yellow
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 4
    } else {
        Write-Host "✅ Auto Updates are set to install updates automatically." -ForegroundColor Green
    }

    Write-Host "`n✅ Windows Auto Updates are now correctly configured and secured." -ForegroundColor Green
}

# Run the function
Check-AutoUpdates
