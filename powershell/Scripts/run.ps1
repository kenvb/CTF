# run.ps1 - Final Version (multi-script, multi-server, full interactive)

# Import required modules
Import-Module .\CommonUtils.psm1
Import-Module .\Select-Targets.psm1
Import-Module .\ToolSync.psm1

# Prompt for credentials
$Cred = Get-Credential -Message "Enter credentials for remote session access."

# Ensure output folder exists
if (-not (Test-Path -Path "Output")) {
    New-Item -Path "Output" -ItemType Directory | Out-Null
}

# Load server sessions
$ServerSessions = @{ }
$Servers = Import-Csv -Path .\servers.csv

# Create sessions with provided credentials
$ConnectedServers = @()
$FailedServers = @()

foreach ($Server in $Servers) {
    try {
        if (-not [string]::IsNullOrWhiteSpace($Server.Name)) {
            $Session = New-PSSession -ComputerName $Server.Name -Credential $Cred -ErrorAction Stop

            # Gather OS, Build, and Architecture information
            $osInfo = Invoke-Command -Session $Session -ScriptBlock {
                Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, BuildNumber
            }

            $csInfo = Invoke-Command -Session $Session -ScriptBlock {
                Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object SystemType
            }

            $ServerSessions[$Server.Name] = @{ 
                Session = $Session
                OS = $osInfo.Caption
                Build = $osInfo.BuildNumber
                Arch = $csInfo.SystemType
            }

            $ConnectedServers += $Server.Name
        }
        else {
            Write-Warning "Empty or invalid server name in CSV. Skipping."
        }
    }
    catch {
        Write-Warning "Failed to connect to $($Server.Name): $_"
        $FailedServers += $Server.Name
    }
}

# Save globally if needed elsewhere
$Global:ServerSessions = $ServerSessions

# Display connection summary
Write-Host "`n--- Connection Summary ---" -ForegroundColor Cyan
Write-Host "Connected Servers:`n  $($ConnectedServers -join ", ")" -ForegroundColor Green
if ($FailedServers.Count -gt 0) {
    Write-Host "Failed Servers:`n  $($FailedServers -join ", ")" -ForegroundColor Red
}

# Set console preview mode
$ShowConsole = $false

# Main script execution loop
while ($true) {
    # Select servers interactively
    $SelectedServers = Select-RemoteServers -SessionMap $ServerSessions
    if (-not $SelectedServers -or $SelectedServers.Count -eq 0) {
        Write-Warning "No servers selected (empty input). Returning to menu."
        continue
    }

    # Select scripts interactively
    $SelectedScripts = Select-ScriptsToRun
    if (-not $SelectedScripts -or $SelectedScripts.Count -eq 0) {
        Write-Warning "No scripts selected (empty input). Returning to menu."
        continue
    }

    foreach ($ScriptFile in $SelectedScripts) {
        $ScriptPath = $ScriptFile.FullName
        $ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptFile.Name)

        foreach ($ServerName in $SelectedServers) {

                # Sync supporting tools if needed
                if ($ScriptName -eq "start-autoruns") {
                    $null = Copy-RemoteToolOnce -Session $Session -ToolName "autorunsc.exe"
                }
                if ($ScriptName -eq "get-psinfo") {
                    $null = Copy-RemoteToolOnce -Session $Session -ToolName "PsInfo.exe"
                }
                if ($ScriptName -eq "get-psloggedon") {
                    $null = Copy-RemoteToolOnce -Session $Session -ToolName "PsLoggedOn.exe"
                }
            
                # ... rest of your script logic ...
            

            
            

            if (-not $ServerSessions.ContainsKey($ServerName)) {
                Write-Warning "No session available for $ServerName. Skipping."
                continue
            }

            $Session = $ServerSessions[$ServerName].Session

            Write-Host "Running $ScriptName on $ServerName..." -ForegroundColor Green

            $Timestamp = Get-SafeTimestamp

            switch ($ScriptName) {
                'Invoke-Diff' {
                    try {
                        $Result = & $ScriptPath -Session $Session
                    }
                    catch {
                        Write-Warning "Invoke-Diff failed to execute locally on $ServerName`: $_"
                        continue
                    }
                }
                'ToolSync' {
                    try {
                        $Result = & $ScriptPath -Session $Session
                    }
                    catch {
                        Write-Warning "ToolSync failed to sync tools on $ServerName`: $_"
                        continue
                    }
                }
                default {
                    try {
                        $Result = Invoke-Command -Session $Session -ScriptBlock (Get-Command $ScriptPath).ScriptBlock
                    }
                    catch {
                        Write-Warning "Remote script execution failed on $ServerName`: $_"
                        continue
                    }
                }
            }

            if ($Result) {
                try {
                    if ($Result -match '^[A-Za-z0-9+/=]+$' -and ($Result.Length % 4) -eq 0) {
                        $DecodedResult = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Result))
                        Save-ResultToFile -Result $DecodedResult -ServerName $ServerName -ScriptName $ScriptName -Timestamp $Timestamp -ShowConsole:$ShowConsole
                    }
                    else {
                        Save-ResultToFile -Result $Result -ServerName $ServerName -ScriptName $ScriptName -Timestamp $Timestamp -ShowConsole:$ShowConsole
                    }
                }
                catch {
                    Write-Warning "Failed to save result for $ScriptName on $ServerName`: $_"
                }
            }
            else {
                Write-Warning "No result returned by $ScriptName on $ServerName."
            }
        }
    }
}

Write-Host "Session ended. Thank you." -ForegroundColor Cyan
