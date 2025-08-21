# irm https://get.activated.win | iex
# Ensure running as Admin
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# URL to fetch the script
$url = "https://get.activated.win"

# Clear the console for better readability
Clear-Host
Write-Host "License Activation Script" -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host ""

# Validate internet connectivity
try {
    Write-Host "Checking internet connectivity..." -ForegroundColor Yellow
    $testConnection = Test-Connection -ComputerName "www.google.com" -Count 1 -Quiet
    if (-Not $testConnection) {
        Write-Host "Internet connectivity is required to run this script. Please check your connection and try again." -ForegroundColor Red
        Exit
    }
    Write-Host "Internet connectivity verified." -ForegroundColor Green
} catch {
    Write-Host "Failed to verify internet connectivity. Error: $_" -ForegroundColor Red
    Exit
}

# Confirm with the user before proceeding
$response = $null
while ($response -eq $null) {
    $response = Read-Host "This script will download and execute content from $url. Do you want to proceed? (Y/N)"
    switch ($response.ToUpper()) {
        "Y" {
            Write-Host "Proceeding with the activation process..." -ForegroundColor Green
        }
        "N" {
            Write-Host "Operation aborted by the user." -ForegroundColor Red
            Exit
        }
        Default {
            Write-Host "Invalid input. Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Yellow
            $response = $null
        }
    }
}

# Attempt to download and execute the script
try {
    Write-Host "Downloading and executing the activation script from $url..." -ForegroundColor Yellow
    Invoke-Expression -Command (Invoke-RestMethod -Uri $url -ErrorAction Stop)
    Write-Host "Script executed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to execute the activation script. Error: $_" -ForegroundColor Red
    Exit
}

# Exit message
Write-Host "License activation script has completed. Exiting now." -ForegroundColor Cyan
Exit
