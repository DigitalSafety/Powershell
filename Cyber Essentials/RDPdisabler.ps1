# Function to check and disable Remote Desktop Protocol (RDP)
function Check-DisableRDP {
    Write-Host "`nChecking Remote Desktop Protocol (RDP) Status..." -ForegroundColor Cyan

    # Get the current RDP status from the registry
    $rdpStatus = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections

    if ($rdpStatus -eq 0) {
        Write-Host "❌ RDP is ENABLED! This is a security risk." -ForegroundColor Red
        Write-Host "Fixing issue: Disabling RDP..." -ForegroundColor Yellow

        # Disable RDP
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1

        # Ensure Remote Desktop services are disabled
        Get-Service -Name TermService | Stop-Service -Force
        Set-Service -Name TermService -StartupType Disabled

        Write-Host "✅ RDP has been DISABLED for security." -ForegroundColor Green
    } else {
        Write-Host "✅ RDP is already DISABLED." -ForegroundColor Green
    }
}

# Run the function
Check-DisableRDP
