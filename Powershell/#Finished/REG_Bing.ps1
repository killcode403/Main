# Ensure running as Admin
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Define the path to the registry key
$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\"
$key = "BingSearchEnabled"
Clear-Host
Write-Host -NoNewline "KEY EDITOR: " -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host -NoNewline "'BingSearchEnabled' " -ForegroundColor Green -BackgroundColor DarkBlue
Write-Host -NoNewline $RegPath -ForegroundColor DarkGray -BackgroundColor DarkBlue
Write-Host ""

# Get the value of the registry key with ErrorAction to suppress errors
try {
    $value = Get-ItemProperty -Path $RegPath -Name $key -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $key
} catch {
    Write-Host "Error reading registry key. Error: $_" -ForegroundColor Red
    Exit
}

# Check if the registry key exists or needs to be created
if ($null -eq $value) {
    Write-Host "The registry key does not exist." -ForegroundColor Yellow

    # Prompt the user to create the registry key
    $createKey = $null
    while ($createKey -eq $null) {
        $createKey = Read-Host "Do you want to create the key? (Y/N)"
        switch ($createKey.ToUpper()) {
            "Y" {
                # Create the new registry key
                try {
                    New-Item -Path $RegPath -Force
                    Write-Host "Registry key created." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to create the registry key. Error: $_" -ForegroundColor Red
                    Exit
                }

                # Prompt the user to enable or disable the key
                $enableDisable = $null
                while ($enableDisable -eq $null) {
                    $enableDisable = Read-Host "Do you want to enable (E) or disable (D) the key?"
                    switch ($enableDisable.ToUpper()) {
                        "E" {
                            try {
                                Set-ItemProperty -Path $RegPath -Name $key -Value 1
                                Write-Host "Registry key enabled." -ForegroundColor Green
                            } catch {
                                Write-Host "Failed to enable the registry key. Error: $_" -ForegroundColor Red
                            }
                            break
                        }
                        "D" {
                            try {
                                Set-ItemProperty -Path $RegPath -Name $key -Value 0
                                Write-Host "Registry key disabled." -ForegroundColor Green
                            } catch {
                                Write-Host "Failed to disable the registry key. Error: $_" -ForegroundColor Red
                            }
                            break
                        }
                        Default {
                            Write-Host "Invalid input. Please enter 'E' to enable or 'D' to disable." -ForegroundColor Yellow
                            $enableDisable = $null
                        }
                    }
                }
            }
            "N" {
                Write-Host "Registry key creation aborted." -ForegroundColor Red
                Exit
            }
            Default {
                Write-Host "Invalid input. Please enter 'Y' or 'N'." -ForegroundColor Yellow
                $createKey = $null
            }
        }
    }
} else {
    Write-Host "The registry key already exists. Current value: $value" -ForegroundColor Cyan

    # Prompt the user to enable or disable the key
    $enableDisable = $null
    while ($enableDisable -eq $null) {
        $enableDisable = Read-Host "Do you want to enable (E) or disable (D) the key?"
        switch ($enableDisable.ToUpper()) {
            "E" {
                try {
                    Set-ItemProperty -Path $RegPath -Name $key -Value 1
                    Write-Host "Registry key enabled." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to enable the registry key. Error: $_" -ForegroundColor Red
                }
                break
            }
            "D" {
                try {
                    Set-ItemProperty -Path $RegPath -Name $key -Value 0
                    Write-Host "Registry key disabled." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to disable the registry key. Error: $_" -ForegroundColor Red
                }
                break
            }
            Default {
                Write-Host "Invalid input. Please enter 'E' to enable or 'D' to disable." -ForegroundColor Yellow
                $enableDisable = $null
            }
        }
    }
}

# Pause the script before exiting
pause
