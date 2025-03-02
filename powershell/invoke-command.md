## Basic Syntax
```powershell
Invoke-Command -ComputerName <RemoteServerName> -ScriptBlock { <Your PowerShell Code> }
```
- Replace `<RemoteServerName>` with the target server's hostname or IP address.
- Replace `<Your PowerShell Code>` with the command you want to execute.

## Running a Script on Multiple Remote Servers
You can execute the same command on multiple servers:
```powershell
$servers = @("Server1", "Server2", "Server3")
Invoke-Command -ComputerName $servers -ScriptBlock { Get-Service | Where-Object { $_.Status -eq "Running" } }
```

## Running a Script from a Local File on a Remote Server
If you have a PowerShell script saved locally, you can run it remotely:
```powershell
Invoke-Command -ComputerName <RemoteServerName> -FilePath "C:\Path\To\YourScript.ps1"
```

## Using Credentials for Remote Execution
If your current user doesn’t have access, you can specify credentials:
```powershell
$cred = Get-Credential
Invoke-Command -ComputerName <RemoteServerName> -Credential $cred -ScriptBlock { Get-Process }
```

## Enabling PowerShell Remoting
Before running `Invoke-Command`, ensure PowerShell remoting is enabled on the target machine:
```powershell
Enable-PSRemoting -Force
```
This command must be run with administrator privileges.

## Troubleshooting
If you encounter errors, check the following:
- Ensure PowerShell Remoting is enabled (`Enable-PSRemoting -Force` on the remote machine).
- The remote machine allows incoming PowerShell remoting connections (`Get-NetFirewallRule -DisplayGroup "Windows Remote Management"`).
- Ensure you have administrative privileges on the remote machine.