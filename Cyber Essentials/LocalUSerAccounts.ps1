# Get all local user accounts
$users = Get-WmiObject Win32_UserAccount | Select-Object Name, Disabled, LocalAccount, SID, Status

# Create a formatted output
Write-Host "User Accounts on This Computer" -ForegroundColor Cyan
Write-Host "--------------------------------"

foreach ($user in $users) {
    # Determine account type
    $isAdmin = $false
    $groups = net localgroup Administrators 2>$null
    if ($groups -match "\b$user.Name\b") {
        $isAdmin = $true
    }

    # Determine status
    $status = if ($user.Disabled) {"DISABLED"} else {"ENABLED"}
    $accountType = if ($isAdmin) {"Administrator"} else {"Standard User"}

    # Display user information
    Write-Host "Username: $($user.Name) | Status: $status | Type: $accountType" -ForegroundColor Yellow
}

Write-Host "`nTotal Accounts Found: $($users.Count)" -ForegroundColor Green
