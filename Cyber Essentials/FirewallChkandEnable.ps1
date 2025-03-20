# Function to check and enable Windows Firewall
function Check-FirewallStatus {
    Write-Host "`nChecking Windows Firewall Status..." -ForegroundColor Cyan

    # Get firewall status for all profiles
    $firewallProfiles = Get-NetFirewallProfile | Select-Object Name, Enabled

    $issuesFound = $false

    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "ENABLED ✅" } else { "DISABLED ❌" }
        Write-Host "$($profile.Name) Firewall: $status"

        # If the firewall is disabled, enable it
        if (-not $profile.Enabled) {
            Write-Host "Fixing issue: Enabling $($profile.Name) Firewall..." -ForegroundColor Yellow
            Set-NetFirewallProfile -Profile $profile.Name -Enabled True
            $issuesFound = $true
        }
    }

    if ($issuesFound) {
        Write-Host "`n✅ Firewall was disabled and has been enabled!" -ForegroundColor Green
    } else {
        Write-Host "`n✅ No issues found. Firewall is already enabled." -ForegroundColor Green
    }
}

# Run the function
Check-FirewallStatus
