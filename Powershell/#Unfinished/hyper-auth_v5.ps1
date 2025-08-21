# Ensure running as Admin:::
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
    {Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit}

# Debug:::
# $ErrorActionPreference = 'SilentlyContinue'
# Set the default console background and foreground colors
$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host
# Pause


# Root Functions:::
function Get-RootDependencies {
    do {Write-Host "--------------------------" -ForegroundColor Green
        switch ((Read-Host "Is this a Server or Client? (S/C)").ToUpper()) {
            'S'       { $Target = 'Server'; $validTarget = $true }
            'SERVER'  { $Target = 'Server'; $validTarget = $true }
            'C'       { $Target = 'Client'; $validTarget = $true }
            'CLIENT'  { $Target = 'Client'; $validTarget = $true }
            default 
                {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
                Write-Host " ERROR: Invalid input" -ForegroundColor Red}}} until ($validTarget)
    # Required info
    $ServerIP = Read-Host "Whats the server's IP?: "
    $ServerHostname = Read-Host "Whats the server's Hostname?: "
    $ClientIP = Read-Host "Whats the client's IP?: "
    $ClientHostname = Read-Host "Whats the client's Hostname?: "
    # $ServerUSR = Read-Host "Whats the server account's Username?: "
    # $ServerPWD = Read-Host "Whats the server account's Password?: " 
}


# Client Functions:::
# Step A 
function Get-ClientConfirmation {
    # Info Check
    function Get-ClientConfirmation_DisplayInfo {
        Clear-Host
        Write-Host "#--------------------------------------#"
        Write-Host "| Configuration mode: $Target"
        Write-Host "| server's IP . . . . . . : $ServerIP"
        Write-Host "| server's Hostname . . . : $ServerHostname"
        Write-Host "| client's IP . . . . . . : $ClientIP"
        Write-Host "| client's Hostname . . . : $ClientHostname"
        Write-Host "#--------------------------------------#"
        Write-Host "Your system will undergo these steps:" 
        Write-Host "1. Set local static DNS override (bypass all DNS servers)" -ForegroundColor Yellow
        Write-Host "2. Set TrustedHosts (permits WinRM connections to non-domain host)" -ForegroundColor Yellow
        Write-Host "3. Enable & Configure WinRM Authentication Protocol (CredSSP/SPN)" -ForegroundColor Yellow
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Yellow}
    # Set variable if user chose "why"
    $ClientSteps = @{
        '1' = "Step 1 | Why: WinRM (SPN) allowed list is Hostname based, not IP"
        '2' = "Step 2 | Why: Host blocks any NTLM WinRM connection, Kerberos is only for AD"
        '3' = "Step 3 | Why: Without CredSSP/SPN, WinRM blocks the delegation"
        '4' = "Step 4 | Why: CredSSP will refuse to forward credentials to client"}
    # Call function to dispay info
    Get-ClientConfirmation_DisplayInfo
    # Prompt loop
    do {$ClientNoticeInput = Read-Host "Press (Enter) to continue / Refresh (R) / Learn step Reason (1-4)"
        if ($ClientNoticeInput -in '1','2','3','4') {Write-Host $ClientSteps[$ClientNoticeInput] -ForegroundColor Cyan}
        elseif ($ClientNoticeInput -ieq 'R') {Get-ClientConfirmation_DisplayInfo}
        elseif (-not [string]::IsNullOrWhiteSpace($ClientNoticeInput)) 
            {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
            Write-Host " ERROR: Invalid input" -ForegroundColor Red}
    } until ([string]::IsNullOrWhiteSpace($ClientNoticeInput))
    # Final prompt
    do {$ClientFinalInput = Read-Host "Do you wish to execute? (Enter)"
        if (-not [string]::IsNullOrWhiteSpace($ClientFinalInput)) 
        {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
        Write-Host " ERROR: Invalid input" -ForegroundColor Red}
    } until ([string]::IsNullOrWhiteSpace($ClientFinalInput))
}

# Step B
function Invoke-ClientExecution {
    # 1. Set local static DNS override
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$ServerIP`t$ServerHostname"' -ForegroundColor DarkGreen
    # Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$ServerIP`t$ServerHostname"
    # 2. Set TrustedHosts (required for WinRM in workgroup)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$ServerHostname" -Force' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$ServerHostname" -Force
    # 3. Enable CredSSP Server role
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$ServerHostname" -force' -ForegroundColor DarkGreen
    # Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$ServerHostname" -force
    # 4. Configure AllowFreshCredentials
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\Auth\CredSSP -Value @{AllowFreshCredentials=$true}' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\Auth\CredSSP -Value @{AllowFreshCredentials=$true}
     Start-Sleep 1
    Write-Host "::System::" -BackgroundColor gray -ForegroundColor magenta -NoNewline
    Write-Host " DONE" -ForegroundColor Green  
}
# Step C
function Invoke-ClientSystemCheck {
    # System Check Part 1/2
    Write-Host "Checking dependencies..."
    Start-Sleep 1
    if ([string]::IsNullOrWhiteSpace($ServerIP)       -or
        [string]::IsNullOrWhiteSpace($ServerHostname) -or
        [string]::IsNullOrWhiteSpace($ClientIP)       -or
        [string]::IsNullOrWhiteSpace($ClientHostname))
       {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
        Write-Host " ERROR: (Variable Dependencies = NUL)" -ForegroundColor Red
        Write-Host "Listing variables..."
        Start-Sleep 3
        Write-Host "#--------------------------------------#"
        Write-Host "| Configuration mode: $Target"
        Write-Host "| server's IP . . . . . . : $ServerIP"
        Write-Host "| server's Hostname . . . : $ServerHostname"
        Write-Host "| client's IP . . . . . . : $ClientIP"
        Write-Host "| client's Hostname . . . : $ClientHostname"
        Write-Host "#--------------------------------------#"
        Write-Host "Next the script will check if all steps are completed successfully. Due to a dependency error the script may confuse NUL with a success status. Do not trust the next system check"
        Pause}
    else {
        Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
        Write-Host " SUCCESS" -ForegroundColor Green}
    # System Check Part 2/2
    Start-Sleep 1
    Write-Host "Checking system..."
    Start-Sleep 1
    # Check step // 1. Set local static DNS override
    $ClientCheck_DNS = "$ServerIP`t$ServerHostname"
    # Read the hosts file and check for an exact match in one go
    if ((Get-Content -Path "C:\Windows\System32\drivers\etc\hosts") -contains $ClientCheck_DNS) {$ClientCheck_DNS_CheckStatus = "Passed"} else {$ClientCheck_DNS_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 2. Set TrustedHosts (required for WinRM in workgroup)
    $ClientCheck_TrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value 
    if ($ClientCheck_TrustedHosts -eq $ServerHostname) {$ClientCheck_TrustedHosts_CheckStatus = "Passed"} else {$ClientCheck_TrustedHosts_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 3. Enable CredSSP Server role
    $ClientCheck_CredSSP_Target = Get-WSManCredSSP |
    Select-String -Pattern $ServerHostname -AllMatches | ForEach-Object {foreach($m in $_.Matches){$m.Value}} | Select-Object -First 1
    $ClientCheck_CredSSP_Status = Get-WSManCredSSP |
    Select-String -Pattern "allow delegating fresh credentials to the following target" -AllMatches | ForEach-Object {foreach($m in $_.Matches){ $m.Value}}
    if (($ClientCheck_CredSSP_Target -eq $ServerHostname) -and ($ClientCheck_CredSSP_Status -eq "allow delegating fresh credentials to the following target")) {$ClientCheck_CredSSP_CheckStatus = "Passed"} else {$ClientCheck_CredSSP_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 4. Configure AllowFreshCredentials
    $ClientCheck_Credentials = reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" |
    Select-String -Pattern $ServerHostname -AllMatches |
    ForEach-Object {foreach($m in $_.Matches){$m.Value}}
    if ($ClientCheck_Credentials -eq $ServerHostname) {$ClientCheck_Credentials_CheckStatus = "Passed"} else {$ClientCheck_Credentials_CheckStatus = "Failed"}
}

# Step D
function Show-ClientSystemStatus {
    # Overview of system status
    Write-Host "#======================================#"
    # 1. DNS override
    Write-Host "| 1. Set local static DNS override ------: " -NoNewline
    if ($ClientCheck_DNS_CheckStatus -eq 'Passed') {Write-Host $ClientCheck_DNS_CheckStatus -ForegroundColor Green} 
    elseif ($ClientCheck_DNS_CheckStatus -eq 'Failed') {Write-Host $ClientCheck_DNS_CheckStatus -ForegroundColor Red} 
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    # 2. TrustedHosts
    Write-Host "| 2. Set TrustedHosts -------------------: " -NoNewline
    if ($ClientCheck_TrustedHosts_CheckStatus -eq 'Passed') {Write-Host $ClientCheck_TrustedHosts_CheckStatus -ForegroundColor Green} 
    elseif ($ClientCheck_TrustedHosts_CheckStatus -eq 'Failed') {Write-Host $ClientCheck_TrustedHosts_CheckStatus -ForegroundColor Red}
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    # 3. CredSSP
    Write-Host "| 3. Enable CredSSP Server role ---------: " -NoNewline
    if ($ClientCheck_CredSSP_CheckStatus -eq 'Passed') {Write-Host $ClientCheck_CredSSP_CheckStatus -ForegroundColor Green} 
    elseif ($ClientCheck_CredSSP_CheckStatus -eq 'Failed') {Write-Host $ClientCheck_CredSSP_CheckStatus -ForegroundColor Red} 
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    # 4. AllowFreshCredentials
    Write-Host "| 4. Configure AllowFreshCredentials ----: " -NoNewline
    if ($ClientCheck_Credentials_CheckStatus -eq 'Passed') {Write-Host $ClientCheck_Credentials_CheckStatus -ForegroundColor Green}
    elseif ($ClientCheck_Credentials_CheckStatus -eq 'Failed') {Write-Host $ClientCheck_Credentials_CheckStatus -ForegroundColor Red} 
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    Write-Host "#======================================#"
}

# Step E
function Invoke-ClientOptionalManualCheck {
    function Invoke-ClientOptionalManualCheck_DisplayInfo {
        Write-Host "Steps with corresponding directories:" 
        Write-Host "1. Set local static DNS override (bypass all DNS servers)" -ForegroundColor Yellow
        Write-Host "   > C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Yellow
        Write-Host "2. Set TrustedHosts (permits WinRM connections to non-domain host)" -ForegroundColor Yellow
        Write-Host "   > WSMan:\localhost\Client\TrustedHosts" -ForegroundColor Yellow
        Write-Host "3. Enable & Configure WinRM Authentication Protocol (CredSSP/SPN)" -ForegroundColor Yellow
        Write-Host "   > HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" -ForegroundColor Yellow
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Yellow
        Write-Host "   > WSMan:\localhost\Client\Auth\CredSSP" -ForegroundColor Yellow}
    # Call function to dispay info
    Invoke-ClientOptionalManualCheck_DisplayInfo
    # Prompt loop
    do {$ClientNoticeInput = Read-Host "Press (Enter) to continue / Manual check (1-4)"
        switch ($ClientNoticeInput) {
            '1' { Start-Process notepad.exe "C:\Windows\System32\drivers\etc\hosts" }
            '2' { Get-Item WSMan:\localhost\Client\TrustedHosts }
            '3' {Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit' `
                    -Name 'LastKey' `
                    -Value 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
                Start-Process regedit.exe}
            '4' { Get-Item WSMan:\localhost\Client\Auth\CredSSP }
            default {
                if (-not [string]::IsNullOrWhiteSpace($ClientNoticeInput)) {
                    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
                    Write-Host " ERROR: Invalid input" -ForegroundColor Red}
            }
        }
    } until ([string]::IsNullOrWhiteSpace($ClientNoticeInput))
}


# Server Functions:::
#
#
#









# Function Execution:::
Get-RootDependencies

if ($Target -eq 'Client') {
    try {
        # Step A    
        Get-ClientConfirmation
        # Step B
        Invoke-ClientExecution
        # Step C
        Invoke-ClientSystemCheck
        # Step D
        Show-ClientSystemStatus
        # Step E
        Invoke-ClientOptionalManualCheck
        Write-Host "::System::" -BackgroundColor gray -ForegroundColor magenta -NoNewline
        Write-Host " DONE" -ForegroundColor Green 
        Pause
    } catch {
        Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Red -NoNewline
        Write-Host " SCRIPT ERROR: $_" -ForegroundColor Red
        Pause
    }















}

if ($Target -eq 'Server') {
    # Info Check
    Clear
    Write-Host "#--------------------------------------#"
    Write-Host "| Configuration mode: $Target"
    Write-Host "| server's IP . . . . . . : $ServerIP"
    Write-Host "| server's Hostname . . . : $ServerHostname"
    Write-Host "| client's IP . . . . . . : $ClientIP"
    Write-Host "| client's Hostname . . . : $ClientHostname"
    Write-Host "#--------------------------------------#"
    # Notice prompt
    Write-Host "Configuration mode: $Target"
    Write-Host "Your system will undergo these steps:"
    Write-Host "1. Set local static DNS override" -ForegroundColor Yellow
    Write-Host "2. Enable WinRM (WSMan service)" -ForegroundColor Yellow
    Write-Host "3. Enable CredSSP Server role" -ForegroundColor Yellow
    Write-Host "4. Set TrustedHosts" -ForegroundColor Yellow
    Write-Host "5. AllowFreshCredentials (receive delegation)" -ForegroundColor Yellow
    Pause

    # 1. Set local static DNS override
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$ClientIP`t$ClientHostname"' -ForegroundColor DarkGreen
    # Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$ClientIP`t$ClientHostname"

    # 2. Enable WinRM (WSMan service)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-PSRemoting -Force' -ForegroundColor DarkGreen
    # Enable-PSRemoting -Force

    # 3. Enable CredSSP Server role
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-WSManCredSSP -Role Server -Force' -ForegroundColor DarkGreen
    # Enable-WSManCredSSP -Role Server -Force

    # 4. Set TrustedHosts
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$ClientHostname" -Force' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$ClientHostname" -Force

    # 5. AllowFreshCredentials (receive delegation)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Force' -ForegroundColor DarkGreen
    # New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Force

    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Name "1" -Value "wsman/$ClientHostname" -PropertyType String -Force' -ForegroundColor DarkGreen
    # New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Name "1" -Value "wsman/$ClientHostname" -PropertyType String -Force
    Start-Sleep 1
    Write-Host "::System::" -BackgroundColor gray -ForegroundColor magenta -NoNewline
    Write-Host " DONE" -ForegroundColor Green
    Pause
}