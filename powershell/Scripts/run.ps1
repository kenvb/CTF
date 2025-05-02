# Import required modules
Import-Module .\CommonUtils.psm1
Import-Module .\Select-Targets.psm1
Import-Module .\ToolSync.psm1

# Prompt for credentials and connect to remote servers
$cred = Get-Credential
Connect-RemoteServers -Credential $cred
$ServerSessions = $Global:ServerSessions

if (-not $ServerSessions.Count) {
    Write-Error "No servers available. Exiting."
    return
}

while ($true) {
    $SelectedServers = Select-RemoteServers -SessionMap $ServerSessions
    if (-not $SelectedServers) {
        Write-Warning "No servers selected. Exiting."
        return
    }

    $SelectedScripts = Select-ScriptsToRun
    if (-not $SelectedScripts) {
        Write-Warning "No scripts selected (empty input). Returning to menu."
        continue
    }

    foreach ($serverName in $SelectedServers) {
        $server = $ServerSessions[$serverName]
        $session = $server.Session

        foreach ($scriptFile in $SelectedScripts) {
            $scriptPath = $scriptFile.FullName
            $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
            Write-Host "Running $scriptName on $serverName..." -ForegroundColor Cyan

            try {
                if ($scriptName -eq "start-autoruns") {
                    Copy-RemoteToolOnce -Session $session -ToolName "autorunsc.exe"
                }
                if ($scriptName -eq "get-psinfo") {
                    Copy-RemoteToolOnce -Session $session -ToolName "PsInfo.exe"
                }
                if ($scriptName -eq "get-psloggedon") {
                    Copy-RemoteToolOnce -Session $session -ToolName "PsLoggedOn.exe"
                }
                if ($scriptName -eq "Get-Sigcheck") {
                    Copy-RemoteToolOnce -Session $session -ToolName "sigcheck.exe"
                }
                if ($scriptName -eq "Run-PrivescCheck") {
                    Copy-RemoteToolOnce -Session $session -ToolName "PrivescCheck.ps1"
                }

                $scriptContent = Get-Content -Path $scriptPath -Raw
                $Result = Invoke-Command -Session $session -ScriptBlock ([ScriptBlock]::Create($scriptContent)) -ErrorAction Stop

                if (-not $Result) {
                    Write-Warning "No result returned by $scriptName on $serverName."
                    continue
                }

                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                Save-ResultToFile -Result $Result -ServerName $serverName -ScriptName $scriptName -Timestamp $timestamp
            }
            catch {
                Write-Warning "Remote script execution failed on $serverName\: $_"
            }
        }
    }
} 
