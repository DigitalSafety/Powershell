# Function to check authentication security
function Check-AuthenticationSecurity {
    Write-Host "`nChecking Authentication Security Settings..." -ForegroundColor Cyan

    # Check if Windows Hello for Business is enabled (Alternative to MFA check)
    $helloStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    if ($helloStatus -eq 1) {
        Write-Host "✅ Windows Hello for Business is ENABLED." -ForegroundColor Green
    } else {
        Write-Host "❌ Windows Hello for Business is NOT enabled!" -ForegroundColor Red
    }

    # Check password policy (Minimum Length)
    $minPasswordLength = (net accounts | Select-String "Minimum password length").ToString() -match "\d+" | Out-Null
    $minPasswordLength = $matches[0]

    if ($minPasswordLength -ge 12) {
        Write-Host "✅ Strong password policy is enforced (Minimum length: $minPasswordLength characters)." -ForegroundColor Green
    } else {
        Write-Host "❌ Weak password policy detected (Minimum length: $minPasswordLength characters)." -ForegroundColor Red
        Write-Host "Fixing issue: Setting minimum password length to 12 characters..." -ForegroundColor Yellow
        net accounts /minpwlen:12
    }

    # Check if the system allows blank passwords
    $allowBlankPasswords = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa").LimitBlankPasswordUse
    if ($allowBlankPasswords -eq 1) {
        Write-Host "✅ Blank passwords are NOT allowed." -ForegroundColor Green
    } else {
        Write-Host "❌ Blank passwords are ALLOWED!" -ForegroundColor Red
        Write-Host "Fixing issue: Disabling blank passwords..." -ForegroundColor Yellow
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 1
    }

    # Check if accounts are locked after failed login attempts
    $lockoutThreshold = (net accounts | Select-String "Lockout threshold").ToString() -match "\d+" | Out-Null
    $lockoutThreshold = $matches[0]

    if ($lockoutThreshold -ge 5) {
        Write-Host "✅ Account lockout is enabled after $lockoutThreshold failed attempts." -ForegroundColor Green
    } else {
        Write-Host "❌ No proper account lockout policy detected!" -ForegroundColor Red
        Write-Host "Fixing issue: Setting account lockout after 5 failed attempts..." -ForegroundColor Yellow
        net accounts /lockoutthreshold:5
    }

    Write-Host "`n✅ Authentication security checks completed successfully." -ForegroundColor Green
}

# Run the function
Check-AuthenticationSecurity
