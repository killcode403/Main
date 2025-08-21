# Warning: This script assumes every command succeeds (No Error Handling)

# Action: Prompt user to enter required information
# Reason: Necessary for script to operate
Write-Output "Please enter your Hyper-v server information:"
Start-Sleep -Seconds 1
$Hostname = Read-Host "[1/4] Enter the hostname of the Hyper-V server"
$HostAddress = Read-Host "[2/4] Enter the IP address of the Hyper-V server"
$HostUSR = Read-Host "[3/4] Enter the username for connecting to the Hyper-V server"
$SecureHostPWD = Read-Host "[4/4] Enter the password for the user" -AsSecureString
Start-Sleep -Milliseconds 50
Write-Host "Hostname: " -NoNewline
Write-Host "$Hostname" -ForegroundColor Cyan
Start-Sleep -Milliseconds 50
Write-Host "HostAddress: " -NoNewline
Write-Host "$HostAddress" -ForegroundColor Cyan
Start-Sleep -Milliseconds 50
Write-Host "HostUSR: " -NoNewline
Write-Host "$HostUSR" -ForegroundColor Cyan
Start-Sleep -Milliseconds 50
Write-Host "HostPWD: " -NoNewline
Write-Host "Encrypted" -ForegroundColor Green
Start-Sleep -Seconds 2
Write-Host "Values saved!" -ForegroundColor DarkCyan
Start-Sleep -Seconds 3
Pause
Write-Host "Starting Configuration..." -ForegroundColor Yellow
Start-Sleep -Seconds 5


Write-Host "Trying Action: [Configures the local machine to accept basic remote management]" -ForegroundColor Yellow
# Action: Configures the local machine to accept basic remote management
# Reason: Necessary for any remote management tasks
winrm quickconfig

Write-Host "Trying Action: [Sets Hostname to equal Host Address]" -ForegroundColor Yellow
# Action: Sets Hostname to equal Host Address
# Reason: Hyper-v manager can only use hostnames to connect
Add-Content -Path C:\Windows\System32\drivers\etc\hosts "$HostAddress $Hostname"

Write-Host "Trying Action: [Attempt to resolve the hostname]" -ForegroundColor Yellow
# Action: Attempt to resolve the hostname
# Reason: Checks [Hostname = Host Address]
Write-Host (Resolve-DnsName $Hostname | Out-String) -ForegroundColor Cyan

Write-Host "Trying Action: [Sets the host as a trusted host]" -ForegroundColor Yellow
# Action: Sets the host as a trusted host
# Reason: For non-domain/workgroup environments where certificate trust cant be established
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$Hostname"

Write-Host "Trying Action: [Displays hostname located in "TrustedHosts"]" -ForegroundColor Yellow
# Action: Displays hostname located in "TrustedHosts"
# Reason: Checks hostname is trusted 
Write-Host "Trusted Host: $(((Get-Item WSMan:\localhost\Client\TrustedHosts).Value -split ",") | Where-Object { $_ -eq $Hostname })" -ForegroundColor Cyan


Write-Host "Trying Action: [Enables "Credential Security Support Provider"]" -ForegroundColor Yellow
# Action: Enables "Credential Security Support Provider"
# Reason: Allows client to securely delegate credentials to the remote server
Enable-WSManCredSSP -Role Client -DelegateComputer "$Hostname"

Write-Host "Trying Action: [Converts the users password back into plain text]" -ForegroundColor Yellow
# Action: Converts the users password back into plain text
# Reason: Necessary to set the correct input for cmdkey
$HostPWD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureHostPWD)
)

Write-Host "Trying Action: [Store credentials securely in "Windows Credential Manager"]" -ForegroundColor Yellow
# Action: Store credentials securely in "Windows Credential Manager"
# Reason: Allows automatic authentication to host (RDP/SMB/Remote Hyper-V)
cmdkey /add:$Hostname /user:$HostUSR /pass:$HostPWD

Write-Host "Trying Action: [Removes the stored password in RAM]" -ForegroundColor Yellow
# Action: Removes the stored password in RAM
#Reason: Password safe in case of RAM leaks
$HostPWD = $null

Write-Host "Trying Action: [Displays stored credentials for host]" -ForegroundColor Yellow
# Action: Displays stored credentials for host
# Reason: Checks if automatic authentication will work
Write-Host (cmdkey /list | Select-String "$Hostname" -Context 0,3).ToString() -ForegroundColor Cyan








