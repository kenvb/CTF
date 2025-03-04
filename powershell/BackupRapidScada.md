# PowerShell Script to Backup Rapid SCADA Configuration Files to a Zip and Schedule It to Run Every Hour
```powershell
$configPaths = @(
    "C:\Program Files\SCADA\BaseDAT",
    "C:\Program Files\SCADA\Views",
    "C:\Program Files\SCADA\ScadaServer\Config",
    "C:\Program Files\SCADA\ScadaComm\Config",
    "C:\Program Files\SCADA\ScadaWeb\Config"
)

# Define the backup zip file paths with date in the filename
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$localBackupPath = "C:\backup\scada_$date.zip"

$smbPath = "\\server\share"

# Create the local backup directory if it doesn't exist
$localBackupDir = [System.IO.Path]::GetDirectoryName($localBackupPath)
if (-Not (Test-Path $localBackupDir)) {
    New-Item -ItemType Directory -Path $localBackupDir | Out-Null
}

Compress-Archive -Path $configPaths -DestinationPath $localBackupPath
Write-Host "Local backup completed successfully. Configuration files are saved in $localBackupPath" -ForegroundColor Green

$smbBackupPath = "$smbPath\scada_$date.zip"

if (-Not (Test-Path $smbPath)) {
    New-Item -ItemType Directory -Path $smbPath | Out-Null
}

Copy-Item -Path $localBackupPath -Destination $smbBackupPath -Force
Write-Host "Backup also saved to SMB share at $smbBackupPath" -ForegroundColor Green

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File 'C:\backup\scada-backup.ps1'"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "HourlySCADABackup" -Action $action -Trigger $trigger -Settings $settings -Description "Backup Rapid SCADA configuration files every hour"
```