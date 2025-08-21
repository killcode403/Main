# Ensure running as Admin:::
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
    {Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$global:PSCommandPath`"" -Verb RunAs 
    exit}

# Debug:::
# $global:ErrorActionPreference = 'SilentlyContinue'
# Set the default console background and foreground colors
$global:Host.UI.RawUI.BackgroundColor = 'Black'
$global:Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host
# Pause


# Root Functions:::
function Get-RootDependencies {
    do {Write-Host "--------------------------" -ForegroundColor Green
        switch ((Read-Host "Is this a Server or Client? (S/C)").ToUpper()) {
            'S'       { $global:Target = 'Server'; $global:validTarget = $global:true }
            'SERVER'  { $global:Target = 'Server'; $global:validTarget = $global:true }
            'C'       { $global:Target = 'Client'; $global:validTarget = $global:true }
            'CLIENT'  { $global:Target = 'Client'; $global:validTarget = $global:true }
            default 
                {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
                Write-Host " ERROR: Invalid input" -ForegroundColor Red}}} until ($global:validTarget)
    # Required info
    $global:ServerIP = Read-Host "Whats the server's IP?: "
    $global:ServerHostname = Read-Host "Whats the server's Hostname?: "
    $global:ClientIP = Read-Host "Whats the client's IP?: "
    $global:ClientHostname = Read-Host "Whats the client's Hostname?: "
    # $global:ServerUSR = Read-Host "Whats the server account's Username?: "
    # $global:ServerPWD = Read-Host "Whats the server account's Password?: " 
}


# Client Functions:::
# Step A 
function Get-ClientConfirmation {
    # Info Check
    function Get-ClientConfirmation_DisplayInfo {
        Clear-Host
        Write-Host "#--------------------------------------#"
        Write-Host "| Configuration mode: $global:Target"
        Write-Host "| server's IP . . . . . . : $global:ServerIP"
        Write-Host "| server's Hostname . . . : $global:ServerHostname"
        Write-Host "| client's IP . . . . . . : $global:ClientIP"
        Write-Host "| client's Hostname . . . : $global:ClientHostname"
        Write-Host "#--------------------------------------#"
        Write-Host "Your system will undergo these steps:" 
        Write-Host "1. Set local static DNS override (bypass all DNS servers)" -ForegroundColor Yellow
        Write-Host "2. Set TrustedHosts (permits WinRM connections to non-domain host)" -ForegroundColor Yellow
        Write-Host "3. Enable & Configure WinRM Authentication Protocol (CredSSP/SPN)" -ForegroundColor Yellow
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Yellow}
    # Set variable if user chose "why"
    $global:ClientSteps = @{
        '1' = "Step 1 | Why: WinRM (SPN) allowed list is Hostname based, not IP"
        '2' = "Step 2 | Why: Host blocks any NTLM WinRM connection, Kerberos is only for AD"
        '3' = "Step 3 | Why: Without CredSSP/SPN, WinRM blocks the delegation"
        '4' = "Step 4 | Why: CredSSP will refuse to forward credentials to client"}
    # Call function to dispay info
    Get-ClientConfirmation_DisplayInfo
    # Prompt loop
    do {$global:ClientNoticeInput = Read-Host "Press (Enter) to continue / Refresh (R) / Learn step Reason (1-4)"
        if ($global:ClientNoticeInput -in '1','2','3','4') {Write-Host $global:ClientSteps[$global:ClientNoticeInput] -ForegroundColor Cyan}
        elseif ($global:ClientNoticeInput -ieq 'R') {Get-ClientConfirmation_DisplayInfo}
        elseif (-not [string]::IsNullOrWhiteSpace($global:ClientNoticeInput)) 
            {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
            Write-Host " ERROR: Invalid input" -ForegroundColor Red}
    } until ([string]::IsNullOrWhiteSpace($global:ClientNoticeInput))
    # Final prompt
    do {$global:ClientFinalInput = Read-Host "Do you wish to execute? (Enter)"
        if (-not [string]::IsNullOrWhiteSpace($global:ClientFinalInput)) 
        {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
        Write-Host " ERROR: Invalid input" -ForegroundColor Red}
    } until ([string]::IsNullOrWhiteSpace($global:ClientFinalInput))
}

# Step B
function Invoke-ClientExecution {
    # 1. Set local static DNS override
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$global:ServerIP`t$global:ServerHostname"' -ForegroundColor DarkGreen
    # Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$global:ServerIP`t$global:ServerHostname"
    # 2. Set TrustedHosts (required for WinRM in workgroup)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ServerHostname" -Force' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ServerHostname" -Force
    # 3. Enable CredSSP Server role
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$global:ServerHostname" -force' -ForegroundColor DarkGreen
    # Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$global:ServerHostname" -force
    # 4. Configure AllowFreshCredentials
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\Auth\CredSSP -Value @{AllowFreshCredentials=$global:true}' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\Auth\CredSSP -Value @{AllowFreshCredentials=$global:true}
     Start-Sleep 1
    Write-Host "::System::" -BackgroundColor gray -ForegroundColor magenta -NoNewline
    Write-Host " DONE" -ForegroundColor Green  
}
# Step C
function Invoke-ClientSystemCheck {
    # System Check Part 1/2
    Write-Host "Checking dependencies..."
    Start-Sleep 1
    if ([string]::IsNullOrWhiteSpace($global:ServerIP)       -or
        [string]::IsNullOrWhiteSpace($global:ServerHostname) -or
        [string]::IsNullOrWhiteSpace($global:ClientIP)       -or
        [string]::IsNullOrWhiteSpace($global:ClientHostname))
       {Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
        Write-Host " ERROR: (Variable Dependencies = NUL)" -ForegroundColor Red
        Write-Host "Listing variables..."
        Start-Sleep 3
        Write-Host "#--------------------------------------#"
        Write-Host "| Configuration mode: $global:Target"
        Write-Host "| server's IP . . . . . . : $global:ServerIP"
        Write-Host "| server's Hostname . . . : $global:ServerHostname"
        Write-Host "| client's IP . . . . . . : $global:ClientIP"
        Write-Host "| client's Hostname . . . : $global:ClientHostname"
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
    $global:ClientCheck_DNS = "$global:ServerIP`t$global:ServerHostname"
    # Read the hosts file and check for an exact match in one go
    if ((Get-Content -Path "C:\Windows\System32\drivers\etc\hosts") -contains $global:ClientCheck_DNS) {$global:ClientCheck_DNS_CheckStatus = "Passed"} else {$global:ClientCheck_DNS_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 2. Set TrustedHosts (required for WinRM in workgroup)
    $global:ClientCheck_TrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value 
    if ($global:ClientCheck_TrustedHosts -eq $global:ServerHostname) {$global:ClientCheck_TrustedHosts_CheckStatus = "Passed"} else {$global:ClientCheck_TrustedHosts_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 3. Enable CredSSP Server role
    $global:ClientCheck_CredSSP_Target = Get-WSManCredSSP |
    Select-String -Pattern $global:ServerHostname -AllMatches | ForEach-Object {foreach($global:m in $global:_.Matches){$global:m.Value}} | Select-Object -First 1
    $global:ClientCheck_CredSSP_Status = Get-WSManCredSSP |
    Select-String -Pattern "allow delegating fresh credentials to the following target" -AllMatches | ForEach-Object {foreach($global:m in $global:_.Matches){ $global:m.Value}}
    if (($global:ClientCheck_CredSSP_Target -eq $global:ServerHostname) -and ($global:ClientCheck_CredSSP_Status -eq "allow delegating fresh credentials to the following target")) {$global:ClientCheck_CredSSP_CheckStatus = "Passed"} else {$global:ClientCheck_CredSSP_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 4. Configure AllowFreshCredentials
    $global:ClientCheck_Credentials = reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" |
    Select-String -Pattern $global:ServerHostname -AllMatches |
    ForEach-Object {foreach($global:m in $global:_.Matches){$global:m.Value}}
    if ($global:ClientCheck_Credentials -eq $global:ServerHostname) {$global:ClientCheck_Credentials_CheckStatus = "Passed"} else {$global:ClientCheck_Credentials_CheckStatus = "Failed"}
}

# Step D
function Show-ClientSystemStatus {
    # Overview of system status
    Write-Host "#======================================#"
    # 1. DNS override
    Write-Host "| 1. Set local static DNS override ------: " -NoNewline
    if ($global:ClientCheck_DNS_CheckStatus -eq 'Passed') {Write-Host $global:ClientCheck_DNS_CheckStatus -ForegroundColor Green} 
    elseif ($global:ClientCheck_DNS_CheckStatus -eq 'Failed') {Write-Host $global:ClientCheck_DNS_CheckStatus -ForegroundColor Red} 
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    # 2. TrustedHosts
    Write-Host "| 2. Set TrustedHosts -------------------: " -NoNewline
    if ($global:ClientCheck_TrustedHosts_CheckStatus -eq 'Passed') {Write-Host $global:ClientCheck_TrustedHosts_CheckStatus -ForegroundColor Green} 
    elseif ($global:ClientCheck_TrustedHosts_CheckStatus -eq 'Failed') {Write-Host $global:ClientCheck_TrustedHosts_CheckStatus -ForegroundColor Red}
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    # 3. CredSSP
    Write-Host "| 3. Enable CredSSP Server role ---------: " -NoNewline
    if ($global:ClientCheck_CredSSP_CheckStatus -eq 'Passed') {Write-Host $global:ClientCheck_CredSSP_CheckStatus -ForegroundColor Green} 
    elseif ($global:ClientCheck_CredSSP_CheckStatus -eq 'Failed') {Write-Host $global:ClientCheck_CredSSP_CheckStatus -ForegroundColor Red} 
    else {Write-Host "INVALID STATUS" -ForegroundColor Red}
    # 4. AllowFreshCredentials
    Write-Host "| 4. Configure AllowFreshCredentials ----: " -NoNewline
    if ($global:ClientCheck_Credentials_CheckStatus -eq 'Passed') {Write-Host $global:ClientCheck_Credentials_CheckStatus -ForegroundColor Green}
    elseif ($global:ClientCheck_Credentials_CheckStatus -eq 'Failed') {Write-Host $global:ClientCheck_Credentials_CheckStatus -ForegroundColor Red} 
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
    do {$global:ClientNoticeInput = Read-Host "Press (Enter) to continue / Manual check (1-4)"
        switch ($global:ClientNoticeInput) {
            '1' { Start-Process notepad.exe "C:\Windows\System32\drivers\etc\hosts" }
            '2' { Get-Item WSMan:\localhost\Client\TrustedHosts }
            '3' {Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit' `
                    -Name 'LastKey' `
                    -Value 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
                Start-Process regedit.exe}
            '4' { Get-Item WSMan:\localhost\Client\Auth\CredSSP }
            default {
                if (-not [string]::IsNullOrWhiteSpace($global:ClientNoticeInput)) {
                    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
                    Write-Host " ERROR: Invalid input" -ForegroundColor Red}
            }
        }
    } until ([string]::IsNullOrWhiteSpace($global:ClientNoticeInput))
}


# Server Functions:::
#
#
#









# Function Execution:::
Get-RootDependencies

if ($global:Target -eq 'Client') {
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
        Write-Host " SCRIPT ERROR: $global:_" -ForegroundColor Red
        Pause
    }















}

if ($global:Target -eq 'Server') {
    # Info Check
    Clear
    Write-Host "#--------------------------------------#"
    Write-Host "| Configuration mode: $global:Target"
    Write-Host "| server's IP . . . . . . : $global:ServerIP"
    Write-Host "| server's Hostname . . . : $global:ServerHostname"
    Write-Host "| client's IP . . . . . . : $global:ClientIP"
    Write-Host "| client's Hostname . . . : $global:ClientHostname"
    Write-Host "#--------------------------------------#"
    # Notice prompt
    Write-Host "Configuration mode: $global:Target"
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
    Write-Host ' Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$global:ClientIP`t$global:ClientHostname"' -ForegroundColor DarkGreen
    # Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$global:ClientIP`t$global:ClientHostname"

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
    Write-Host ' Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ClientHostname" -Force' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ClientHostname" -Force

    # 5. AllowFreshCredentials (receive delegation)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Force' -ForegroundColor DarkGreen
    # New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Force

    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Name "1" -Value "wsman/$global:ClientHostname" -PropertyType String -Force' -ForegroundColor DarkGreen
    # New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Name "1" -Value "wsman/$global:ClientHostname" -PropertyType String -Force
    Start-Sleep 1
    Write-Host "::System::" -BackgroundColor gray -ForegroundColor magenta -NoNewline
    Write-Host " DONE" -ForegroundColor Green
    Pause
}