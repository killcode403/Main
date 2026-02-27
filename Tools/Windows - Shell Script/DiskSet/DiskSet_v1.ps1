# Author: KC99 / Language: Powershell
# Description: Change disk onine status
# ======================= Start-Code =======================
# Ensure running as Admin
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrative privileges. Restarting as Administrator..." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Ensure Required Services are Running
Write-Host "Ensuring Windows Modules Installer and WMI services are running..." -ForegroundColor Yellow
try {
    # Start TrustedInstaller
    Set-Service -Name TrustedInstaller -StartupType Manual
    Start-Service -Name TrustedInstaller

    # Start WMI service
    Set-Service -Name Winmgmt -StartupType Automatic
    Start-Service -Name Winmgmt

    Write-Host "Services are running successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to start necessary services. Exiting..." -ForegroundColor Red
    Exit
}

# Run DISM to Repair System Image
Write-Host "Attempting to repair system image using DISM..." -ForegroundColor Yellow
try {
    cmd.exe /c DISM.exe /Online /Cleanup-Image /RestoreHealth
    Write-Host "DISM repair complete. Re-attempting SFC..." -ForegroundColor Green
    Start-Sleep -Seconds 2
} catch {
    Write-Host "DISM failed. Exiting script." -ForegroundColor Red
    Exit
}

# Run System File Checker
Write-Host "Running System File Checker (SFC)..." -ForegroundColor Green
try {
    cmd.exe /c sfc /scannow
    Write-Host "SFC Scan Complete." -ForegroundColor Cyan
} catch {
    Write-Host "Failed to execute SFC." -ForegroundColor Red
}

Write-Host "Script Complete. Press any key to exit..."
[Console]::ReadKey()


# Ensure running as Admin
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Display available disks
Write-Host "Available disks:" -ForegroundColor Green
Get-Disk | Select-Object Number, OperationalStatus, FriendlyName, @{Name="Size (GB)";Expression={($_.Size / 1GB).ToString("F2")}} | Format-Table -AutoSize

# Ask the user for the disk number they want to modify
$disknum = $null
while ($disknum -eq $null) {
    $input = Read-Host "Enter the disk number to modify (must be numeric)"
    if ([int]::TryParse($input, [ref]$null)) {
        $disknum = [int]$input
        $disk = Get-Disk -Number $disknum -ErrorAction SilentlyContinue
        if ($disk -eq $null) {
            Write-Host "Invalid disk number. No disk found with number $disknum. Please try again." -ForegroundColor Yellow
            $disknum = $null
        }
    } else {
        Write-Host "Invalid input. Please enter a numeric value." -ForegroundColor Yellow
    }
}

# Ask the user for the action (remove or add)
$act = $null
while ($act -eq $null) {
    $input = Read-Host "Remove or Add? (R/A)"
    switch ($input.ToUpper()) {
        "R" { $act = "Remove" }
        "A" { $act = "Add" }
        Default {
            Write-Host "Invalid action. Please enter 'R' to remove or 'A' to add." -ForegroundColor Yellow
        }
    }
}

# Perform the action based on user input
try {
    if ($act -eq "Remove") {
        Write-Host "Taking disk $disknum offline..."
        Set-Disk -Number $disknum -IsOffline $true
        Write-Host "Disk $disknum is now offline." -ForegroundColor Green
    } elseif ($act -eq "Add") {
        Write-Host "Bringing disk $disknum online..."
        Set-Disk -Number $disknum -IsOffline $false
        Write-Host "Disk $disknum is now online." -ForegroundColor Green
    }
} catch {
    Write-Host "An error occurred while modifying disk $disknum. Error: $_" -ForegroundColor Red
}

# Display updated disk list
Write-Host "Updated disk status:" -ForegroundColor Green
Get-Disk | Select-Object Number, OperationalStatus, FriendlyName, @{Name="Size (GB)";Expression={($_.Size / 1GB).ToString("F2")}} | Format-Table -AutoSize

# Pause the script before exiting
pause
