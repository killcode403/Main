# Define the path to the registry key
$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\"
$key = "BingSearchEnabled"
Clear-Host
Write-Host -NoNewline "KEY EDITOR: " -ForegroundColor cyan -BackgroundColor darkblue
Write-Host -NoNewline "'BingSearchEnabled' " -ForegroundColor green -BackgroundColor darkblue
Write-Host -NoNewline $RegPath -ForegroundColor darkgray -BackgroundColor darkblue
Write-Host ""

# Get the value of the registry key with ErrorAction to suppress errors
$value = Get-ItemProperty -Path $RegPath -Name $key -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $key

# Corrected condition: Check if the value is either 1 or 0
if ($value -lt 0) {
    # Prompt the user to create the registry key
    Write-Host -NoNewline "Warning: " -ForegroundColor red -BackgroundColor gray
    Write-Host "Choice 'Y': New directory will be made, any existing keys in this directory will be removed" -ForegroundColor black -BackgroundColor gray
    $createKey = Read-Host "Registry key does not exist. Do you want to create it? (Y/N)"

    if ($createKey -eq 'Y' -or $createKey -eq 'y') {
        # Create the new registry key
        New-Item -Path $RegPath -Force

        # Prompt the user to enable or disable the key
        $enableDisable = Read-Host "Registry key created. Do you want to enable (E) or disable (D) it?"

        if ($enableDisable -eq 'E' -or $enableDisable -eq 'e') {
            Set-ItemProperty -Path $RegPath -Name $key -Value 1
            Write-Host "Registry key enabled."
        }
        elseif ($enableDisable -eq 'D' -or $enableDisable -eq 'd') {
            Set-ItemProperty -Path $RegPath -Name $key -Value 0
            Write-Host "Registry key disabled."
        }
        else {
            Write-Host "Invalid input. No changes made."
        }
    }
    else {
        Write-Host "Registry key creation aborted."
        Exit
    }
}
else {
    # Prompt the user to enable or disable the existing key
    $enableDisable = Read-Host "Registry key already exists. Do you want to enable (E) or disable (D) it?"

    if ($enableDisable -eq 'E' -or $enableDisable -eq 'e') {
        Set-ItemProperty -Path $RegPath -Name $key -Value 1
        Write-Host "Registry key enabled."
    }
    elseif ($enableDisable -eq 'D' -or $enableDisable -eq 'd') {
        Set-ItemProperty -Path $RegPath -Name $key -Value 0
        Write-Host "Registry key disabled."
    }
    else {
        Write-Host "Invalid input. No changes made."
    }
}

pause
