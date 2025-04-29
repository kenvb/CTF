Import-Module .\Select-Targets.psm1 -Force
Import-Module .\ToolSync.psm1 -Force
Import-Module .\CommonUtils.psm1 -Force

# === Initial setup ===
$csvPath = ".\servers.csv"
$outputRoot = Join-Path -Path $PSScriptRoot -ChildPath "Output"
$runTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$combinedSummary = @()

$servers = Import-Csv -Path $csvPath
$cred = Get-Credential
$Global:ServerSessions = @{}
$updatedServerData = @()

foreach ($server in $servers) {
    $ip = $server.ipaddress
    if (-not $ip) { continue }

    $existingName  = $server.name
    $existingOS    = $server.OS
    $existingBuild = $server.Build
    $existingArch  = $server.Arch

    Write-Host "Connecting to $ip..."

    $session = New-PSSession -ComputerName $ip -Credential $cred -ErrorAction SilentlyContinue
    if ($session) {
        $sysInfo = Invoke-Command -Session $session -ScriptBlock {
            $os = Get-CimInstance Win32_OperatingSystem
            [pscustomobject]@{
                Hostname = $env:COMPUTERNAME
                OS       = $os.Caption
                Build    = $os.BuildNumber
                Arch     = $os.OSArchitecture
            }
        }

        $finalName  = if ($existingName)  { $existingName }  else { $sysInfo.Hostname }
        $finalOS    = if ($existingOS)    { $existingOS }    else { $sysInfo.OS }
        $finalBuild = if ($existingBuild) { $existingBuild } else { $sysInfo.Build }
        $finalArch  = if ($existingArch)  { $existingArch }  else { $sysInfo.Arch }

        Write-Host "  [OK] $finalName ($ip) - $finalOS, Build $finalBuild, $finalArch" -ForegroundColor Green

        $Global:ServerSessions[$finalName] = @{
            Session = $session
            OS      = $finalOS
            Build   = $finalBuild
            Arch    = $finalArch
        }

        $updatedServerData += [pscustomobject]@{
            ipaddress = $ip
            name      = $finalName
            OS        = $finalOS
            Build     = $finalBuild
            Arch      = $finalArch
        }
    } else {
        Write-Host "  [FAILED] Could not connect to $ip" -ForegroundColor Red
        $updatedServerData += $server
    }
}

# Update servers.csv
$updatedServerData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# === Script execution loop ===
do {
    # --- Session health check ---
    $Global:DisconnectedServers = @()

    $toRemove = @()
    foreach ($entry in $Global:ServerSessions.GetEnumerator()) {
        if (-not (Test-SessionAlive -Session $entry.Value.Session)) {
            Write-Host "Session to $($entry.Key) died. Attempting silent reconnect..." -ForegroundColor Yellow
            $toRemove += $entry.Key

            $Global:DisconnectedServers += [pscustomobject]@{
                IP    = (Get-ServerIP -Name $entry.Key)
                Name  = $entry.Key
                OS    = $entry.Value.OS
                Build = $entry.Value.Build
                Arch  = $entry.Value.Arch
            }
        }
    }
    foreach ($dead in $toRemove) {
        $Global:ServerSessions.Remove($dead)
    }

    foreach ($entry in $Global:DisconnectedServers) {
        try {
            $session = New-PSSession -ComputerName $entry.IP -Credential $cred -ErrorAction Stop
            if ($session) {
                Write-Host "  [RECONNECTED] $($entry.Name)" -ForegroundColor Green
                $Global:ServerSessions[$entry.Name] = @{
                    Session = $session
                    OS      = $entry.OS
                    Build   = $entry.Build
                    Arch    = $entry.Arch
                }
            }
        }
        catch {
            Write-Warning "  [FAILED] Still cannot reach $($entry.Name) ($($entry.IP))"
        }
    }
    # --- End of session health check ---

    $selectedServers = Select-RemoteServers -SessionMap $Global:ServerSessions
    if (-not $selectedServers) {
        Write-Warning "No servers selected. Exiting loop."
        break
    }

    Write-Host "`nSelect a script to run:"
    Write-Host "  0. Run all scripts"
    $selectedScript = Select-ScriptToRun

    $scriptList = @()
    $customScriptContent = $null

    if ($selectedScript -eq '0') {
        $scriptList = Get-ChildItem -Path ".\Scripts" -Filter *.ps1 | Sort-Object Name
    } elseif ($selectedScript -eq 'C') {
        Write-Host "`nEnter your custom PowerShell script. Press Enter on an empty line to finish:`n" -ForegroundColor Yellow
        $lines = @()
        do {
            $line = Read-Host ">"
            if ($line -eq '') { break }
            $lines += $line
        } while ($true)

        if ($lines.Count -eq 0) {
            Write-Warning "No script entered. Returning to menu."
            continue
        }

        $customScriptContent = $lines -join "`n"
        $scriptList = @("custom-inline")
    } else {
        $scriptList = @((Get-Item $selectedScript))
    }

    foreach ($script in $scriptList) {
        if ($script -is [string] -and $script -eq "custom-inline") {
            $scriptName = "custom-inline"
        } else {
            $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($script.Name)
        }

        foreach ($server in $selectedServers) {
            Write-Host "Running script: $scriptName on $server"
            $serverStart = Get-Date
            $session = $Global:ServerSessions[$server].Session
            $output = $null
            $decoded = $null
            $savedPath = ""
            $status = ""

            # --- TOOL SYNC HOOK EXAMPLE ---
            if ($scriptName -eq "start-autoruns") {
                $null = Copy-RemoteToolOnce -Session $session -ToolName "autorunsc.exe"
            }
            if ($scriptName -eq "get-psinfo") {
                $null = Copy-RemoteToolOnce -Session $session -ToolName "PsInfo.exe"
            }
            if ($scriptName -eq "get-psloggedon") {
                $null = Copy-RemoteToolOnce -Session $session -ToolName "PsLoggedOn.exe"
            }
                       
            # Example:
            # if ($scriptName -eq "run-sysinternals") { $null = Copy-RemoteToolOnce -Session $session -ToolName "PsExec.exe" }
            # --- END TOOL SYNC ---

            try {
                if ($scriptName -eq "custom-inline") {
                    $output = Invoke-Command -Session $session -ScriptBlock ([ScriptBlock]::Create($customScriptContent)) -ErrorAction Stop
                } else {
                    $scriptContent = Get-Content -Path $script.FullName -Raw
                    $output = Invoke-Command -Session $session -ScriptBlock ([ScriptBlock]::Create($scriptContent)) -ErrorAction Stop
                }

                $output = $output | Out-String
                $decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($output.Trim()))
            } catch {
                Write-Warning "Failed to run $scriptName on ${server}: $($_.Exception.Message)"
            }

            if ($decoded) {
                $path = Join-Path $outputRoot "$server\$scriptName"
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -ItemType Directory -Force | Out-Null
                }

                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $file = Join-Path $path "$scriptName-$timestamp.json"
                [System.IO.File]::WriteAllText($file, $decoded, [System.Text.Encoding]::UTF8)
                $savedPath = $file
                $status = "Success"

                if ($scriptName -eq "custom-inline") {
                    Write-Host "`n--- Output from $server ---"
                    Write-Host $decoded.Trim()
                    Write-Host "--------------------------------`n"
                } else {
                    try {
                        $parsed = $decoded | ConvertFrom-Json
                        if ($parsed -is [System.Collections.IEnumerable]) {
                            Write-Host "`n--- Result Preview for $server ---"
                            $parsed | Format-Table -AutoSize
                            Write-Host "-----------------------------------`n"
                        }
                    } catch {
                        Write-Host "`n${server}: Output saved, not displayed (non-JSON)"
                    }
                }
            } else {
                $status = "No Output"
            }

            $duration = (Get-Date) - $serverStart
            $combinedSummary += [pscustomobject]@{
                Server     = $server
                Script     = $scriptName
                Status     = $status
                OutputFile = $savedPath
                Duration   = "{0:N2}s" -f $duration.TotalSeconds
            }
        }
    }

} while ($true)

# === Final summary ===
if ($combinedSummary.Count) {
    $summaryPath = Join-Path $outputRoot "Run-Summary-$runTimestamp.txt"
    $summaryLines = @("Execution Summary ($runTimestamp):`n")
    foreach ($entry in $combinedSummary) {
        $summaryLines += "{0,-20} {1,-20} {2,-10} {3,-50} {4}" -f $entry.Server, $entry.Script, $entry.Status, $entry.OutputFile, $entry.Duration
    }

    $summaryLines | Out-File -FilePath $summaryPath -Encoding UTF8

    Write-Host "`n=== Combined Summary Report ===" -ForegroundColor Cyan
    $summaryLines | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Saved to: $summaryPath"
}
