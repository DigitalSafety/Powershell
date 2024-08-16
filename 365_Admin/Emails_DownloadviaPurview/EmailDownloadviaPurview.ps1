# This program makes the whole process of recovering emails from the Server much easier
# It will ask for details then it will open Purview at the Export page and then
# continue on Purview to down the .pst file for import into Outlook and recover emails.
# Function to prompt for user input and validate it
function Get-UserInput {
    param (
        [string]$Prompt,
        [string]$DefaultValue = $null
    )

    $input = Read-Host $Prompt
    if ($input -eq "") {
        return $DefaultValue
    } else {
        return $input
    }
}

try {
    # Connect to Microsoft Purview (Security & Compliance Center)
    Write-Host "Connecting to Microsoft Purview..."
    Connect-IPPSSession
    Write-Host "Connected successfully." -ForegroundColor Green

    # Prompt for email address
    $emailAddress = Get-UserInput -Prompt "Enter the email address to search" -DefaultValue "jane.d@example.com"

    # Prompt for date range
    $startDate = Get-UserInput -Prompt "Enter the start date (YYYY-MM-DD)" -DefaultValue "2024-04-01"
    $endDate = Get-UserInput -Prompt "Enter the end date (YYYY-MM-DD)" -DefaultValue "2024-07-01"

    # Create the search name and query
    $searchName = "ExportEmailsSearch_$([Guid]::NewGuid())"
    $searchQuery = "Received:`"$startDate..$endDate`""

    # Create the compliance search
    Write-Host "Creating compliance search..."
    New-ComplianceSearch -Name $searchName -ExchangeLocation $emailAddress -ContentMatchQuery $searchQuery
    Write-Host "Compliance search created successfully." -ForegroundColor Green

    # Start the compliance search
    Write-Host "Starting the compliance search..."
    Start-ComplianceSearch -Identity $searchName
    Write-Host "Compliance search started successfully." -ForegroundColor Green

    # Wait for the search to complete
    Write-Host "Waiting for search to complete..."
    do {
        $searchStatus = Get-ComplianceSearch -Identity $searchName
        Write-Host "Search status: $($searchStatus.Status)"
        Start-Sleep -Seconds 30  # Wait for 30 seconds before checking again
    } while ($searchStatus.Status -ne "Completed")

    # Start the export action
    Write-Host "Starting export action..."
    New-ComplianceSearchAction -SearchName $searchName -Export -Format "Msg"
    Write-Host "Export action started successfully." -ForegroundColor Green

    # Open the Compliance Center webpage to view and download the results
    $url = "https://compliance.microsoft.com/contentsearchv2?viewid=export&"
    Write-Host "Opening the Compliance Center to view and download the results..."
    Start-Process $url

} catch {
    # Catch and display errors
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Disconnect the session
Write-Host "Disconnecting from Microsoft Purview..."
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Disconnected successfully." -ForegroundColor Green
