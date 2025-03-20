# Function to check if TPM and BitLocker are supported
function Check-TPM-BitLocker {
    Write-Host "`nChecking TPM and BitLocker Compatibility..." -ForegroundColor Cyan

    # Check TPM presence
    $tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
    if ($tpm -and $tpm.IsActivated_InitialValue -eq $true) {
        Write-Host "✅ TPM is present and activated on this device." -ForegroundColor Green
        Write-Host "➡️ You can enable BitLocker without requiring a password." -ForegroundColor Cyan
    } else {
        Write-Host "❌ No TPM detected! Enabling BitLocker will require a password or USB key." -ForegroundColor Red
    }

    # Check OS version
    $osEdition = (Get-WmiObject Win32_OperatingSystem).Caption
    if ($osEdition -match "Windows 10 Pro|Windows 11 Pro|Enterprise|Education") {
        Write-Host "✅ Your operating system ($osEdition) supports BitLocker." -ForegroundColor Green
    } else {
        Write-Host "❌ Your operating system ($osEdition) does NOT support BitLocker." -ForegroundColor Red
        Write-Host "➡️ You need **Windows 11 Pro, Enterprise, or Education** to use BitLocker." -ForegroundColor Yellow
        Write-Host "`n🔹 **Upgrade Suggestions:**" -ForegroundColor Cyan
        Write-Host " - If you are using **Windows 11 Home**, upgrade to **Windows 11 Pro** via:" -ForegroundColor Yellow
        Write-Host "   ➡️ Settings > System > Activation > Upgrade to Pro (Requires a license purchase)." -ForegroundColor Cyan
        Write-Host " - If you are using **Windows 10 Home**, consider upgrading to **Windows 11 Pro** for full BitLocker support." -ForegroundColor Yellow
        Write-Host "   ➡️ Use the Microsoft Store or an enterprise upgrade path." -ForegroundColor Cyan
    }

    Write-Host "`n🔹 If you have TPM and a supported OS, you can enable BitLocker without a password." -ForegroundColor Cyan
}

# Run the function
Check-TPM-BitLocker
