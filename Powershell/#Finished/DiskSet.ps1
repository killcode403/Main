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
