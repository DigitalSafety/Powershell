# Install the AzureAD and MSOnline modules if not already installed
try {
    Write-Output "Checking if AzureAD module is installed..."
    if (-not (Get-Module -ListAvailable -Name AzureAD)) {
        Write-Output "AzureAD module not found. Installing AzureAD module..."
        Install-Module AzureAD -Scope CurrentUser -Force
        Write-Output "AzureAD module installed."
    } else {
        Write-Output "AzureAD module is already installed."
    }

    Write-Output "Checking if MSOnline module is installed..."
    if (-not (Get-Module -ListAvailable -Name MSOnline)) {
        Write-Output "MSOnline module not found. Installing MSOnline module..."
        Install-Module MSOnline -Scope CurrentUser -Force
        Write-Output "MSOnline module installed."
    } else {
        Write-Output "MSOnline module is already installed."
    }
}
catch {
    Write-Error "Error installing modules: $_"
    exit
}

# Connect to AzureAD
try {
    Write-Output "Connecting to Azure Active Directory..."
    Connect-AzureAD
    Write-Output "Connected to Azure Active Directory."
}
catch {
    Write-Error "Error connecting to Azure Active Directory: $_"
    exit
}

# Connect to MSOnline
try {
    Write-Output "Connecting to Microsoft Online Service..."
    Connect-MsolService
    Write-Output "Connected to Microsoft Online Service."
}
catch {
    Write-Error "Error connecting to Microsoft Online Service: $_"
    exit
}

# Prompt for user details
$userDetails = @{
    AccountEnabled = $true
    DisplayName = Read-Host "Enter Display Name"
    MailNickname = Read-Host "Enter Mail Nickname"
    UserPrincipalName = Read-Host "Enter User Principal Name"
    UserType = Read-Host "Enter User Type"
    Department = Read-Host "Enter Department"
    JobTitle = Read-Host "Enter Job Title"
}

# Prompt for password
$password = Read-Host "Enter Password (ensure it meets complexity requirements)" -AsSecureString
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
$userDetails.PasswordProfile = $passwordProfile

# Create the new user in AzureAD
try {
    $newUser = New-AzureADUser -AccountEnabled $userDetails.AccountEnabled `
                               -DisplayName $userDetails.DisplayName `
                               -MailNickname $userDetails.MailNickname `
                               -UserPrincipalName $userDetails.UserPrincipalName `
                               -PasswordProfile $userDetails.PasswordProfile `
                               -UserType $userDetails.UserType `
                               -Department $userDetails.Department `
                               -JobTitle $userDetails.JobTitle

    if ($newUser -ne $null) {
        Write-Output "User created: $($userDetails.UserPrincipalName)"

        # Delay to allow for propagation
        Start-Sleep -Seconds 60

        # Enforce MFA for the new user by setting StrongAuthenticationRequirements
        $strongAuthRequirement = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
        $strongAuthRequirement.RelyingParty = "*"
        $strongAuthRequirement.State = "Enabled"
        $strongAuthRequirement.RememberDevicesNotIssuedBefore = (Get-Date)

        Set-MsolUser -UserPrincipalName $userDetails.UserPrincipalName -StrongAuthenticationRequirements @($strongAuthRequirement)
        
        Write-Output "MFA enforced for UserPrincipalName: $($userDetails.UserPrincipalName)"
    } else {
        Write-Output "Failed to create user: $($userDetails.UserPrincipalName)"
    }
}
catch {
    Write-Error "Error creating user: $_"
    exit
}

Write-Output "Script completed successfully."
