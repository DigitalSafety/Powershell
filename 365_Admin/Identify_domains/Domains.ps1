# This script connects to Microsoft Online Service, retrieves the list of domains, and outputs the results to the screen and a file.

# Connect to Microsoft Online Service
try {
    Write-Output "Connecting to Microsoft Online Service..."
    Connect-MsolService
    Write-Output "Connected to Microsoft Online Service."
}
catch {
    Write-Error "Error connecting to Microsoft Online Service: $_"
    exit
}

# Initialize a variable to store the output
$output = ""

# Retrieve and display the list of domains
try {
    Write-Output "Retrieving the list of domains..."
    $domains = Get-MsolDomain
    $output += "List of domains:`n"
    $domains | ForEach-Object { 
        $domainInfo = "$($_.Name) - $($_.Status) - $($_.Authentication)"
        Write-Output $domainInfo
        $output += $domainInfo + "`n"
    }
}
catch {
    Write-Error "Error retrieving domains: $_"
    exit
}

# Save the result to a file
$fileName = "msol_domains.txt"
$outputPath = Join-Path -Path (Get-Location) -ChildPath $fileName

try {
    $output | Out-File -FilePath $outputPath -Encoding utf8
    Write-Output "Results saved to $outputPath"
}
catch {
    Write-Error "Error saving results to file: $_"
}

Write-Output "Script completed successfully."
