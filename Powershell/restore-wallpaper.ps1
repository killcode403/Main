# Ensure running as Administrator
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# === SECTION: Disable Wallpaper Lock ===

# Registry path and value
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
$valueName = "NoChangingWallPaper"

# Create registry path if it doesn't exist
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Set the value to 0 to allow wallpaper changes
Set-ItemProperty -Path $regPath -Name $valueName -Value 0 -Type DWord
Write-Output "Wallpaper lock has been DISABLED. Users can now change the wallpaper."
