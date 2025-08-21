# Ensure running as Admin:::
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
    {Write-Host "This script requires administrative privileges. Please run again and accept the UAC prompt." -ForegroundColor Red
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit}

    
# Debug and Enviroment:::
# $global:ErrorActionPreference = 'SilentlyContinue'
# Set the default console background and foreground colors
$global:Host.UI.RawUI.BackgroundColor = 'Black'
$global:Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host
# Pause


# Root Functions:::
# System Message [Good] (1/2)
function Show-RootSystemMSG-OK_Done {
    Write-Host "::System::" -BackgroundColor gray -ForegroundColor magenta -NoNewline
    Write-Host " DONE" -ForegroundColor Green
}
function Show-RootSystemMSG-OK_SUCCESS {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " SUCCESS" -ForegroundColor Green
}

# System Message [Good] (2/2)
function Show-RootSystemMSG-OK_TRYING-A {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " TRYING: Step A" -ForegroundColor Green
}
function Show-RootSystemMSG-OK_TRYING-B {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " TRYING: Step B" -ForegroundColor Green
}
function Show-RootSystemMSG-OK_TRYING-C {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " TRYING: Step C" -ForegroundColor Green
}
function Show-RootSystemMSG-OK_TRYING-D {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " TRYING: Step D" -ForegroundColor Green
}
function Show-RootSystemMSG-OK_TRYING-E {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " TRYING: Step E" -ForegroundColor Green
}

# System Message [Error]
function Show-RootSystemMSG-ERR_Invalid-Input {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " ERROR: Invalid Input" -ForegroundColor Yellow
}
function Show-RootSystemMSG-ERR_Variable-Dependencies {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Magenta -NoNewline
    Write-Host " ERROR: Variable Dependencies = NUL" -ForegroundColor Yellow
}

function Show-RootSystemMSG-ERR-Script-Failure {
    Write-Host "::System::" -BackgroundColor Gray -ForegroundColor Red -NoNewline
    Write-Host " ERROR: Script Failure" -ForegroundColor Yellow
}

# System Action
function Get-RootMode {
    # Prompt loop
    do { Write-Host "--------------------------" -ForegroundColor Green
        $global:SetRootMode = (Read-Host "Select Mode: Configure (C) / Debug (D) / Manual Check (M)").ToUpper()
        switch ($global:SetRootMode) {
            'C'            {$global:RootMode = "Configure"}
            'CONFIGURE'    {$global:RootMode = "Configure"}
            'D'            {$global:RootMode = "Debug"}
            'DEBUG'        {$global:RootMode = "Debug"}
            'M'            {$global:RootMode = "Manual Check"}
            'MANUAL CHECK' {$global:RootMode = "Manual Check"}
            default {
                Show-RootSystemMSG-ERR_Invalid-Input
                $global:RootMode = $null
            }
        }
    } until ($global:RootMode)
}
function Get-RootDependencies {
    do {
        switch ((Read-Host "Is this a Server or Client? (S/C)").ToUpper()) {
            'S'       {$global:Target = 'Server'; $global:validTarget = $global:true}
            'SERVER'  {$global:Target = 'Server'; $global:validTarget = $global:true}
            'C'       {$global:Target = 'Client'; $global:validTarget = $global:true}
            'CLIENT'  {$global:Target = 'Client'; $global:validTarget = $global:true}
            default 
                {Show-RootSystemMSG-ERR_Invalid-Input}}} until ($global:validTarget)
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
        Write-Host "1. Set local static DNS override (bypass all DNS servers)" -ForegroundColor Cyan
        Write-Host "2. Set TrustedHosts (permits WinRM connections to non-domain host)" -ForegroundColor Cyan
        Write-Host "3. Enable & Configure WinRM Authentication Protocol (CredSSP/SPN)" -ForegroundColor Cyan
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Cyan}
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
        if ($global:ClientNoticeInput -in '1','2','3','4') {Write-Host $global:ClientSteps[$global:ClientNoticeInput] -ForegroundColor Yellow}
        elseif ($global:ClientNoticeInput -ieq 'R') {Get-ClientConfirmation_DisplayInfo}
        elseif (-not [string]::IsNullOrWhiteSpace($global:ClientNoticeInput)) 
            {Show-RootSystemMSG-ERR_Invalid-Input}
    } until ([string]::IsNullOrWhiteSpace($global:ClientNoticeInput))
    # Final prompt
    do {$global:ClientFinalInput = Read-Host "Do you wish to execute? (Enter)"
        if (-not [string]::IsNullOrWhiteSpace($global:ClientFinalInput)) 
        {Show-RootSystemMSG-ERR_Invalid-Input}
    } until ([string]::IsNullOrWhiteSpace($global:ClientFinalInput))
}
# Step B
function Invoke-ClientExecution {
    # 1. Set local static DNS override
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$global:ServerIP`t$global:ServerHostname"' -ForegroundColor DarkGreen
     Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n$global:ServerIP`t$global:ServerHostname"
    # 2. Set TrustedHosts (required for WinRM in workgroup)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ServerHostname" -Force' -ForegroundColor DarkGreen
     Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ServerHostname" -Force
    # 3. Enable CredSSP Client role
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$global:ServerHostname" -force' -ForegroundColor DarkGreen
     Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$global:ServerHostname" -force
    # 4. Configure AllowFreshCredentials
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Force' -ForegroundColor DarkGreen
     New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Force
    Write-Host ' New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Name "1" -Value 1 ' -ForegroundColor DarkGreen
     New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" -Name "1" -Value 1 
    # Finish Prompt
    Start-Sleep 1
}
# Step C
function Invoke-ClientSystemCheck {
    # System Check Part 1/2
    Write-Host "Checking dependencies..."
    Start-Sleep 2
    if ([string]::IsNullOrWhiteSpace($global:ServerIP)       -or
        [string]::IsNullOrWhiteSpace($global:ServerHostname) -or
        [string]::IsNullOrWhiteSpace($global:ClientIP)       -or
        [string]::IsNullOrWhiteSpace($global:ClientHostname))
       {Show-RootSystemMSG-ERR_Variable-Dependencies
        Write-Host "Listing variables..."
        Start-Sleep 3
        Write-Host "#--------------------------------------#"
        Write-Host "| Configuration mode: $global:Target"
        Write-Host "| server's IP . . . . . . : $global:ServerIP"
        Write-Host "| server's Hostname . . . : $global:ServerHostname"
        Write-Host "| client's IP . . . . . . : $global:ClientIP"
        Write-Host "| client's Hostname . . . : $global:ClientHostname"
        Write-Host "#--------------------------------------#"
        Write-Host "Next the script will check if all steps are completed successfully. Due to a dependency error the script may confuse NUL with a success status. If so do not trust the next system check"
        Pause}
    else {Show-RootSystemMSG-OK_SUCCESS}
    # System Check Part 2/2
    Start-Sleep 1
    Write-Host "Checking system..."
    Start-Sleep 2
    # Check step // 1. Set local static DNS override
    $global:ClientCheck_DNS = "$global:ServerIP`t$global:ServerHostname"
    # Read the hosts file and check for an exact match in one go
    if ((Get-Content -Path "C:\Windows\System32\drivers\etc\hosts") -contains $global:ClientCheck_DNS) {$global:ClientCheck_DNS_CheckStatus = "Passed"} else {$global:ClientCheck_DNS_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 2. Set TrustedHosts (required for WinRM in workgroup)
    $global:ClientCheck_TrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value 
    if ($global:ClientCheck_TrustedHosts -eq $global:ServerHostname) {$global:ClientCheck_TrustedHosts_CheckStatus = "Passed"} else {$global:ClientCheck_TrustedHosts_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 3. Enable CredSSP Server role (Fuck)
    try {
        $CredSSPOutput = Get-WSManCredSSP
        $TargetMatch = $CredSSPOutput | Select-String -Pattern $global:ServerHostname -AllMatches
        $global:ClientCheck_CredSSP_Target = $TargetMatch | ForEach-Object {foreach($m in $_.Matches){$m.Value}} | Select-Object -First 1} 
        catch {$global:ClientCheck_CredSSP_Target = $null}
    try {
        $CredSSPStatusMatch = Get-WSManCredSSP | Select-String -Pattern "allow delegating fresh credentials to the following target" -AllMatches
        $global:ClientCheck_CredSSP_Status = $CredSSPStatusMatch | ForEach-Object {foreach($m in $_.Matches){$m.Value}}}
        catch {$global:ClientCheck_CredSSP_Status = $null}
    if (($global:ClientCheck_CredSSP_Target -eq $global:ServerHostname) -and ($global:ClientCheck_CredSSP_Status -eq "allow delegating fresh credentials to the following target")) 
        {$global:ClientCheck_CredSSP_CheckStatus = "Passed"} 
    else {$global:ClientCheck_CredSSP_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 4. Configure AllowFreshCredentials (Fuck)
    try {
        $regOutput = reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"
        if (![string]::IsNullOrWhiteSpace($global:ServerHostname)) 
            {$match = $regOutput | Select-String -Pattern "wsman"
            $global:ClientCheck_Credentials = $match | ForEach-Object {foreach($m in $_.Matches){$m.Value}}} 
        else {$global:ClientCheck_Credentials = $null}} 
    catch {$global:ClientCheck_Credentials = $null}
    if ($global:ClientCheck_Credentials -eq $global:ServerHostname) 
        {$global:ClientCheck_Credentials_CheckStatus = "Passed"} 
    else {$global:ClientCheck_Credentials_CheckStatus = "Failed"}
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
    Write-Host "| 3. Enable CredSSP Client role ---------: " -NoNewline
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
        Write-Host "#-----------------------------------#"
        Write-Host "Steps with corresponding directories:" 
        Write-Host "1. Set local static DNS override (bypass all DNS servers)" -ForegroundColor Cyan
        Write-Host "GUI > C:\Windows\System32\drivers\etc\hosts" -ForegroundColor White
        Write-Host "2. Set TrustedHosts (permits WinRM connections to non-domain host)" -ForegroundColor Cyan
        Write-Host "CLI > WSMan:\localhost\Client\TrustedHosts" -ForegroundColor White
        Write-Host "3. Enable & Configure WinRM Authentication Protocol (CredSSP/SPN)" -ForegroundColor Cyan
        Write-Host "GUI > HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" -ForegroundColor White
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Cyan
        Write-Host "CLI > WSMan:\localhost\Client\Auth\CredSSP" -ForegroundColor White}
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
                if (-not [string]::IsNullOrWhiteSpace($global:ClientNoticeInput)) {Show-RootSystemMSG-ERR_Invalid-Input}
            }
        }
    } until ([string]::IsNullOrWhiteSpace($global:ClientNoticeInput))
}






# Server Functions:::
# Step A
function Get-ServerConfirmation {
    function Get-ServerConfirmation_DisplayInfo {
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
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Yellow
        Write-Host "5. Enable WinRM (PowerShell Remoting) " -ForegroundColor Yellow}
       # Set variable if user chose "why"
       $global:ServerSteps = @{
            '1' = "Step 1 | Why: WinRM (SPN) allowed list is Hostname based, not IP"
            '2' = "Step 2 | Why: Host blocks any NTLM WinRM connection, Kerberos is only for AD"
            '3' = "Step 3 | Why: Without CredSSP/SPN, WinRM blocks the delegation"
            '4' = "Step 4 | Why: CredSSP will refuse to forward credentials to client"
            '5' = "Step 5 | Why: Required for PowerShell remote sessions. Needed for Hyper-V Manager"}
       # Call function to dispay info
    Get-ServerConfirmation_DisplayInfo
    # Prompt loop
    do {$global:ServerNoticeInput = Read-Host "Press (Enter) to continue / Refresh (R) / Learn step Reason (1-5)"
        if ($global:ServerNoticeInput -in '1','2','3','4', '5') {Write-Host $global:ServerSteps[$global:ServerNoticeInput] -ForegroundColor Cyan}
        elseif ($global:ServerNoticeInput -ieq 'R') {Get-ServerConfirmation_DisplayInfo}
        elseif (-not [string]::IsNullOrWhiteSpace($global:ServerNoticeInput)) {Show-RootSystemMSG-ERR_Invalid-Input}
    } until ([string]::IsNullOrWhiteSpace($global:ServerNoticeInput))
    # Final prompt
    do {$global:ServerFinalInput = Read-Host "Do you wish to execute? (Enter)"
        if (-not [string]::IsNullOrWhiteSpace($global:ServerFinalInput)) {Show-RootSystemMSG-ERR_Invalid-Input}
    } until ([string]::IsNullOrWhiteSpace($global:ServerFinalInput))
}
# Step B
function Invoke-ServerExecution {
    # Step 1: Set local static DNS override
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "n$global:ServerIPt$global:ServerHostname"' -ForegroundColor DarkGreen
    # Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "n$global:ServerIPt$global:ServerHostname"
    # Step 2: Set TrustedHosts
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ServerHostname" -Force' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$global:ServerHostname" -Force
    # Step 3: Enable & Configure WinRM Authentication Protocol
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$global:ServerHostname" -force' -ForegroundColor DarkGreen
    # Enable-WSManCredSSP -Role Client -DelegateComputer "wsman/$global:ServerHostname" -force
    # Step 4: Configure AllowFreshCredentials
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Set-Item WSMan:\localhost\Client\Auth\CredSSP -Value @{AllowFreshCredentials=$global:true}' -ForegroundColor DarkGreen
    # Set-Item WSMan:\localhost\Client\Auth\CredSSP -Value @{AllowFreshCredentials=$global:true}
    # Step 5: Enable WinRM (PowerShell Remoting)
    Start-Sleep 1
    Write-Host "Executing:" -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host ' Enable-PSRemoting -Force' -ForegroundColor DarkGreen
    # Enable-PSRemoting -Force
    # Finish Prompt
    Start-Sleep 1
}
# Step C
function Invoke-ServerSystemCheck {
    # System Check Part 1/2
    Write-Host "Checking dependencies..."
    Start-Sleep 1
    if ([string]::IsNullOrWhiteSpace($global:ServerIP)       -or
        [string]::IsNullOrWhiteSpace($global:ServerHostname) -or
        [string]::IsNullOrWhiteSpace($global:ClientIP)       -or
        [string]::IsNullOrWhiteSpace($global:ClientHostname))
       {Show-RootSystemMSG-ERR_Variable-Dependencies
        Write-Host "Listing variables..."
        Start-Sleep 3
        Write-Host "#--------------------------------------#"
        Write-Host "| Configuration mode: $global:Target"
        Write-Host "| server's IP . . . . . . : $global:ServerIP"
        Write-Host "| server's Hostname . . . : $global:ServerHostname"
        Write-Host "| client's IP . . . . . . : $global:ClientIP"
        Write-Host "| client's Hostname . . . : $global:ClientHostname"
        Write-Host "#--------------------------------------#"
        Write-Host "Next the script will check if all steps are completed successfully. Due to a dependency error the script may confuse NUL with a success status. If so do not trust the next system check"
        Pause}
    else {Show-RootSystemMSG-OK_SUCCESS}
    # System Check Part 2/2
    Start-Sleep 1
    Write-Host "Checking system..."
    Start-Sleep 1
    # Check step // 1. Set local static DNS override
    $global:ServerCheck_DNS = "$global:ClientIP`t$global:ClientHostname"
    # Read the hosts file and check for an exact match in one go
    if ((Get-Content -Path "C:\Windows\System32\drivers\etc\hosts") -contains $global:ServerCheck_DNS) {$global:ServerCheck_DNS_CheckStatus = "Passed"} else {$global:ServerCheck_DNS_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 2. Set TrustedHosts (required for WinRM in workgroup)
    $global:ServerCheck_TrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value 
    if ($global:ServerCheck_TrustedHosts -eq $global:ClientHostname) {$global:ServerCheck_TrustedHosts_CheckStatus = "Passed"} else {$global:ServerCheck_TrustedHosts_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 3. Enable CredSSP Server role
    $global:ServerCheck_CredSSP_Target = Get-WSManCredSSP |
    Select-String -Pattern $global:ClientHostname -AllMatches | ForEach-Object {foreach($global:m in $global:_.Matches){$global:m.Value}} | Select-Object -First 1
    $global:ServerCheck_CredSSP_Status = Get-WSManCredSSP |
    Select-String -Pattern "allow delegating fresh credentials to the following target" -AllMatches | ForEach-Object {foreach($global:m in $global:_.Matches){ $global:m.Value}}
    if (($global:ServerCheck_CredSSP_Target -eq $global:ClientHostnameostname) -and ($global:ServerCheck_CredSSP_Status -eq "allow delegating fresh credentials to the following target")) {$global:ServerCheck_CredSSP_CheckStatus = "Passed"} else {$global:ServerCheck_CredSSP_CheckStatus = "Failed"}
    Start-Sleep 1
    # Check step // 4. Configure AllowFreshCredentials
    $global:ClientCheck_Credentials = reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials" |
    Select-String -Pattern $global:ClientHostname -AllMatches |
    ForEach-Object {foreach($global:m in $global:_.Matches){$global:m.Value}}
    if ($global:ClientCheck_Credentials -eq $global:ClientHostname) {$global:ClientCheck_Credentials_CheckStatus = "Passed"} else {$global:ClientCheck_Credentials_CheckStatus = "Failed"}
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
        Write-Host "#-----------------------------------#"
        Write-Host "Steps with corresponding directories:" 
        Write-Host "1. Set local static DNS override (bypass all DNS servers)" -ForegroundColor Yellow
        Write-Host "GUI > C:\Windows\System32\drivers\etc\hosts" -ForegroundColor White
        Write-Host "2. Set TrustedHosts (permits WinRM connections to non-domain host)" -ForegroundColor Yellow
        Write-Host "CLI > WSMan:\localhost\Client\TrustedHosts" -ForegroundColor White
        Write-Host "3. Enable & Configure WinRM Authentication Protocol (CredSSP/SPN)" -ForegroundColor Yellow
        Write-Host "GUI > HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" -ForegroundColor White
        Write-Host "4. Configure AllowFreshCredentials (allows WinRM to forward to target)" -ForegroundColor Yellow
        Write-Host "CLI > WSMan:\localhost\Client\Auth\CredSSP" -ForegroundColor White}
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
                if (-not [string]::IsNullOrWhiteSpace($global:ClientNoticeInput)) {Show-RootSystemMSG-ERR_Invalid-Input}
            }
        }
    } until ([string]::IsNullOrWhiteSpace($global:ClientNoticeInput))
}












# Root-Function Execution (Set Root Mode):::
Get-RootMode

# RootMode Execution:::


if ($global:RootMode -eq 'Manual Check') {
    Write-Host "Selected Mode: $global:RootMode"
    Invoke-ClientOptionalManualCheck
    Write-Host "The script will now exit" -ForegroundColor Cyan
    Pause
    Exit
}

elseif ($global:RootMode -eq 'Debug') {
    Write-Host "Selected Mode: $global:RootMode"
    function Invoke-RootModeDebug_DisplayInfo {
            Write-Host "#-----------------------------------#"
            Write-Host "Steps with corresponding Function:" 
            Write-Host "Step 0: Get-RootDependencies" -ForegroundColor Yellow
            Write-Host "Step A: Get-ClientConfirmation" -ForegroundColor Yellow
            Write-Host "Step B: Invoke-ClientExecution" -ForegroundColor Yellow
            Write-Host "Step C: Invoke-ClientSystemCheck" -ForegroundColor Yellow
            Write-Host "Step D: Show-ClientSystemStatus" -ForegroundColor Yellow
            Write-Host "Step E: Invoke-ClientOptionalManualCheck" -ForegroundColor Yellow}
        # Call function to dispay info
    Invoke-RootModeDebug_DisplayInfo
    # Prompt loop
    do {$global:SetDebug = (Read-Host "Press (Enter) to Exit / Select Step (A-E)").ToUpper()
        switch ($global:SetDebug) {
            '0' {Get-RootDependencies
                Invoke-RootModeDebug_DisplayInfo}
            'A' {Get-ClientConfirmation
                Invoke-RootModeDebug_DisplayInfo}
            'B' {Invoke-ClientExecution
                Invoke-RootModeDebug_DisplayInfo}
            'C' {Invoke-ClientSystemCheck
                Invoke-RootModeDebug_DisplayInfo}
            'D' {Show-ClientSystemStatus
                Invoke-RootModeDebug_DisplayInfo}
            'E' {Invoke-ClientOptionalManualCheck
                Invoke-RootModeDebug_DisplayInfo}
            default {
                if (-not [string]::IsNullOrWhiteSpace($global:SetDebug)) {Show-RootSystemMSG-ERR_Invalid-Input}
            }
        }
    } until ([string]::IsNullOrWhiteSpace($global:SetDebug))
    Write-Host "The script will now exit" -ForegroundColor Cyan
    Pause
    Exit
}
elseif ($global:RootMode -eq 'Configure') {
    Write-Host "Selected Mode: $global:RootMode"
    Get-RootDependencies
    if ($global:Target -eq 'Client') {
        try {
            Show-RootSystemMSG-OK_TRYING-A
            # Step A    
            Get-ClientConfirmation
            Show-RootSystemMSG-OK_TRYING-B
            # Step B
            Invoke-ClientExecution
            Show-RootSystemMSG-OK_TRYING-C
            # Step C
            Invoke-ClientSystemCheck
            Show-RootSystemMSG-OK_TRYING-D
            # Step D
            Show-ClientSystemStatus
            Show-RootSystemMSG-OK_TRYING-E
            # Step E
            Invoke-ClientOptionalManualCheck
            # Finishing
            Start-Sleep 1
            Write-Host "The script will now exit" -ForegroundColor Cyan
            Pause
            Exit} 
        catch {
            Show-RootSystemMSG-ERR-Script-Failure
            Write-Host "The script will now exit"
            Pause
            Exit
        }
    }
    elseif ($global:Target -eq 'Server') {
        try {
            # Step A    
            # Get-ServerConfirmation
            # Step B
            # Invoke-ServerExecution
            # Step C
            # Invoke-ServerSystemCheck
            # Step D
            # Show-ServerSystemStatus
            # Step E
            # Invoke-ServerOptionalManualCheck
            # Finishing
            Start-Sleep 1
            Write-Host "The script will now exit" -ForegroundColor Cyan
            Pause
            Exit} 
        catch {
            Show-RootSystemMSG-ERR-Script-Failure
            Write-Host "The script will now exit"
            Pause
            Exit
        }
    }
}


