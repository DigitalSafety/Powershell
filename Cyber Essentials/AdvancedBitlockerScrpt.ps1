# Function to check Office 365, force Azure AD Join, enable BitLocker, and store the recovery key
function Check-EnableBitLocker {
    Write-Host "`n🔍 Checking Office 365 & Azure AD Status..." -ForegroundColor Cyan

    # Check if the device is connected to Office 365
    $O365Status = dsregcmd /status | Select-String "WorkplaceJoined" | ForEach-Object { $_ -match "YES" }
    $aadJoined = dsregcmd /status | Select-String "AzureAdJoined" | ForEach-Object { $_ -match "YES" }
    $domainJoined = dsregcmd /status | Select-String "DomainJoined" | ForEach-Object { $_ -match "YES" }

    if ($O365Status) {
        Write-Host "✅ This device is connected to Office 365." -ForegroundColor Green
    } else {
        Write-Host "❌ This device is NOT connected to Office 365. Ensure you're signed in with a work account." -ForegroundColor Red
        return
    }

    # Check if the device is already Azure AD Joined
    if ($aadJoined) {
        Write-Host "✅ This device is already Azure AD Joined." -ForegroundColor Green
    } else {
        Write-Host "❌ This device is NOT Azure AD Joined." -ForegroundColor Red

        if ($domainJoined) {
            Write-Host "⚠️ This device is already joined to an on-premises Active Directory." -ForegroundColor Yellow
            Write-Host "➡️ You must enable **Hybrid Azure AD Join** via Group Policy or Intune." -ForegroundColor Cyan
            return
        }

        # Check if the user is local or an Azure AD account
        $CurrentUser = whoami
        if ($CurrentUser -match "AzureAD\\") {
            try {
                Connect-AzureAD
                $AzureUser = Get-AzureADUser -SearchString "$env:USERNAME@$env:USERDOMAIN"
                if ($AzureUser) {
                    Write-Host "✅ Verified that $env:USERNAME is an Azure AD user." -ForegroundColor Green
                } else {
                    Write-Host "❌ The account $env:USERNAME does NOT exist in Azure AD. Contact IT support." -ForegroundColor Red
                    return
                }
            } catch {
                Write-Host "❌ Unable to connect to Azure AD. Ensure you have the AzureAD module installed and admin permissions." -ForegroundColor Red
                return
            }

            # Force Azure AD Join
            Write-Host "🔄 Resetting Azure AD registration and rejoining..." -ForegroundColor Yellow
            dsregcmd /leave
            Start-Sleep -Seconds 5
            dsregcmd /join
            Start-Sleep -Seconds 5

            # Restart and check status
            Write-Host "🔄 Restarting device. Please log in and rerun the script." -ForegroundColor Cyan
            Restart-Computer
            return
        } else {
            Write-Host "⚠️ You are logged in with a LOCAL ACCOUNT ($env:USERNAME). Skipping Azure AD check." -ForegroundColor Yellow
        }
    }

    Write-Host "`n🔍 Checking TPM and BitLocker Compatibility..." -ForegroundColor Cyan

    # Check TPM presence
    $tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
    $hasTPM = $false
    if ($tpm -and $tpm.IsActivated_InitialValue -eq $true) {
        Write-Host "✅ TPM is present and activated on this device." -ForegroundColor Green
        Write-Host "➡️ You can enable BitLocker without requiring a password." -ForegroundColor Cyan
        $hasTPM = $true
    } else {
        Write-Host "❌ No TPM detected! Enabling BitLocker will require a password or USB key." -ForegroundColor Red
    }

    # Check OS edition
    $osEdition = (Get-WmiObject Win32_OperatingSystem).Caption
    $bitLockerSupported = $osEdition -match "Windows 10 Pro|Windows 11 Pro|Enterprise|Education"
    if ($bitLockerSupported) {
        Write-Host "✅ Your operating system ($osEdition) supports BitLocker." -ForegroundColor Green
    } else {
        Write-Host "❌ Your operating system ($osEdition) does NOT support BitLocker." -ForegroundColor Red
        Write-Host "➡️ You need **Windows 11 Pro, Enterprise, or Education** to use BitLocker." -ForegroundColor Yellow
        return
    }

    # Check if BitLocker is already enabled
    $bitLockerStatus = (Get-BitLockerVolume -MountPoint "C:").ProtectionStatus
    if ($bitLockerStatus -eq "On") {
        Write-Host "✅ BitLocker is already ENABLED on this system." -ForegroundColor Green
        return
    }

    # If TPM & OS support BitLocker, enable it using TPM (No password required)
    if ($hasTPM -and $bitLockerSupported) {
        Write-Host "`n🔒 Enabling BitLocker using TPM (No password required)..." -ForegroundColor Yellow

        # Enable BitLocker with TPM
        Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector -SkipHardwareTest
        Write-Host "✅ BitLocker has been successfully ENABLED using TPM." -ForegroundColor Green

        # Retrieve the actual BitLocker Recovery Key
        $bitLockerKey = (Get-BitLockerVolume -MountPoint "C:").KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | Select-Object -ExpandProperty RecoveryPassword

        if ($bitLockerKey) {
            Write-Host "`n🔑 **Your BitLocker Recovery Key:**" -ForegroundColor Cyan
            Write-Host "$bitLockerKey" -ForegroundColor Yellow
            Write-Host "➡️ Store this key in a safe place (Microsoft Account, USB, or Print it)." -ForegroundColor Cyan
        } else {
            Write-Host "❌ No BitLocker Recovery Key found! Ensure BitLocker setup completes successfully." -ForegroundColor Red
        }

        # Backup the BitLocker key to Azure AD
        Write-Host "`n🔷 Backing up the BitLocker key to Azure AD..." -ForegroundColor Blue
        BackupToAAD-BitLockerKeyProtector -MountPoint "C:"
        Write-Host "✅ BitLocker recovery key has been stored in Azure AD." -ForegroundColor Green
    } else {
        Write-Host "❌ BitLocker cannot be enabled automatically because TPM is missing." -ForegroundColor Red
    }
}

# Run the function
Check-EnableBitLocker
