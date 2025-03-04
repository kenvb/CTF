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

### Red Flags:
- Connections to unknown external IPs.
- Processes making many outbound connections.


## Next Steps:
- Investigate suspicious tasks, services, or network connections.
- Check file hashes via `Get-FileHash` and compare with VirusTotal.
- Disable or remove confirmed malicious entries.