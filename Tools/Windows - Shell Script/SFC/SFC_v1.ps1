# Author: KC99 / Language: Powershell
# Description: Checks for corrupt system files
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
