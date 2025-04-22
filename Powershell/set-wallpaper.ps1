# Ensure running as Administrator
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# === SECTION 1: Enable Wallpaper Lock ===

# Registry path and value
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
$valueName = "NoChangingWallPaper"

# Ensure registry path exists
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Create or set value to 1 (lock)
Set-ItemProperty -Path $regPath -Name $valueName -Value 1 -Type DWord

Write-Output "Wallpaper changes are now LOCKED."

# === SECTION 2: Download Wallpaper ===

# Image URL
$imageUrl = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSSZ1OlCgGCZgVV4RzLv9e99hkRlzXwo-j_rw&s"

# Local save path (user's Pictures folder)
$localFolder = [Environment]::GetFolderPath("MyPictures")
$localImage = Join-Path $localFolder "downloaded_wallpaper.jpg"

# Download image
try {
    Write-Output "Downloading wallpaper..."
    Invoke-WebRequest -Uri $imageUrl -OutFile $localImage -UseBasicParsing
    Write-Output "Image saved to: $localImage"
}
catch {
    Write-Error "Failed to download image. Exiting script."
    exit 1
}

# === SECTION 3: Apply Wallpaper ===

# Add user32.dll interop
Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# Constants
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDWININICHANGE = 0x02

# Apply wallpaper
$result = [Wallpaper]::SystemParametersInfo(
    $SPI_SETDESKWALLPAPER,
    0,
    $localImage,
    $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE
)

if ($result) {
    Write-Output "Wallpaper successfully applied."
} else {
    Write-Error "Failed to apply the wallpaper."
}



start-sleep 30
Start-Process "https://github.com/killcode403/Main/blob/main/Powershell/restore-wallpaper.ps1"
