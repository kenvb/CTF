function Show-ConsolePreview {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Data,

        [Parameter(Mandatory=$true)]
        [ValidateSet('CSV','JSON')]
        [string]$Format
    )

    if ($Format -eq 'JSON') {
        try {
            $parsed = $Data | ConvertFrom-Json -ErrorAction Stop
            if ($parsed -is [System.Collections.IEnumerable]) {
                $parsed | Format-Table -AutoSize
            } else {
                Write-Host $parsed
            }
        } catch {
            Write-Host ($Data -join "`n")
        }
    } else {
        Write-Host ($Data -join "`n")
    }

    Write-Host "`n--- End of Preview ---`n"
}
# region Utility functions

function Get-SafeTimestamp {
    [CmdletBinding()]
    param()

    return (Get-Date -Format "yyyyMMdd-HHmmss")
}

function Save-ResultToFile {
    param (
        [Parameter(Mandatory = $true)] $Result,
        [Parameter(Mandatory = $true)] [string]$ServerName,
        [Parameter(Mandatory = $true)] [string]$ScriptName,
        [Parameter(Mandatory = $true)] [string]$Timestamp
    )

    $OutputFormat = "json"
    if ($Result -is [hashtable] -and $Result.ContainsKey("OutputFormat")) {
        $OutputFormat = $Result.OutputFormat.ToLower()
        $Result = $Result.Data
    }

    if ($Result -is [string] -and $Result -match '^[A-Za-z0-9+/=]{20,}$') {
        try {
            $Result = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Result))
        } catch {
            Write-Warning "Failed to decode Base64 result. Saving raw."
        }
    }

    $baseDir = Join-Path -Path ".\Output" -ChildPath $ServerName
    $scriptDir = Join-Path -Path $baseDir -ChildPath $ScriptName
    if (-not (Test-Path $scriptDir)) {
        New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
    }

    $extension = if ($OutputFormat -eq "csv") { "csv" } else { "json" }
    $filename = "${ScriptName}-${Timestamp}.${extension}"
    $outputPath = Join-Path -Path $scriptDir -ChildPath $filename

    try {
        switch ($extension) {
            "json" {
                $Result | Out-File -FilePath $outputPath -Encoding UTF8
            }
            "csv" {
                $Result | Out-File -FilePath $outputPath -Encoding UTF8
            }
        }
        Write-Host "Saved result to $outputPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to save result for $ScriptName on $ServerName\: $_"
    }
}

function Connect-RemoteServers {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $Global:ServerSessions = @{}
    $AllServers = Import-Csv -Path ".\servers.csv"
    $UpdatedServers = @()

    foreach ($server in $AllServers) {
        $ip = $server.ipaddress
        if (-not $ip) {
            Write-Warning "Empty or invalid server entry in CSV. Skipping."
            $UpdatedServers += $server
            continue
        }

        try {
            $session = New-PSSession -ComputerName $ip -Credential $Credential -ErrorAction Stop

            $os = Invoke-Command -Session $session -ScriptBlock {
                (Get-CimInstance Win32_OperatingSystem).Caption
            }
            $build = Invoke-Command -Session $session -ScriptBlock {
                (Get-CimInstance Win32_OperatingSystem).BuildNumber
            }
            $arch = Invoke-Command -Session $session -ScriptBlock {
                $env:PROCESSOR_ARCHITECTURE
            }
            $hostname = Invoke-Command -Session $session -ScriptBlock {
                (Get-CimInstance Win32_ComputerSystem).Name
            }

            $name = if ($server.name) { $server.name } else { $hostname }

            $Global:ServerSessions[$name] = [pscustomobject]@{
                Session = $session
                IP = $ip
                OS = $os
                Build = $build
                Arch = $arch
            }

            $UpdatedServers += [pscustomobject]@{
                name      = $name
                ipaddress = $ip
                os        = if ($server.os)    { $server.os }    else { $os }
                build     = if ($server.build) { $server.build } else { $build }
                arch      = if ($server.arch)  { $server.arch }  else { $arch }
            }

            Write-Host "Connected to $name ($ip) - $os, Build $build, $arch" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to connect to $ip\: $_"
            $UpdatedServers += $server
        }
    }

    $UpdatedServers | Sort-Object name | Export-Csv -Path ".\servers.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "servers.csv updated with any enriched data." -ForegroundColor Yellow
}
